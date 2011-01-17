use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    input => [qw(chomp test_scan_cookie)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

sub test_scan_cookie {
    my($input) = @_;
    return [CGI::Hatchet->new->scan_cookie({HTTP_COOKIE => $input})];
}

__END__

=== simple
--- input
foo=123; bar=qwerty; baz=wibble
--- expected
[
    'foo' => '123',
    'bar' => 'qwerty',
    'baz' => 'wibble',
]

=== baz=wib=ble
--- input
foo=123, bar=qwerty;  baz=wib=ble ; qux=1&2&
--- expected
[
    'foo' => '123',
    'bar' => 'qwerty',
    'baz' => 'wib=ble',
    'qux' => '1&2&',
]

=== baz=wibble;
--- input
foo=123; bar=qwerty; baz=wibble;
--- expected
[
    'foo' => '123',
    'bar' => 'qwerty',
    'baz' => 'wibble',
]

=== trim blanks
--- input
foo=vixen  ,  bar=cow  ;  baz=bitch  ;  qux=politician
--- expected
[
    'foo' => 'vixen',
    'bar' => 'cow',
    'baz' => 'bitch',
    'qux' => 'politician',
]

=== decode uri
--- input
foo=a%20phrase; bar=yes%2C%20a%20phrase; baz=%5Ewibble; qux=%27
--- expected
[
    'foo' => 'a phrase',
    'bar' => 'yes, a phrase',
    'baz' => '^wibble',
    'qux' => "'",
]

=== multi values
--- input
foo=vixen; foo=cow; foo=bitch
--- expected
[
    'foo' => 'vixen',
    'foo' => 'cow',
    'foo' => 'bitch',
]

=== broken pairs
--- input
foo=; =cow; baz; ;
--- expected
[
        'foo' => '',
]

