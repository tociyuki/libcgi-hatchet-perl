package CGI::Hatchet;
use 5.008002;
use strict;
use warnings;
use IO::File;
use Carp;

use version; our $VERSION = '0.003';

# $Id$
# $Revision$
## no critic qw(ProhibitPunctuationVars)

__PACKAGE__->_mk_attributes(
    \&_scalar_accessor => qw(
        keyword_name max_post enable_upload block_size max_header
        error status body redirect fatals_to_browser
    ),
);
__PACKAGE__->_mk_attributes(\&_param_accessor => 'header');

sub new {
    my($class, @arg) = @_;
    my %opt = @arg == 1 && ref $arg[0] eq 'HASH' ? %{$arg[0]} : @arg;
    my $content_type = delete $opt{content_type};
    my $content_length = delete $opt{content_length};
    delete $opt{redirect};
    my $self = bless {
        max_post => 100 * 1024,
        enable_upload => 0,
        max_header => 1 * 1024,
        block_size => 4 * 1024,
        keyword_name => 'keyword',
        crlf => undef,
        status => 200,
        header => {},
        cookie => {},
        body => q{},
        redirect => undef,
        fatals_to_browser => 0,
        (ref $class ? %{$class} : ()),
        %opt,
        error => undef,
    }, ref $class ? ref $class : $class;
    if ($content_type) {
        $self->content_type($content_type);
    }
    if ($content_length) {
        $self->content_length($content_length);
    }
    return $self;
}

sub content_type   { return shift->header('Content-Type' => @_) }
sub content_length { return shift->header('Content-Length' => @_) }

sub finalize_psgi {
    my($self, $env) = @_;
    if (! $self->status) {
        $self->status(200);
    }
    if (my $location = $self->redirect) {
        $self->header('Location', $location);
        if ($self->status !~ /\A3\d\d\z/msx) {
            $self->status(302);
        }
    }
    $self->finalize_cookie;
    $self->finalize_error;
    if ($self->status =~ /\A(?:1\d\d|[23]04)\z/msx) {
        $self->body(q{});
        $self->content_length(undef);
    }
    else {
        if (! defined $self->body) {
            $self->body(q{});
        }
        if (! defined $self->content_length) {
            use bytes;
            $self->content_length(bytes::length($self->body));
        }
    }
    if ($env->{REQUEST_METHOD} eq 'HEAD') {
        $self->body(q{});
    }
    ## no critic qw(ComplexMap)
    return [
        $self->status,
        [map {
            my $name = $_;
            map {
                ($name => join "\x0d\x0a ", split /(?:\r\n?|\n)+[\t\040]*/msx, $_);
            } $self->header($name);
        } $self->header],
        [$self->body],
    ];
}

sub cookie {
    my($self, @arg) = @_;
    return keys %{$self->{cookie}} if ! @arg;
    my $k = shift @arg;
    if (@arg == 1 && ! defined $arg[0]) {
        return delete $self->{cookie}{$k};
    }
    if (@arg) {
        $self->{cookie}{$k} = {name => $k, value => @arg};
    }
    return $self->{cookie}{$k};
}

sub finalize_cookie {
    my($self) = @_;
    my @a = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @b = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    for my $key ($self->cookie) {
        my $cookie = $self->cookie($key);
        my @dough = (
            _encode_uri($cookie->{name}) . q{=} . _encode_uri($cookie->{value}),
            ($cookie->{domain} ? 'domain=' . _encode_uri($cookie->{domain}) : ()),
            ($cookie->{path}) ? 'path=' . _encode_uri($cookie->{path}) : (),
        );
        if (defined $cookie->{expires}) {
            my($s, $min, $h, $d, $mon, $y, $w) = gmtime $cookie->{expires};
            push @dough, sprintf 'expires=%s, %02d-%s-%04d %02d:%02d:%02d GMT',
                $a[$w], $d, $b[$mon], $y + 1900, $h, $min, $s;
        }
        push @dough,
            ($cookie->{secure} ? 'secure' : ()),
            ($cookie->{httponly} ? 'HttpOnly' : ());
        $self->header('Set-Cookie' => join q{; }, @dough);
    }
    return $self;
}

sub finalize_error {
    my($self) = @_;
    return if ! $self->error;
    $self->content_type('text/html; charset=UTF-8');
    $self->header('Set-Cookie', undef);
    $self->location(undef);
    if ($self->status !~ m/\A[45]\d\d\z/msx) {
        $self->status(500);
    }
    my $status = $self->status;
    my $error = q{};
    if ($self->fatals_to_browser) {
        $error = $self->error;
        my %special = (
            q{&} => '&amp;', q{<} => '&lt;', q{>} => '&gt;',
            q{"} => '&quot;', q{'} => '&#39;',
        );
        $error =~ s{([<>"'&])}{ $special{$1} }gemsx;
    }
    $self->body(<<"HTML");
<html>
<head><title>ERROR $status</title></head>
<body>
<h1>ERROR $status</h1>
<pre>$error</pre>
</body>
</html>
HTML
    return;
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
        $self->{crlf} = $os =~ m/VMS/msxi ? "\n"
            : "\t" ne "\011" ? "\r\n"
            : "\015\012";
    }
    return $self->{crlf};
}

sub scan_cookie {
    my($self, $env) = @_;
    my @cookie;
    for (split /[,;]/msx, $env->{'HTTP_COOKIE'} || q{}) {
        s/\A[\t\x20]+//msx;
        s/[\t\x20]+\z//msx;
        my @a = split /=/msx, $_, 2;
        next if @a < 2 || $a[0] eq q{}; # '', 'k', '=v'
        push @cookie, map { _decode_uri($_) } @a;
    }
    return @cookie;
}

sub read_body {
    my($self, $env) = @_;
    my $reader = $self->_proc_reader($env);
    my $body = q{};
    while (length $body < $env->{'CONTENT_LENGTH'}) {
        $reader->($body) or $self->_croak(400, 'Bad Request');
    }
    return $body;
}

sub scan_formdata {
    my($self, $env) = @_;
    my $method = $env->{'REQUEST_METHOD'} || 'GET';
    my $query = defined $env->{'QUERY_STRING'} ? $env->{'QUERY_STRING'}
        : defined $env->{'REDIRECT_QUERY_STRING'}
            ? defined $env->{'REDIRECT_QUERY_STRING'}
        : q{};
    my $c = {
        query_param => $self->_scan_urlencoded($query),
    };
    if ($method eq 'POST') {
        my $input = $env->{'psgi.input'};
        defined fileno $input or eval { $input->can('read') }
            or $self->_croak(500, 'Input handle is closed.');
        my $content_type = $env->{'CONTENT_TYPE'};
        if ($content_type =~ m{\Aapplication/x-www-form-urlencoded\b}msx) {
            $c->{body_param} = $self->_scan_urlencoded($self->read_body($env));
        }
        elsif ($content_type =~ m{\Amultipart/form-data\b}msx) {
            my $body_param = $self->_scan_multipart_formdata($env);
            @{$c}{keys %{$body_param}} = values %{$body_param};
        }
    }
    return $c;
}

sub _croak {
    my($self, $code, $message) = @_;
    $self->{status} = $code || 500;
    $self->{error} = $message || 'Internal Server Error';
    croak "$code $message";
}

sub _scan_urlencoded {
    my($self, $data) = @_;
    defined $data or return [];
    my @param;
    for (split /[&;]/msx, $data) {
        my @pair = split /=/msx, $_, 2;
        if (@pair == 1) {
            unshift @pair, $self->keyword_name; # 'k'
        }
        next if @pair < 2 || $pair[0] eq q{}; # '', '=v'
        push @param, map { _decode_uri($_) } @pair;
    }
    return \@param;
}

sub _decode_uri {
    my($uri) = @_;
    $uri =~ tr/+/ /;
    $uri =~ s{%([0-9A-Fa-f]{2})}{ chr hex $1 }egmsx;
    return $uri;
}

sub _encode_uri {
    my($uri) = @_;
    if (utf8::is_utf8($uri)) {
        require Encode;
        $uri = Encode::encode('utf-8', $uri);
    }
    $uri =~ s{
        (?:(\%([0-9A-Fa-f]{2})?)|([^a-zA-Z0-9_~\-.=+\$,:\@/;?\&\#]))
    }{
        $2 ? $1 : $1 ? '%25' : sprintf '%%%02X', ord $3
    }egmosx;
    return $uri;
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
            return wantarray ? @{$v} : $v->[-1];
        }
        elsif (@arg == 1 && ref $arg[0] eq 'ARRAY') {
            @{$self->{$attr}{$k}} = @{$arg[0]};
        }
        elsif (@arg) {
            push @{$self->{$attr}{$k}}, @arg;
        }
        return if ! exists $self->{$attr}{$k};
        return wantarray ? @{$self->{$attr}{$k}} : $self->{$attr}{$k}[-1];
    };
}

sub _scan_multipart_formdata {
    my($self, $env) = @_;
    my $input = $env->{'psgi.input'};
    my $boundary =
        $env->{'CONTENT_TYPE'} =~ m{\bboundary=(?:"(.+?)"|([^;]+))}msx ? $+
        : $self->_croak(400, 'Bad Request');
    my $crlf = $self->crlf;
    my $bd_size = (length $boundary) + 2 * (length "--$crlf");
    $boundary = quotemeta $boundary;
    $crlf = quotemeta $crlf;
    my $body = q{};
    my $hd_size = 0;
    my $hd_name = q{};
    my $reader = $self->_proc_reader($env);
    my $setter = sub {};
    my $c = {
        taint => q{},
        header => {},
        param => [],
        upload_info => [],
    };
    my $state = 1;
    while ($state) {
        if ($state == 1) {
            if ($body =~ s/\A--${boundary}${crlf}//msx) {
                $state = 2;
            }
            else {
                length $body < $bd_size or $self->_croak(400, 'Bad Request');
                $reader->($body) or $self->_croak(400, 'Bad Request');
                $c->{taint} = substr $body, 0, 0;
            }
        }
        elsif ($state == 2) {
            if ($body =~ s/\A${crlf}//msx) {
                $setter = $self->_proc_setter($c);
                $hd_size = 0;
                $hd_name = q{};
                %{$c->{header}} = ();
                $state = 3;
            }
            elsif ($body =~ s/\A(([A-Za-z0-9-]+):[\t\x20]*(.*?)${crlf})//msx) {
                $hd_size += length $1;
                $hd_name = $c->{taint} . (uc $2);
                $hd_name =~ tr/-/_/;
                $c->{header}{$hd_name} = $c->{taint} . $3;
            }
            elsif ($body =~ s/(\A[\t\x20]+(.*?)${crlf})//msx) {
                $hd_size += length $1;
                $hd_name ne q{} or $self->_croak(400, 'Bad Request');
                $c->{header}{$hd_name} .= q{ } . $2;
            }
            elsif ($body =~ m{(.*?)${crlf}}msx) {
                $self->_croak(400, 'Bad Request');
            }
            else {
                $reader->($body) or $self->_croak(400, 'Bad Request');
            }
            $hd_size <= $self->max_header or $self->_croak(400, 'Bad Request');
        }
        elsif ($state == 3) {
            if ($body =~ s/\A(.*?)${crlf}--${boundary}(--)?${crlf}//msx) {
                $setter->($1);
                $state = $2 ? 0 : 2;
            }
            else {
                my $size = (length $body) - $bd_size + 1;
                if ($size > 0) {
                    $setter->(substr $body, 0, $size, q{});
                }
                if (length $body < $bd_size) {
                    $reader->($body) or $self->_croak(400, 'Bad Request');
                }
            }
        }
    }
    return {body_param => $c->{param}, upload_info => $c->{upload_info}};
}

sub _proc_reader {
    my($self, $env) = @_;
    my $input = $env->{'psgi.input'};
    my $content_length = $env->{'CONTENT_LENGTH'};
    defined $content_length or $self->_croak(411, 'Length Required');
    {
        my $max = $self->max_post;
        my $limit = defined $max && $max >=0 ? $max : $content_length;
        $content_length <= $limit or $self->_croak(400, 'Bad Request');
    }
    my $block_size = $self->block_size;
    my $count = 0;
    my $idle = 0;
    binmode $input;
    $self = $env = undef;
    return sub{
        while (1) {
            read $input, my($data), $block_size;
            if ((my $size = length $data) > 0) {
                last if $count + $size > $content_length;
                $count += $size;
                $_[0] .= $data; ## no critic qw(ArgUnpacking)
                return $count;
            }
            last if ++$idle > 500;
        }
        return;
    };
}

sub _proc_setter {
    my($self, $c) = @_;
    my($name, $filename) = $self->_content_disposition($c->{header});
    my $enable_upload = $self->enable_upload;
    $self = undef;
    defined $name or return sub{};
    if (! defined $filename) {
        push @{$c->{param}}, $c->{taint} . $name, $c->{taint};
        return sub{ $c->{param}[-1] .= shift };
    }
    else {
        $enable_upload or return sub{};
        my $fh = IO::File->new_tmpfile or return sub{};
        binmode $fh;
        push @{$c->{param}}, $c->{taint} . $name, $c->{taint} . $filename;
        push @{$c->{upload_info}}, $c->{taint} . $filename, {
            %{$c->{header}},
            'CONTENT_LENGTH' => 0,
            'name' => $c->{taint} . $name,
            'filename' => $c->{taint} . $filename,
            'handle' => $fh,
        };
        return sub{
            my($part) = @_;
            print {$fh} $part;
            $c->{upload_info}[-1]{'CONTENT_LENGTH'} += length $part;
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

1;

__END__

=pod

=head1 NAME

CGI::Hatchet - A form decoder for PSGI applications like as CGI.pm 

=head1 VERSION

0.003

=head1 SYNOPSIS

    use CGI::Hatchet;
    use File::Slurp;
    use Hash::MultiValue;

    # create instance.
    $q = CGI::Hatchet->new(
        post_max => 16 * 1024,
        enable_upload => 1,
    );
    # or via the instance as a factory.
    $factory = CGI::Hatchet->new;
    $factory->max_post(256 * 1024);
    $factory->enable_upload(1);
    $q0 = $factory->new;
    $q1 = $factory->new;
    # fetch parameters.
    my $ph = $q->scan_formdata($env);
    # on CGI environment.
    # my $ph = $q->scan_formdata({%ENV, 'psgi.input' => \*INPUT});
    my $param = Hash::MultiValue->new(
        @{$ph->{query_param}}, @{$ph->{body_param}},
    );
    my $upload_info = Hash::MultiValue->new(@{$ph->{upload_info}});
    for my $name (keys %{$param}) {
        for my $value ($param->get_all($name)) {
            print "$name: $value\n";
            if (my $upinfo = $upload_info->{$value}) {
                seek $upinfo->{handle}, 0, 0;
                print "$value: ", File::Slurp::read_file($upinfo->{handle}), "\n";
            }
        }
    }
    # fetch cookies
    my $cookies = Hash::MultiValue->new($q->scan_cookie($env));
    for my $name (keys %{$cookies}) {
        for my $value ($cookie->get_all($name)) {
            print "$name: $value\n";
        }
    }

=head1 DESCRIPTION

This module provides you to decode form-data for PSGI applications.

=head1 METHODS

=over

=item C<< $q = new($key => $value, ...) >>

=item C<< $q->keyword_name($string) >>

=item C<< $q->max_post($integer) >>

=item C<< $q->enable_upload($bool) >>

=item C<< $q->block_size($integer) >>

=item C<< $q->crlf($string) >>

=item C<< $q->max_header($integer) >>

=item C<< $q->status($digits) >>

B<Response> status code.

=item C<< $q->content_type($string) >>

B<Response> header Content-Type.

=item C<< $q->content_length($integer) >>

B<Respons> header Content-Length.

=item C<< $q->header($name => $value) >>

B<Response> headers.

=item C<< $q->cookie($name => $value, expires => time - 3600) >>

B<Response> cookies.

=item C<< $q->body($string) >>

B<Response> body.

=item C<< $q->redirect($uri) >>

B<Response> redirect pointer.

=item C<< $q->finalize_psgi($env) >>

Creates a PSGI (Perl Server Gateway Interface) response.

=item C<< $q->finalize_cookie >>

Creates Set-Cookie headers.

=item C<< $q->finalize_error >>

Setup the status code and the headers related error.

=item C<< $q->fatals_to_browser($bool) >>

Enables reporting errors into the response body.

=item C<< @pairs = $q->scan_cookie($env) >>

Scans requested cookies from the PSGI env.
It returns a pair list of cookie's names and values.
It is comfortable that you treat the pair list through Hash::MultiValue.

    $cookies = Hash::MultiValue->new($q->scan_cookie($env));

=item C<< $hashref = $q->scan_formdata($env) >>

Scans formdata from the PSGI env.
It returns a hash reference that has keys, 'query_param', and/or
'body_param', and/or 'upload_info'. The values for these keys
are an array reference. Each array references include a pair
list of parameter's names and values.

    is_deeply $q->scan_formdata($env), {
        query_param => [key0, value0, key1, value1, ...],
        body_param => [key0, value0, key1, value1, ...],
        upload_info => [
            filename0 => {
                handle => \*handle_0,
                name => key_0,
                filename => filename0,
                CONTENT_DISPOSITION => ..,
                CONTENT_LENGTH => ..,
            }, ..
        ],
    }, 'scan_formdata';

If you get upload_info, you must C<seek $handle_N, 0, 0> before
read from it.

=item C<< $body = $q->read_body($env) >>

=item C<< $q->error >>

=back

=head1 DEPENDENCIES

L<IO::File>

=head1 SEE ALSO

L<CGI>, L<CGI::Simple>, L<PSGI>, L<Hash::MultiValue>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
