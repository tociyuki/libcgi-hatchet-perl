use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

my @HEADER_NANE = qw(
    Cache-Control Connection Date MIME-Version Pragma Transfer-Encoding
    Upgrade Via Accept Accept-Charset Accept-Encoding Accept-Language
    Authorization Expect From Host
    If-Match If-Modified-Since If-None-Match If-Range If-Unmodified-Since
    Max-Forwards Proxy-Authorization Range Referer TE User-Agent
    Accept-Ranges Age Location Proxy-Authenticate Retry-After Server
    Vary Warning WWW-Authenticate
    Allow Content-Base Content-Encoding Content-Language Content-Length
    Content-Location Content-MD5 Content-Range Content-Type ETag Expires
    Last-Modified URI Cookie Set-Cookie
);

my %HEADER_ORDER = map {
    lc $HEADER_NANE[$_] => sprintf '%3d', $_ + 1
} 0 .. $#HEADER_NANE;

plan tests => 1 * blocks;

filters {
    input => [qw(eval test_finalize)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

sub test_finalize {
    my $res = CGI::Hatchet->new_response(@_)->finalize;
    $res->[1] = sort_header($res->[1]);
    return $res;
}

sub sort_header {
    my(@arg) = @_;
    my $q = CGI::Hatchet->new_response;
    $q->replace(header => @arg);
    return [
        map {
            my $name = $_;
            map { $name => $_ } $q->header($name);
        } sort {
            ($HEADER_ORDER{lc $a} || $a) cmp ($HEADER_ORDER{lc $b} || $b)
        } $q->header,
    ];
}

__END__

=== array body
--- input
('200', ['Content-Type' => 'text/plain'], ['hello', 'world'])
--- expected
['200', ['Content-Type' => 'text/plain'], ['hello', 'world']]

=== scalar body
--- input
('200', ['Content-Type' => 'text/plain'], 'hello, world')
--- expected
['200', ['Content-Type' => 'text/plain'], ['hello, world']]

=== ref body
--- input
('200', ['Content-Type' => 'text/plain'], {content => 'hello, world'})
--- expected
['200', ['Content-Type' => 'text/plain'], {content => 'hello, world'}]

=== set-cookies
--- input
(
    '200',
    [
        'Content-Type' => 'text/html; charset=UTF-8',
        'ETag' => q{"aWe35tgd"},
        'Set-Cookie' => 'a=A',
        'Set-Cookie' => 'b=B',
        'Last-Modified' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Date' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Expires' => 'Mon, 18 Nov 2010 00:01:02 GMT',
        'Pragma' => 'no-cache',
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
)
--- expected
[
    '200',
    [
        'Date' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Pragma' => 'no-cache',
        'Content-Type' => 'text/html; charset=UTF-8',
        'ETag' => q{"aWe35tgd"},
        'Expires' => 'Mon, 18 Nov 2010 00:01:02 GMT',
        'Last-Modified' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Set-Cookie' => 'a=A',
        'Set-Cookie' => 'b=B',
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
]

=== malformed header
--- input
(
    '303',
    [
        'Content-Type' => 'text/html; charset=UTF-8',
        'Location' => "http://example.net/ \n\n\n \n\n<script>alert('evil')</script>",
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
)
--- expected
[
    '303',
    [
        'Location' => "http://example.net/ \x0d\x0a \x0d\x0a <script>alert('evil')</script>",
        'Content-Type' => 'text/html; charset=UTF-8',
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
]

=== protect xss
--- input
(
    '200',
    [
        'Content-Type' => 'text/plain; charset=UTF-8',
        'X-Attachment' => "\nContent-Type: text/html\n\n \n\n\n \n\n<script>alert('evil')</script>\n\n",
    ],
    ['Funny'],
)
--- expected
[
    '200',
    [
        'Content-Type' => 'text/plain; charset=UTF-8',
        'X-Attachment' => "\x0d\x0a Content-Type: text/html\x0d\x0a \x0d\x0a \x0d\x0a <script>alert('evil')</script>",
    ],
    ['Funny'],
]

