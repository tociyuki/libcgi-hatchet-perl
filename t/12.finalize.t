use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    input => [qw(eval test_finalize sort_header)],
    expected => [qw(eval sort_header)],
};

run_is_deeply 'input' => 'expected';

sub test_finalize {
    return CGI::Hatchet->new_response(@_)->finalize;
}

sub sort_header {
    my($res) = @_;
    my @a;
    for (0 .. -1 + int @{$res->[1]} / 2) {
        my $i = $_ * 2;
        push @a, [
            $res->[1][$i] . q{:} . $res->[1][$i + 1],
            $res->[1][$i] => $res->[1][$i + 1],
        ];
    }
    @a = sort { $a->[0] cmp $b->[0] } @a;
    return [$res->[0], [map { $_->[1] => $_->[2] } @a], $res->[2]];
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
        'Etag' => q{"aWe35tgd"},
        'Last-Modified' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Date' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Expires' => 'Mon, 18 Nov 2010 00:01:02 GMT',
        'Pragma' => 'no-cache',
        'Set-Cookie' => 'a=A',
        'Set-Cookie' => 'b=B',
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
)
--- expected
[
    '200',
    [
        'Content-Type' => 'text/html; charset=UTF-8',
        'Etag' => q{"aWe35tgd"},
        'Last-Modified' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Date' => 'Sun, 17 Nov 2010 00:01:02 GMT',
        'Expires' => 'Mon, 18 Nov 2010 00:01:02 GMT',
        'Pragma' => 'no-cache',
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
        'Content-Type' => 'text/html; charset=UTF-8',
        'Location' => "http://example.net/ \x0d\x0a \x0d\x0a <script>alert('evil')</script>",
    ],
    ['<html><head><title>Hello, World</title></head><body></body></html>'],
]

=== protect xss
--- input
(
    '200',
    [
        'Content-Type' => 'text/plain; charset=UTF-8',
        'Attachment' => "\nContent-Type: text/html\n\n \n\n\n \n\n<script>alert('evil')</script>\n\n",
    ],
    ['Funny'],
)
--- expected
[
    '200',
    [
        'Content-Type' => 'text/plain; charset=UTF-8',
        'Attachment' => "\x0d\x0a Content-Type: text/html\x0d\x0a \x0d\x0a \x0d\x0a <script>alert('evil')</script>",
    ],
    ['Funny'],
]

