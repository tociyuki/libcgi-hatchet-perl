use strict;
use warnings;
use Test::More tests => 30;
use CGI::Hatchet;

{
    my $q = CGI::Hatchet->new(env => {
        HTTP_COOKIE => 'foo=123; bar=qwerty; baz=wibble',
    });

    is($q->raw_cookie, 'foo=123; bar=qwerty; baz=wibble', 'raw_cookie');
    my @keys = $q->cookie;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->cookie('foo')), '123',       'foo is 123');
    is((scalar $q->cookie('bar')), 'qwerty',    'bar is qwerty');
    is((scalar $q->cookie('baz')), 'wibble',    'baz is wibble');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=123, bar=qwerty;  baz=wib=ble ; qux=1&2&');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 4, 'returns correct number 4');
    is((scalar $q->cookie('foo')), '123',       'cookie foo is 123');
    is((scalar $q->cookie('bar')), 'qwerty',    'cookie bar is qwerty');
    is((scalar $q->cookie('baz')), 'wib=ble',   'cookie baz is wib=ble');
    is((scalar $q->cookie('qux')), '1&2&',      'cookie qux is 1&2&');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=123; bar=qwerty; baz=wibble;');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->cookie('foo')), '123',       'foo is 123');
    is((scalar $q->cookie('bar')), 'qwerty',    'bar is qwerty');
    is((scalar $q->cookie('baz')), 'wibble',    'baz is wibble');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=vixen   ,   bar=cow   ;   baz=bitch    ;   qux=politician');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 4, 'returns correct number 4');
    is((scalar $q->cookie('foo')), 'vixen',     'foo is vixen');
    is((scalar $q->cookie('bar')), 'cow',       'bar is cow');
    is((scalar $q->cookie('baz')), 'bitch',     'baz is bitch');
    is((scalar $q->cookie('qux')), 'politician','qux is politician');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=a%20phrase; bar=yes%2C%20a%20phrase; baz=%5Ewibble; qux=%27');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 4, 'returns correct number 4');
    is((scalar $q->cookie('foo')), 'a phrase',      "foo is 'a phrase'");
    is((scalar $q->cookie('bar')), 'yes, a phrase', "bar is 'yes, a phrase'");
    is((scalar $q->cookie('baz')), '^wibble',       "baz is '^wibble'");
    is((scalar $q->cookie('qux')), "'",             'qux is "\'"');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=vixen; foo=cow; foo=bitch');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 1, 'returns correct number 1');
    is_deeply [$q->cookie('foo')], [qw(vixen cow bitch)],   'multiple foo';
    is((scalar $q->cookie('foo')), 'vixen',     'scalar foo is vixen');
}

{
    my $q = CGI::Hatchet->new;
    $q->raw_cookie('foo=; =cow; baz; ;');
    $q->scan_cookie;

    my @keys = $q->cookie;
    is((scalar @keys), 2, 'returns correct number 1');
    is((scalar $q->cookie('foo')), q{},     'foo is empty');
    is((scalar $q->cookie('baz')), q{},     'baz is empty');
}

