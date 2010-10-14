package CGI::Hatchet;
use 5.008002;
use strict;
use warnings;
use IO::File;
use Carp;

use version; our $VERSION = '0.001';

# $Id$
# $Revision$
## no critic qw(ProhibitPunctuationVars)

our $DEFAULT_MAX_POST = 100 * 1024;

__PACKAGE__->_mk_attributes(
    \&_scalar_accessor => qw(
        max_post enable_upload max_header block_size keyword_name error
        request_method query_string content_type content_length raw_cookie
    ),
);
__PACKAGE__->_mk_attributes(
    \&_param_accessor => qw(param query_param upload_info cookie),
);

sub new {
    my($class, %arg) = @_;
    my $env = delete $arg{env};
    my $self = bless {
        max_post => $DEFAULT_MAX_POST,
        enable_upload => 0,
        max_header => 1 * 1024,
        block_size => 4 * 1024,
        keyword_name => 'keyword',
        crlf => undef,
        (ref $class ? %{$class} : ()),
        %arg,
        param => {},
        query_param => {},
        upload_info => {},
        cookie => {},
        error => undef,
    }, ref $class ? ref $class : $class;
    if (ref $env eq 'HASH') {
        $self->prepare_env($env);
        $self->scan_formdata($env->{'psgi.input'});
        $self->scan_cookie;
    }
    return $self;
}

sub prepare_env {
    my($self, $env) = @_;
    $self->request_method($env->{'REQUEST_METHOD'} || 'GET');
    $self->query_string(
          defined $env->{'QUERY_STRING'} ? $env->{'QUERY_STRING'}
        : defined $env->{'REDIRECT_QUERY_STRING'}
            ? defined $env->{'REDIRECT_QUERY_STRING'}
        : q{},
    );
    $self->content_type($env->{'CONTENT_TYPE'} || q{});
    $self->content_length($env->{'CONTENT_LENGTH'});
    $self->raw_cookie($env->{'HTTP_COOKIE'} || q{});
    return $self;
}

sub scan_cookie {
    my($self) = @_;
    $self->{cookie} = {};
    for (split /[,;]/msx, $self->raw_cookie) {
        s/\A[\t\x20]+//msx;
        s/[\t\x20]+\z//msx;
        my($k, $v) = split /=/msx, $_, 2;
        next if ! defined $k || $k eq q{};
        $self->cookie(_decode_uri($k) => _decode_uri(defined $v ? $v : q{}));
    }
    return $self;
}

sub read_entity {
    my($self, $input) = @_;
    my $reader = $self->_proc_reader($input);
    my $body = q{};
    while (length $body < $self->content_length) {
        $reader->($body) or $self->_die(400, 'Bad Request');
    }
    return $body;
}

sub scan_formdata {
    my($self, $input) = @_;
    my $method = $self->request_method || q{};
    my $query = $self->query_string || q{};
    @{$self}{qw(param query_param upload)} = ({}, {}, {});
    if ($query =~ /[&=;]/msx) {
        $self->_scan_urlencoded($query);
    }
    if ($method eq 'POST') {
        defined fileno $input or eval { $input->can('read') }
            or $self->_die(500, 'Input handle is closed.');
        $self->{query_param} = $self->{param};
        $self->{param} = {};
        my $content_type = $self->content_type;
        if ($content_type =~ m{\Aapplication/x-www-form-urlencoded\b}msx) {
            $self->_scan_urlencoded($self->read_entity($input));
        }
        elsif ($content_type =~ m{\Amultipart/form-data\b}msx) {
            $self->_scan_multipart_formdata($input);
        }
    }
    return $self;
}

sub _scan_urlencoded {
    my($self, $data) = @_;
    defined $data or return $self;
    for (split /[&;]/msx, $data) {
        my($k, $v) = my(@pair) = split /=/msx, $_, 2;
        next if ! defined $k || $k eq q{}; # '' || '=v'
        if (@pair == 1) {
            $self->param($self->keyword_name => _decode_uri($k)); # 'k'
        }
        else {
            $self->param(_decode_uri($k) => _decode_uri($v)); # 'k=v', 'k='
        }
    }
    return $self;
}

sub crlf {
    my($self, @arg) = @_;
    if (@arg) {
        $self->{crlf} = $arg[0];
    }
    if (! $self->{crlf}) {
        my $os = $^O || do {
            require Config;
            $Config::Config{'osname'}; ## no critic qw(PackageVars)
        };
        $self->{crlf} = $os =~ m/VMS/msxi? "\n"
            : "\t" ne "\011" ? "\r\n"
            : "\015\012";
    }
    return $self->{crlf};
}

sub _decode_uri {
    my($s) = @_;
    $s =~ tr/+/ /;
    $s =~ s{%([0-9A-Fa-f]{2})}{ chr hex $1 }msxge;
    return $s;
}

sub _mk_attributes {
    my($class, $accessor, @attrlist) = @_;
    for my $attr (@attrlist) {
        no strict 'refs'; ## no critic qw(NoStrict)
        *{"${class}::${attr}"} = $accessor->($attr);
    }
    return;
}

sub _scalar_accessor {
    my($attr) = @_;
    return sub{
        my($self, @arg) = @_;
        if (@arg) {
            $self->{$attr} = $arg[0];
        }
        return $self->{$attr};
    };
}

sub _param_accessor {
    my($attr) = @_;
    return sub{
        my($self, @arg) = @_;
        @arg or return keys %{$self->{$attr}};
        my $k = shift @arg;
        if (@arg == 1 && ! defined $arg[0]) {
            my $v = delete $self->{$attr}{$k};
            return if ! $v;
            return wantarray ? @{$v} : $v->[0];
        }
        elsif (@arg == 1 && ref $arg[0] eq 'ARRAY') {
            $self->{$attr}{$k} = [@{$arg[0]}];
        }
        elsif (@arg) {
            push @{$self->{$attr}{$k}}, @arg;
        }
        return if ! exists $self->{$attr}{$k};
        return wantarray ? @{$self->{$attr}{$k}} : $self->{$attr}{$k}[0];
    };
}

sub _die {
    my($self, $code, $message) = @_;
    $self->{error} = [
        $code,
        ['Content-Type' => 'text/plain; charset=UTF-8'],
        [$message],
    ];
    croak "$code $message";
}

sub _scan_multipart_formdata {
    my($self, $input) = @_;
    my $boundary = $self->content_type =~ m{
        \bboundary=(?:"(.*?)"|([^;]*))
    }msx ? $+ : $self->_die(400, 'Bad Request');
    my $crlf = $self->crlf;
    my $ctx = {
        buf => q{},
        param => {},
        upload_info => {},
        crlf => quotemeta $crlf,
        boundary => quotemeta $boundary,
        boundary_size => (length $boundary) + 2 * (length "--$crlf"),
        taint => (substr $0, 0, 0),
        header_size => 0,
        header_name => q{},
        header => {},
        reader => $self->_proc_reader($input),
        setter => sub{},
    };
    local $@ = undef;
    my $fail = ! eval {
        my $cont = \&_scan_multipart_formdata_first_boundary;
        while (1) {
            $cont = $cont->($self, $ctx, $cont) or last;
        }
        1;
    };
    if ($fail) {
        my $err = $@;
        $self->_die(ref $err ? @{$err}: (500, "$err"));
    }
    for my $name (keys %{$ctx->{param}}) {
        $self->param($name => @{$ctx->{param}{$name}});
    }
    for my $filename (keys %{$ctx->{upload_info}}) {
        $self->upload_info($filename => @{$ctx->{upload_info}{$filename}});
    }
    return $self;
}

sub _proc_reader {
    my($self, $input) = @_;
    my $content_length = $self->content_length;
    defined $content_length or $self->_die(411, 'Length Required');
    {
        my $max = $self->max_post;
        my $limit = defined $max && $max >=0 ? $max : $content_length;
        $content_length <= $limit or $self->_die(400, 'Bad Request');
    }
    my $block_size = $self->block_size;
    $self = undef; # to avoid cyclic references.
    my $count = 0;
    my $spin = 0;
    binmode $input;
    return sub{
        while (1) {
            read $input, my($data), $block_size;
            if ((my $size = length $data) > 0) {
                last if $count + $size > $content_length;
                $count += $size;
                $_[0] .= $data; ## no critic qw(ArgUnpacking)
                return $count;
            }
            last if ++$spin > 1000;
        }
        return;
    };
}

sub _proc_setter {
    my($self, $ctx) = @_;
    my($header, $param, $taint, $upload_info)
        = @{$ctx}{qw(header param taint upload_info)};
    my($name, $filename) = $self->_content_disposition($header);
    my $enable_upload = $self->enable_upload;
    $self = $ctx = undef; # to avoid cyclic references.
    defined $name or return sub{};
    if (! defined $filename) {
        push @{$param->{$name}}, $taint;
        return sub{ $param->{$name}[-1] .= shift };
    }
    else {
        $enable_upload or return sub{};
        my $fh = IO::File->new_tmpfile or return sub{};
        binmode $fh;
        push @{$param->{$name}}, $taint . $filename;
        push @{$upload_info->{$filename}}, {
            %{$header},
            CONTENT_LENGTH => 0,
            name => $taint . $name,
            filename => $taint . $filename,
            handle => $fh,
        };
        return sub{
            my($part) = @_;
            print {$fh} $part;
            $upload_info->{$filename}[-1]{'CONTENT_LENGTH'} += length $part;
        };
    }
}

sub _content_disposition {
    my($self, $header) = @_;
    my $s = $header->{'CONTENT_DISPOSITION'} or return;
    my %h;
    while ($s =~ m/\b((?:file)?name)=(?:"(.*?)"|([^;]*))/msxog) {
        $h{$1} = $+;
    }
    return @h{'name', 'filename'};
}

sub _scan_multipart_formdata_first_boundary {
    my($self, $ctx, $cont) = @_;
    my($boundary, $crlf) = @{$ctx}{'boundary', 'crlf'};
    if ($ctx->{buf} =~ s/\A--${boundary}${crlf}//msx) {
        $cont = \&_scan_multipart_formdata_header;
    }
    elsif (length $ctx->{buf} < $ctx->{boundary_size}) {
        $ctx->{reader}->($ctx->{buf}) or croak [400, 'Bad Request'];
    }
    else {
        croak [400, 'Bad Request'];
    }
    return $cont;
}

sub _scan_multipart_formdata_header {
    my($self, $ctx, $cont) = @_;
    my $crlf = $ctx->{crlf};
    if ($ctx->{buf} =~ s/\A${crlf}//msx) {
        $ctx->{setter} = $self->_proc_setter($ctx);
        $ctx->{header_size} = 0;
        $ctx->{header_name} = q{};
        $ctx->{header} = {};
        $cont = \&_scan_multipart_formdata_body;
    }
    elsif ($ctx->{buf} =~ s/\A(([A-Za-z0-9_-]+):[\t\x20]*(.+?)${crlf})//msx) {
        $ctx->{header_size} += length $1;
        $ctx->{header_name} = $ctx->{taint} . (uc $2);
        $ctx->{header_name} =~ tr/-/_/;
        $ctx->{header}{ $ctx->{header_name} } = $ctx->{taint} . $3;
    }
    elsif ($ctx->{buf} =~ s/(\A[\t\x20]*(.+?)${crlf})//msx) {
        $ctx->{header_size} += length $1;
        $ctx->{header_name} ne q{} or croak [400, 'Bad Request'];
        $ctx->{header}{ $ctx->{header_name} } .= $ctx->{taint} . $1;
    }
    else {
        $ctx->{reader}->($ctx->{buf}) or croak [400, 'Bad Request'];
    }
    $ctx->{header_size} <= $self->max_header or croak [400, 'Bad Request'];
    return $cont;
}

sub _scan_multipart_formdata_body {
    my($self, $ctx, $cont) = @_;
    my($boundary, $crlf) = @{$ctx}{'boundary', 'crlf'};
    if ($ctx->{buf} =~ s/\A(.*?)${crlf}--${boundary}(--)?${crlf}//msx) {
        $ctx->{setter}->($1);
        $cont = $2 ? undef : \&_scan_multipart_formdata_header;
    }
    else {
        my $size = (length $ctx->{buf}) - $ctx->{boundary_size} + 1;
        if ($size > 0) {
            $ctx->{setter}->(substr $ctx->{buf}, 0, $size, q{});
        }
        if (length $ctx->{buf} < $ctx->{boundary_size}) {
            $ctx->{reader}->($ctx->{buf}) or croak [400, 'Bad Request'];
        }
    }
    return $cont;
}

1;

__END__

=pod

=head1 NAME

CGI::Hatchet - A form decoder for PSGI applications like as CGI.pm 

=head1 VERSION

0.001

=head1 SYNOPSIS

    use CGI::Hatchet;
    use File::Slurp;

    # construct instance directory.
    $q = CGI::Hatchet->new(
        env => $env,
        post_max => 16 * 1024,
        enable_upload => 1,
    );
    # or via the instance as a factory.
    $factory = CGI::Hatchet->new;
    $factory->max_post(256 * 1024);
    $factory->enable_upload(1);
    $q0 = $factory->new(env => $env0);
    $q1 = $factory->new(env => $env1);
    # fetch parameters.
    my @param_keys = $q->param;
    for my $name ($q->param) {
        for my $value ($q->param($name)) {
            print "$name: $value\n";
            if (my $info = $q->upload_info($value)) {
                seek $info->{handle}, 0, 0;
                print "$value: ", File::Slurp::read_file($info->{handle}), "\n";
            }
        }
    }
    # fetch cookies
    my @cookie_keys = $q->cookie;
    for my $name ($q->cookie) {
        for my $value ($q->cookie($name)) {
            print "$name: $value\n";
        }
    }
    # fetch query parameters from QUERY_STRING on POST.
    my @query_keys = $q->query_param;
    for my $name ($q->query_param) {
        for my $value ($q->query_param($name)) {
            print "$name: $value\n";
        }
    }
    
    # on CGI environment.
    $q = CGI::Hatchet->new(
        env => {%ENV, 'psgi.input' => \*INPUT},
    );
    
    # step-by-step decoding over CGI environment.
    #  step 1. create decoder
    $q = CGI::Hatchet->new;
    #  step 2. set variables.
    $q->request_method($ENV{REQUEST_METHOD});
    $q->query_string($ENV{QUERY_STRING});
    $q->raw_cookie($ENV{HTTP_COOKIE});
    $q->path_info($ENV{PATH_INFO});
    $q->content_type($ENV{CONTENT_TYPE});
    $q->content_length($ENV{CONTENT_LENGTH});
    #  step 3. scan
    $q->scan_formdata(\*STDIN);
    $q->scan_cookie;

=head1 DESCRIPTION

This module provides you to decode form-data for PSGI applications.

=head1 METHODS

=over

=item C<< $q = new(env => $env, name => $value...) >>

=item C<< $q->param($name) >>

=item C<< $q->query_param($name) >>

=item C<< $q->upload_info($filename) >> 

=item C<< $q->cookie($name) >>

=item C<< $q->keyword_name($string) >>

=item C<< $q->max_post($integer) >>

=item C<< $q->enable_upload($bool) >>

=item C<< $q->block_size($integer) >>

=item C<< $q->crlf($string) >>

=item C<< $q->max_header($integer) >>

=item C<< $q->prepare_env($env) >>

=item C<< $q->request_method($string) >>

=item C<< $q->query_string($string) >>

=item C<< $q->content_type($string) >>

=item C<< $q->content_length($integer) >>

=item C<< $q->raw_cookie($string) >>

=item C<< $q->scan_cookie >>

=item C<< $q->scan_formdata($input) >>

=item C<< $q->read_entity($input) >>

=item C<< $q->error >>

=back

=head1 DEPENDENCIES

L<IO::File>

=head1 SEE ALSO

L<CGI>, L<CGI::Simple>, L<PSGI>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
