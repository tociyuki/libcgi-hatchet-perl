package CGI::Hatchet;
use 5.008002;
use strict;
use warnings;
use Carp;
use Encode;
use IO::File;

use version; our $VERSION = '0.015';

# $Id$
# $Revision$
## no critic qw(ProhibitPunctuationVars ProhibitComplexMappings)

__PACKAGE__->_mk_attributes(
    \&_scalar_accessor => qw(
        keyword_name max_post enable_upload block_size max_header
        fatals_to_browser error_page_builder error code body env
        max_params
    ),
);
__PACKAGE__->_mk_attributes(
    \&_param_accessor => qw(header param upload request_cookie),
);

*status = \&code;

sub address     { return shift->env->{'REMOTE_ADDR'} }
sub remote_host { return shift->env->{'REMOTE_HOST'} }
sub protocol    { return shift->env->{'SERVER_PROTOCOL'} }
sub method      { return shift->env->{'REQUEST_METHOD'} }
sub port        { return shift->env->{'SERVER_PORT'} }
sub user        { return shift->env->{'REMOTE_USER'} }
sub request_uri { return shift->env->{'REQUEST_URI'} }
sub path_info   { return shift->env->{'PATH_INFO'} }
sub path        { return shift->env->{'PATH_INFO'} || q{/} }
sub script_name { return shift->env->{'SCRIPT_NAME'} }
sub scheme      { return shift->env->{'psgi.url_scheme'} }
sub secure      { return shift->scheme eq 'https' }

sub new {
    my($class, @arg) = @_;
    if (ref $arg[0] eq 'HASH' && exists $arg[0]->{'psgi.version'}) {
        unshift @arg, 'env';
    }
    elsif (@arg == 1 && ref $arg[0] eq 'HASH') {
        @arg = %{$arg[0]};
    }
    my $self = bless {
        env => {SERVER_PROTOCOL => 'HTTP/1.0', SCRIPT_NAME => q{}},
        keyword_name => 'keyword',
        max_post => 100 * 1024,
        max_params => 512,
        enable_upload => 0,
        block_size => 4 * 1024,
        max_header => 1 * 1024,
        fatals_to_browser => 0,
        error_page_builder => undef,
        crlf => undef,
        (ref $class ? %{$class} : ()),
        error => undef,
        code => undef,
        body => undef,
        header => {},
        cookie => {},
        param => {},
        upload => {},
        request_cookie => {},
    }, ref $class ? ref $class : $class;
    for (0 .. -1 + int @arg / 2) {
        my $i = $_ * 2;
        $self->replace($arg[$i] => $arg[$i + 1]);
    }
    return $self;
}

sub new_response {
    my($class, $rc, $headers, $content) = @_;
    my $self = bless {
        env => {SERVER_PROTOCOL => 'HTTP/1.0', SCRIPT_NAME => q{}},
        code => undef,
        header => {},
        cookie => {},
        body => undef,
        fatals_to_browser => 0,
        error_page_builder => undef,
        error => undef,
    }, ref $class ? ref $class : $class;
    if (ref $class) {
        for my $attr (
            qw(error code fatals_to_browser error_page_builder crlf env)
        ) {
            $self->$attr($class->$attr);
        }
    }
    if (! $self->error) {
        $self->code($rc);
    }
    if (ref $headers eq 'ARRAY') {
        $self->replace(header => $headers);
    }
    if (defined $content) {
        $self->content_length(undef);
        $self->body($content);
    }
    return $self;
}

sub content_type   { return shift->header('Content-Type' => @_) }
sub content_length { return shift->header('Content-Length' => @_) }

sub cookie {
    my($self, @arg) = @_;
    return keys %{$self->{cookie}} if ! @arg;
    my $k = shift @arg;
    if (@arg) {
        if (@arg == 1 && ! defined $arg[0]) {
            return delete $self->{cookie}{$k};
        }
        if (@arg == 1 && ref $arg[0] eq 'HASH') {
            $self->{cookie}{$k} = {name => $k, %{$arg[0]}};
        }
        else {
            $self->{cookie}{$k} = {name => $k, value => @arg};
        }
    }
    return $self->{cookie}{$k};
}

sub redirect {
    my($self, @arg) = @_;
    if (@arg) {
        $self->header('Location' => $arg[0]);
        $self->code(@arg > 1 ? $arg[1] : '303');
    }
    return $self->header('Location');
}

sub finalize {
    my($self) = @_;
    my $body = $self->body;
    ## no critic qw(ComplexMap)
    return [
        $self->code,
        [map {
            my $name = $_;
            map {
                ($name => join "\x0d\x0a ", split /[\r\n]+[\t\040]*/msx, $_);
            } $self->header($name);
        } $self->header],
        # similar as Plack::Response except for unchecking overload q{""}.
        ! defined $body ? [] : ! ref $body ? [$body] : $body,
    ];
}

sub finalize_cookie {
    my($self) = @_;
    my @a = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @b = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    for my $key ($self->cookie) {
        my $cookie = $self->cookie($key);
        my @dough = (
            _encode_uri($cookie->{name}) . q{=} . _encode_uri($cookie->{value}),
            ($cookie->{domain}
                ? 'domain=' . _encode_uri($cookie->{domain}) : ()),
            ($cookie->{path})
                ? 'path=' . _encode_uri_path($cookie->{path}) : (),
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

sub normalize {
    my($self, $env) = @_;
    my $_env = $env || $self->env;
    local $self->{env} = $_env; ## no critic (ProhibitLocalVars)
    if (! $self->code) {
        $self->error(join ".\n", 'Undefined code', ($self->error || ()));
    }
    if ($self->error) {
        if (! $self->code || $self->code !~ m/\A[45][0-9][0-9]\z/msx) {
            $self->code(500);
        }
        $self->header('Set-Cookie', undef);
        $self->header('Location', undef);
        $self->content_length(undef);
        $self->body(undef);
        if (ref $self->error_page_builder eq 'CODE') {
            $self->error_page_builder->($self, $env);
        }
        else {
            $self->_build_default_error_page;
        }
    }
    else {
        if (($self->protocol || 'HTTP/1.0') =~ m{/1.0\z}msx) {
            if ($self->code =~ m/\A30[37]\z/msx) {
                $self->code('302');
            }
        }
    }
    if ($self->code =~ m/\A(?:1[0-9][0-9]|[23]04)\z/msx) {
        $self->content_length(undef);
        $self->body(undef);
    }
    elsif (! defined $self->content_length) {
        if (! ref $self->body && defined $self->body) {
            use bytes;
            $self->content_length(bytes::length($self->body));
        }
        elsif (ref $self->body eq 'ARRAY') {
            use bytes;
            $self->content_length(bytes::length(join q{}, @{$self->body}));
        }
    }
    if ($self->method eq 'HEAD') {
        $self->body(undef);
    }
    return $self;
}

sub _build_default_error_page {
    my($self) = @_;
    $self->content_type('text/html; charset=UTF-8');
    my $code = $self->code;
    my $content = q{};
    if ($self->fatals_to_browser) {
        my $error = $self->error;
        my %special = (
            q{&} => '&amp;', q{<} => '&lt;', q{>} => '&gt;',
            q{"} => '&quot;', q{'} => '&#39;',
        );
        $error =~ s{([<>"'&])}{ $special{$1} }gemsx;
        $content = qq{<pre>$error</pre>\n};
    }
    $self->body(<<"HTML");
<html>
<head>
<title>ERROR $code</title>
</head>
<body>
<h1>ERROR $code</h1>
$content</body>
</html>
HTML
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
        $self->{crlf} = $os =~ m/VMS/msxi ? "\n"
            : "\t" ne "\011" ? "\r\n"
            : "\015\012";
    }
    return $self->{crlf};
}

sub scan_header {
    my($self, $env) = @_;
    $env ||= $self->env;
    return map {
        /\A(?:HTTP|CONTENT)/msx ? do {
            (my $k = $_) =~ s/\AHTTP_//msx;
            $k = join q{-}, map { ucfirst lc } split /_/msx, $k;
            ($k => $env->{$_});
        } : ()
    } keys %{$env};
}

sub scan_cookie {
    my($self, $env) = @_;
    $env ||= $self->env;
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
    $env ||= $self->env;
    my $reader = $self->_proc_reader($env);
    my $body = q{};
    while (length $body < $env->{'CONTENT_LENGTH'}) {
        $reader->($body) or $self->_croak(400, 'Bad Request');
    }
    return $body;
}

sub scan_formdata {
    my($self, $env) = @_;
    $env ||= $self->env;
    my $method = $env->{'REQUEST_METHOD'} || 'GET';
    my $query = defined $env->{'QUERY_STRING'} ? $env->{'QUERY_STRING'}
        : defined $env->{'REDIRECT_QUERY_STRING'}
            ? defined $env->{'REDIRECT_QUERY_STRING'}
        : q{};
    my $c = {
        query_param => $self->_scan_urlencoded($query),
        body_param => [],
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
    $self->{code} = $code || 500;
    $self->{error} = $message || 'Internal Server Error';
    croak "$code $message";
}

sub _decode_uri {
    my($uri) = @_;
    $uri =~ tr/+/ /;
    $uri =~ s{%([0-9A-Fa-f]{2})}{ chr hex $1 }egmosx;
    return $uri;
}

sub _encode_uri {
    my($uri) = @_;
    if (utf8::is_utf8($uri)) {
        $uri = Encode::encode('utf-8', $uri);
    }
    $uri =~ s{([^a-zA-Z0-9_\-./])}{ sprintf '%%%02X', ord $1 }egmosx;
    return $uri;
}

sub _encode_uri_path {
    my($uri) = @_;
    if (utf8::is_utf8($uri)) {
        $uri = Encode::encode('utf-8', $uri);
    }
    $uri =~ s{
        (?:(\%([0-9A-Fa-f]{2})?)|([^a-zA-Z0-9_~\-.=+\$,:\@/?\&\#]))
    }{
        $2 ? $1 : $1 ? '%25' : sprintf '%%%02X', ord $3
    }egmosx;
    return $uri;
}

sub replace {
    my($self, $attr, @arg) = @_;
    if (ref $self->{$attr} eq 'HASH' && $attr ne 'env') {
        %{$self->{$attr}} = ();
        my $a = @arg == 1 && ref $arg[0] eq 'ARRAY' ? $arg[0] : \@arg;
        for (0 .. -1 + int @{$a} / 2) {
            my $i = $_ * 2;
            $self->$attr($a->[$i] => $a->[$i + 1]);
        }
    }
    else {
        $self->$attr(@arg);
    }
    return $self;
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
        if (@arg) {
            if (@arg == 1 && ! defined $arg[0]) {
                return if ! exists $self->{$attr}{$k};
                my $v = delete $self->{$attr}{$k};
                return wantarray ? @{$v} : $v->[-1];
            }
            if ($attr eq 'header' && lc $k ne 'set-cookie') {
                $self->{$attr}{$k}[0] = $arg[0];
            }
            elsif (@arg == 1 && ref $arg[0] eq 'ARRAY') {
                @{$self->{$attr}{$k}} = @{$arg[0]};
            }
            else {
                push @{$self->{$attr}{$k}}, @arg;
            }
        }
        return if ! exists $self->{$attr}{$k};
        return wantarray ? @{$self->{$attr}{$k}} : $self->{$attr}{$k}[-1];
    };
}

sub _scan_urlencoded {
    my($self, $data) = @_;
    defined $data or return [];
    my $nparam = 0;
    my $max_params = $self->max_params;
    my @param;
    for (split /[&;]/msx, $data) {
        last if ++$nparam > $max_params;
        my @pair = split /=/msx, $_, 2;
        if (@pair == 1) {
            unshift @pair, $self->keyword_name; # 'k'
        }
        next if @pair < 2 || $pair[0] eq q{}; # '', '=v'
        push @param, map { _decode_uri($_) } @pair;
    }
    return \@param;
}

sub _scan_multipart_formdata {
    my($self, $env) = @_;
    my $input = $env->{'psgi.input'};
    length $env->{'CONTENT_TYPE'} < 256 or $self->_croak(400, 'Bad Request');
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
        body_param => [],
        upload_info => [],
    };
    my $nparam = 0;
    my $max_params = $self->max_params;
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
                last if ++$nparam > $max_params;
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
    return {body_param => $c->{body_param}, upload_info => $c->{upload_info}};
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
        push @{$c->{body_param}}, $c->{taint} . $name, $c->{taint};
        return sub{ $c->{body_param}[-1] .= shift };
    }
    else {
        $enable_upload or return sub{};
        my $fh = IO::File->new_tmpfile or return sub{};
        binmode $fh;
        push @{$c->{body_param}}, $c->{taint} . $name, $c->{taint} . $filename;
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
        my($k, $v) = ($1, $+);
        if ($v =~ /\=\?.+\?\=/msx) {
            $v = Encode::decode('MIME-Header', $v);
        }
        else {
            $v = Encode::decode('UTF-8', _decode_uri($v));
        }
        $h{$k} = $v;
    }
    return @h{'name', 'filename'};
}

1;

__END__

=pod

=head1 NAME

CGI::Hatchet - low level request decoder and response container.

=head1 VERSION

0.015

=head1 SYNOPSIS

    use CGI::Hatchet;
    use File::Slurp;
    use Hash::MultiValue;
    
    $res = CGI::Hatchet->new(
        code => '200',
        header => ['Content-Type' => 'text/plain'],
        body => ['Hello, ', 'World!'],
        env => $env,
        post_max => 16 * 1024,
        enable_upload => 1,
    );
    $req = $res->new;
    
    # fetch parameters.
    my $ph = $res->scan_formdata;
    my $parameters = Hash::MultiValue->new(
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
    
    # you can access this module's param, upload, and upload_info attribute.
    $req->replace(param => $ph->{body_param});
    for (0 .. -1 + int @{$qh->{upload_info}} / 2) {
        my $i = $_ * 2;
        my $fh = delete $qh->{upload_info}[$i + 1]{handle};
        seek $fh, 0, 0;
        $req->upload($qh->{upload_info}[$i], $fh);
    }
    my $filename = $req->param('up');
    my $upload_body = File::Slurp::read_file($req->upload($filename));
    
    my $cookies = Hash::MultiValue->new($res->scan_cookie);
    # you may access this module'srequest_cookie attribute.
    $req->replace(request_cookie => $res->scan_cookie);
    for my $name ($req->request_cookie) {
        for my $value ($req->request_cookie($name)) {
            print "$name: $value\n";
        }
    }
    
    $res->code(200);
    $res->content_type('text/plain');
    $res->body(['Hello, ', 'World!']);
    $res->cookie('a' => q{}, 'expires' => time - 365 * 24 * 3600);
    $res->header('ETag' => q{"iU8ADFlEtdad3a"});
    $res->body(['Hello all.']);
    $res->redirect('http://another.net/', '303');
    $res->finalize_cookie;
    $res->normalize;
    my $psgi_res = $res->finalize;

=head1 DESCRIPTION

This module provides you to formdata decoder and response
for PSGI applications.

=head1 METHODS

=over

=item C<< new($key => $value, ...) >>
=item C<< new({$key => $value, ...}) >>

Create an instance with constructor inhjection.
Injectable attributes are:

    keyword_name => 'keyword',  # parameter name for nuked keyword.
    max_post => 100 * 1024,     # maximum post length in bytes.
    enable_upload => 0,         # 0: disable, 1: enable.
    block_size => 4 * 1024,     # read block size
    max_header => 1 * 1024,     # maximum header size in multipart/formdata
    fatals_to_browser => 0,     # 0: none, 1: appears error message.
    error_page_builder => undef,    # error page builder code reference.
    crlf => undef,              # crlf code in scalar, undef for auto detect.
    env => $env,                # PSGI environment hash reference.
    error => undef,             # error string.
    code => undef,              # status code for response.
    body => undef,              # body for response.
    header => {},               # header for request/response.
    cookie => {},               # cookie for response.
    request_cookie => {},       # cookie of request.
    param => {},                # parameters of request.
    upload => {},               # uploads of request.

=item C<< new(\%env) >>

Create an instance with a PSGI environment hash reference
as similar as C<< Plack::Request->new($env) >>.
The PSGI environment must have a key 'psgi.version'.

=item C<< new_response($rc, \@headers, \@body) >>

Create an instance with response status code, headers, and, body
as similar as C<< Plack::Request->new($env)->new_response(200) >>.

=item C<< keyword_name($string) >>

Sets/Gets parameter name for nuked keyword in query part such as:

    http://example.net/wiki?FrontPage

=item C<< max_post($integer) >>

Sets/Gets maximum content length limits the post entity in bytes.

=item C<< max_params($integer) >>

Sets/Gets maximum number of keys in QUERY or POST parameters
to avoid hashdos.

=item C<< enable_upload($bool) >>

Sets/Gets getting the feature of the uploaded files.

    0: disable
    1: enable.

=item C<< block_size($integer) >>

Sets/Gets Block size to read the POST entity.

=item C<< crlf($string) >>

Sets/Gets CRLF code.

=item C<< max_header($integer) >>

Sets/Gets Maximum header size limits in the multipart/formdata entity.

=item C<< env($key => $string) >>

Sets/Gets the PSGI environment hash reference.
This will be used in scan_formdata, scan_header, and, scan_cookie.

=item C<< address($string) >>

Gets the remote address. This is as same as C<< $c->env->{REMOTE_ADDR} >>.

=item C<< method($string) >>

Gets the request method. This is as same as C<< $c->env->{REQUEST_METHOD} >>.

=item C<< path($string) >>

Gets the path. This is as same as C<< $c->env->{PATH_INFO} || q{/} >>.

=item C<< path_info($string) >>

Gets the path_info. This is as same as C<< $c->env->{PATH_INFO} >>.

=item C<< port($string) >>

Gets the server port. This is as same as C<< $c->env->{SERVER_PORT} >>.

=item C<< protocol($string) >>

Gets the server protocol. This is as same as C<< $c->env->{SERVER_PROTOCOL} >>.

=item C<< remote_host($string) >>

Gets the remote host. This is as same as C<< $c->env->{REMOTE_HOST} >>.

=item C<< request_uri($string) >>

Gets the request uri. This is as same as C<< $c->env->{REQUEST_URI} >>.

=item C<< user($string) >>

Gets the remote user. This is as same as C<< $c->env->{REMOTE_USER} >>.

=item C<< scan_header(\%HASH) >>

Scans headers from PSGI environment hash references.
If there is no argument, C<< $self->env >> is used.

    $req->replace(header => $req->scan_header);

NOTICE: For each header, the name of it becomes the capitalized format always.
So that, some got names are differences from HTTP Standard's one.

    Got Name:           Standard Name:
    ------------------- --------------------
    Mime-Version        MIME-Version
    Te                  TE
    Www-Authenticate    WWW-Authenticate
    Content-Md5         Content-MD5
    Etag                ETag
    Uri                 URI

=item C<< scheme($string) >>

Gets the scheme. This is as same as C<< $c->env->{'psgi.scheme'} >>.

=item C<< script_name($string) >>

Gets the script name. This is as same as C<< $c->env->{SCRIPT_NAME} >>.

=item C<< secure($string) >>

Returns true if the scheme is https.
This is as same as C<< $c->env->{'psgi.scheme'} eq 'https' >>.

=item C<< code($digits) >>

Sets/Gets B<Response> status code.

=item C<< status($digits) >>

Sets/Gets B<Response> status code.
This is alias of the C<code> attribute.

=item C<< content_type($string) >>

Sets/Gets the Content-Type header.

=item C<< content_length($integer) >>

Sets/Gets the Content-Length header.

=item C<< header($name => $value) >>

Sets/Gets header value for given name.

=item C<< cookie($name => $value, expires => time - 3600) >>

Sets/Gets B<Response> cookies.

=item C<< body($string) >>

Sets/Gets B<Response> body.

=item C<< redirect($uri) >>

Sets/Gets B<Response> redirect pointer.

=item C<< finalize >>

Creates a PSGI (Perl Server Gateway Interface) response.

=item C<< normalize($env) >>

Takes status code, headers, and body under the care of
HTTP response rules.

=item C<< finalize_cookie >>

Creates Set-Cookie headers.

=item C<< fatals_to_browser($bool) >>

Enables reporting errors into the response body.

=item C<< error_page_builder($coderef) >>

Sets custom error page builder.

=item C<< scan_cookie($env) >>

Scans requested cookies from the PSGI env.
It returns a pair list of cookie's names and values.
It is comfortable that you treat the pair list through Hash::MultiValue.

    $cookies = Hash::MultiValue->new($q->scan_cookie($env));

or using request_cookie attribute.

    $q->replace(request_cookie, $q->scan_cookie($env));
    for my $k ($q->request_cookie) {
        my $v = $q->request_cookie($k);
    }

=item C<< scan_formdata($env) >>

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

=item C<< $body = read_body($env) >>

Reads entire content of the request.

=item C<< replace($attr_name => value) >>

Replaces the attribute contents.

    $q->replace('content_type' => 'text/html');
    $q->replace('enable_upload' => 0);
    $q->replace('param' => ('a' => 'A', 'b' => 'B', 'a' => 'C'));
    $q->replace('param' => ['a' => 'A', 'b' => 'B', 'a' => 'C']);
    $q->replace('cookie' => ('a' => {name => 'a', value => 'A'}));

=item C<< param($name) >>

Attribute for accessing formdata parameters similiar as CGI's one.
Before use this attribute, you must set scan_formdata result manually.

    $qh = $q->scan_formdata($env);
    $q->replace(
        param => @{$qh->{query_param}}, @{$qh->{body_param} || []},
    );
    for my $key ($q->param) {
        my $last_value = $q->param($key);
        my @values = $q->param($key);
    }
    $q->param($key, [@replace_values]);
    $q->param($key, @push_values);
    $q->param($key, undef); # delete $key and its values.

=item C<< upload($name) >>

Attribute for accessing formdata uploads similiar as CGI's one.
Before use this attribute, you must set scan_formdata result manually.

    $qh = $q->scan_formdata($env);
    $q->replace('upload'); # clear
    for (0 .. -1 + int @{$qh->{upload_info}} / 2) {
        my $i = $_ * 2;
        my $fh = delete $qh->{upload_info}[$i + 1]{handle};
        seek $fh, 0, 0;
        $q->upload($qh->{upload_info}[$i], $fh);
    }
    my $upload_body = File::Slurp::read_file($q->upload($upload_filename));

=item C<< request_cookie($name) >>

Attribute for accessing request cookies.
Before use this attribute, you must set scan_cookie result manually.

    $q->replace(request_cookie => $q->scan_cookie($env));
    for my $key ($q->request_cookie) {
        my $last_value = $q->request_cookie($key);
        my @values = $q->request_cookie($key);
    }
    $q->request_cookie($key, [@replace_values]);
    $q->request_cookie($key, @push_values);
    $q->request_cookie($key, undef); # delete $key and its values.

=item C<< error >>

Sets/Gets error message.

=back

=head1 DEPENDENCIES

L<IO::File>

=head1 SEE ALSO

L<CGI>, L<CGI::Simple>, L<PSGI>, L<Hash::MultiValue>

=head1 AUTHOR

MIZUTANI Tociyuki  C<< <tociyuki@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, MIZUTANI Tociyuki C<< <tociyuki@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
