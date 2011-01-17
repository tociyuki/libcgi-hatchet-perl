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
    input => [qw(eval test_scan_header)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

sub test_scan_header {
    my($input) = @_;
    return sort_header(CGI::Hatchet->new->scan_header($input));
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

=== ignore
--- input
{
    '.foo' => 'ignore',
}
--- expected
[]

=== headers
--- input
{
    'HTTP_CACHE_CONTROL' => 'a',
    'HTTP_CONNECTION' => 'b',
    'HTTP_DATE' => 'c',
    'HTTP_MIME_VERSION' => 'd',
    'HTTP_PRAGMA' => 'e',
    'HTTP_TRANSFER_ENCODING' => 'f',
    'HTTP_UPGRADE' => 'g',
    'HTTP_VIA' => 'h',
    'HTTP_ACCEPT' => 'i',
    'HTTP_ACCEPT_CHARSET' => 'j',
    'HTTP_ACCEPT_ENCODING' => 'k',
    'HTTP_ACCEPT_LANGUAGE' => 'l',
    'HTTP_AUTHORIZATION' => 'm',
    'HTTP_EXPECT' => 'n',
    'HTTP_FROM' => 'o',
    'HTTP_HOST' => 'p',
    'HTTP_IF_MATCH' => 'q',
    'HTTP_IF_MODIFIED_SINCE' => 'r',
    'HTTP_IF_NONE_MATCH' => 's',
    'HTTP_IF_RANGE' => 't',
    'HTTP_IF_UNMODIFIED_SINCE' => 'u',
    'HTTP_MAX_FORWARDS' => 'v',
    'HTTP_PROXY_AUTHORIZATION' => 'w',
    'HTTP_RANGE' => 'x',
    'HTTP_REFERER' => 'y',
    'HTTP_TE' => 'z',
    'HTTP_USER_AGENT' => 'A',
    'HTTP_ACCEPT_RANGES' => 'B',
    'HTTP_AGE' => 'C',
    'HTTP_LOCATION' => 'D',
    'HTTP_PROXY_AUTHENTICATE' => 'E',
    'HTTP_RETRY_AFTER' => 'F',
    'HTTP_SERVER' => 'G',
    'HTTP_VARY' => 'H',
    'HTTP_WARNING' => 'I',
    'HTTP_WWW_AUTHENTICATE' => 'J',
    'HTTP_ALLOW' => 'K',
    'CONTENT_BASE' => 'L',
    'CONTENT_ENCODING' => 'M',
    'CONTENT_LANGUAGE' => 'N',
    'CONTENT_LENGTH' => 'O',
    'CONTENT_LOCATION' => 'P',
    'CONTENT_MD5' => 'Q',
    'CONTENT_RANGE' => 'R',
    'CONTENT_TYPE' => 'S',
    'HTTP_ETAG' => 'T',
    'HTTP_EXPIRES' => 'U',
    'HTTP_LAST_MODIFIED' => 'V',
    'HTTP_URI' => 'W',
    'HTTP_COOKIE' => 'X',
    'HTTP_SET_COOKIE' => 'Y',
}
--- expected
[
    'Cache-Control' => 'a',
    'Connection' => 'b',
    'Date' => 'c',
    'Mime-Version' => 'd',
    'Pragma' => 'e',
    'Transfer-Encoding', => 'f',
    'Upgrade' => 'g',
    'Via' => 'h',
    'Accept' => 'i',
    'Accept-Charset' => 'j',
    'Accept-Encoding' => 'k',
    'Accept-Language' => 'l',
    'Authorization' => 'm',
    'Expect' => 'n',
    'From' => 'o',
    'Host' => 'p',
    'If-Match' => 'q',
    'If-Modified-Since' => 'r',
    'If-None-Match' => 's',
    'If-Range' => 't',
    'If-Unmodified-Since' => 'u',
    'Max-Forwards' => 'v',
    'Proxy-Authorization' => 'w',
    'Range' => 'x',
    'Referer' => 'y',
    'Te' => 'z',
    'User-Agent' => 'A',
    'Accept-Ranges' => 'B',
    'Age' => 'C',
    'Location' => 'D',
    'Proxy-Authenticate' => 'E',
    'Retry-After' => 'F',
    'Server' => 'G',
    'Vary' => 'H',
    'Warning' => 'I',
    'Www-Authenticate' => 'J',
    'Allow' => 'K',
    'Content-Base' => 'L',
    'Content-Encoding' => 'M',
    'Content-Language' => 'N',
    'Content-Length' => 'O',
    'Content-Location' => 'P',
    'Content-Md5' => 'Q',
    'Content-Range' => 'R',
    'Content-Type' => 'S',
    'Etag' => 'T',
    'Expires' => 'U',
    'Last-Modified' => 'V',
    'Uri' => 'W',
    'Cookie' => 'X',
    'Set-Cookie' => 'Y',
]

