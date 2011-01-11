use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    input => [qw(eval)],
    expected => [qw(eval)],
};

run {
    my($block) = @_;
    my $q = CGI::Hatchet->new;
    my $input = $block->input;
    while (my($k, $v) = each %{$input->{property}}) {
        $q->replace($k => $v);
    }
    $q->normalize($input->{env});
    my @headers = $q->header;
    is_deeply +{
        code => $q->code,
        header => {
            'keys' => {map { $_ => 1 } @headers},
            map { $_ => [ $q->header($_) ] } @headers,
        },
        body => $q->body,
    }, $block->expected, $block->name;
};

__END__

=== GET 200 Ok scalar body with content-length
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        content_length => length $body,
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== GET 200 Ok array body with content-length
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        content_length => length $body,
        body => [$body],
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => [$body],
}

=== GET 200 Ok other body with content-length
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        content_length => length $body,
        body => {content => $body},
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => {content => $body},
}

=== GET 200 Ok scalar body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== GET 200 Ok array body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => [$body],
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => [$body],
}

=== GET 200 Ok other body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => {content => $body},
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => {content => $body},
}

=== HEAD 200 Ok scalar body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'HEAD',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => undef,
}

=== HEAD 200 Ok array body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'HEAD',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => [$body],
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => undef,
}

=== HEAD 200 Ok other body
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
{
    env => {
        REQUEST_METHOD => 'HEAD',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '200',
        content_type => 'text/html; charset=UTF-8',
        body => {content => $body},
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '200',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => undef,
}

=== GET 100 Continue
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '100',
        content_type => 'text/html; charset=UTF-8',
        content_length => length $body,
        body => $body,
    },
}
--- expected
+{
    code => '100',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => undef,
}

=== GET 204 No Content
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '204',
        content_type => 'text/html; charset=UTF-8',
        content_length => length $body,
        body => $body,
    },
}
--- expected
+{
    code => '204',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => undef,
}

=== GET 303 See Other
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '303',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
            'Location' => 'http://example.net/',
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '303',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length', 'Location'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
        'Location' => ['http://example.net/'],
    },
    body => $body,
}

=== GET HTTP/1.0 303 See Other
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.0',
    },
    property => {
        code => '303',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
            'Location' => 'http://example.net/',
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '302',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length', 'Location'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
        'Location' => ['http://example.net/'],
    },
    body => $body,
}

=== GET 304 Not Modified
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '304',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '304',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => undef,
}

=== GET HTTP/1.0 304 Not Modified
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.0',
    },
    property => {
        code => '304',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '304',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type'},
        'Content-Type' => ['text/html; charset=UTF-8'],
    },
    body => undef,
}

=== GET 307 Tempolary Redirect
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '307',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
            'Location' => 'http://example.net/',
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '307',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length', 'Location'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
        'Location' => ['http://example.net/'],
    },
    body => $body,
}

=== GET HTTP/1.0 307 Tempolary Redirect
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.0',
    },
    property => {
        code => '307',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
            'Location' => 'http://example.net/',
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    code => '302',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length', 'Location'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
        'Location' => ['http://example.net/'],
    },
    body => $body,
}

=== GET 400 Bad Request
--- input
my $body = '<html><head><title>Bad</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '400',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Bad</title></head><body></body></html>';
+{
    code => '400',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== GET 500 Internal Server Error
--- input
my $body = '<html><head><title>Error</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '500',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
        ],
        body => $body,
    },
}
--- expected
my $body = '<html><head><title>Error</title></head><body></body></html>';
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== error is 404
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '404',
        content_type => 'text/html; charset=UTF-8',
        error => 'Not Found',
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 404</title>
</head>
<body>
<h1>ERROR 404</h1>
</body>
</html>
HTML
+{
    code => '404',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== error is 500, fatals_to_browser is false
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        fatals_to_browser => 0,
        code => '500',
        content_type => 'text/html; charset=UTF-8',
        error => "There is something to be wrong, it will.\n",
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 500</title>
</head>
<body>
<h1>ERROR 500</h1>
</body>
</html>
HTML
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== error is 500, fatals_to_browser is true
--- input
my $body = '<html><head><title>Hello, World</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        fatals_to_browser => 1,
        code => '500',
        content_type => 'text/html; charset=UTF-8',
        error => "There is something to be wrong, it will.\n",
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 500</title>
</head>
<body>
<h1>ERROR 500</h1>
<pre>There is something to be wrong, it will.
</pre>
</body>
</html>
HTML
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== error clears Location and Set-Cookie headers
--- input
my $body = '<html><head><title>Error</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '303',
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
            'Content-Length' => length $body,
            'Location' => 'http://example.net/',
            'Set-Cookie' => 'a=A',
            'Set-Cookie' => 'b=B',
        ],
        error => "There is something to be wrong, it will.\n",
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 500</title>
</head>
<body>
<h1>ERROR 500</h1>
</body>
</html>
HTML
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== error with custom builder
--- input
my $body = 'Hello, World';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        code => '500',
        content_type => 'text/html; charset=UTF-8',
        error => "There is something to be wrong, it will.\n",
        error_page_builder => sub{
            my($q) = @_;
            $q->content_type('application/xml; charset=UTF-8'),
            $q->body('<result><error code="1" /></result>');
        },
        body => $body,
    },
}
--- expected
my $body = '<result><error code="1" /></result>';
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['application/xml; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== undefined code
--- input
my $body = '<html><head><title>Error</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
        ],
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 500</title>
</head>
<body>
<h1>ERROR 500</h1>
</body>
</html>
HTML
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

=== undefined code, fatals_to_browser is true
--- input
my $body = '<html><head><title>Error</title></head><body></body></html>';
+{
    env => {
        REQUEST_METHOD => 'GET',
        SERVER_PROTOCOL => 'HTTP/1.1',
    },
    property => {
        fatals_to_browser => 1,
        header => [
            'Content-Type' => 'text/html; charset=UTF-8',
        ],
        body => $body,
    },
}
--- expected
my $body = <<"HTML";
<html>
<head>
<title>ERROR 500</title>
</head>
<body>
<h1>ERROR 500</h1>
<pre>Undefined code</pre>
</body>
</html>
HTML
+{
    code => '500',
    header => {
        'keys' => {map { $_ => 1 } 'Content-Type', 'Content-Length'},
        'Content-Type' => ['text/html; charset=UTF-8'],
        'Content-Length' => [length $body],
    },
    body => $body,
}

