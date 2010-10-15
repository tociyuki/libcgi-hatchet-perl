use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    input => [qw(eval test_cookie test_sort)],
    expected => [qw(eval test_sort)],
};

run_is_deeply 'input' => 'expected';

sub test_sort { return [sort @{$_[0]}] }

sub test_cookie {
    my($a) = @_;
    my $q = CGI::Hatchet->new;
    for (@{$a}) {
        $q->cookie(@{$_});
    }
    $q->finalize_cookie;
    return [$q->header('Set-Cookie')];
}

__END__

=== single
--- input
[
    ['a' => 'A'],
]
--- expected
[
    q{a=A},
]

=== three
--- input
[
    ['a' => 'A'],
    ['b' => 'B'],
    ['c' => 'C'],
]
--- expected
[
    q{a=A},
    q{b=B},
    q{c=C},
]

=== domain
--- input
[
    ['a' => 'A', 'domain' => 'example.net'],
]
--- expected
[
    q{a=A; domain=example.net},
]

=== path
--- input
[
    ['a' => 'A', 'path' => q{/cgi-bin/example.cgi/?k=!%22%za}],
]
--- expected
[
    q{a=A; path=/cgi-bin/example.cgi/?k=%21%22%25za},
]

=== expires
--- input
[
    ['a' => 'A', 'expires' => 1287000000],
]
--- expected
[
    q{a=A; expires=Wed, 13-Oct-2010 20:00:00 GMT},
]

=== secure
--- input
[
    ['a' => 'A', 'secure' => 1],
]
--- expected
[
    q{a=A; secure},
]

=== httponly
--- input
[
    ['a' => 'A', 'httponly' => 1],
]
--- expected
[
    q{a=A; HttpOnly},
]

=== mix options
--- input
[
    ['a' => 'A',
        'expires' => 1287000000,
        'path' => q{/cgi-bin/example.cgi/?k=!%22%za},
        'secure' => 1,
        'domain' => 'example.net',
    ],
]
--- expected
[
    q{a=A; domain=example.net; path=/cgi-bin/example.cgi/?k=%21%22%25za; }
    . q{expires=Wed, 13-Oct-2010 20:00:00 GMT; secure},
]

=== empty value
--- input
[
    ['a' => '',
        'expires' => 1287000000,
    ],
]
--- expected
[
    q{a=; expires=Wed, 13-Oct-2010 20:00:00 GMT},
]

=== three mix options
--- input
[
    ['a' => 'A',
        'path' => q{/cgi-bin/example.cgi/?k=!%22%za},
        'domain' => 'example.net',
    ],
    ['b' => 'B',
        'expires' => 1287000000,
    ],
    ['c' => 'C',
        'secure' => 1,
    ],
]
--- expected
[
    q{a=A; domain=example.net; path=/cgi-bin/example.cgi/?k=%21%22%25za},
    q{b=B; expires=Wed, 13-Oct-2010 20:00:00 GMT},
    q{c=C; secure},
]

=== expires format
--- input
[
    ['m1' => 'jan', 'expires' => (14610 +   0) * 24 * 3600],
    ['m2' => 'feb', 'expires' => (14610 +  31) * 24 * 3600],
    ['m3' => 'mar', 'expires' => (14610 +  59) * 24 * 3600],
    ['m4' => 'apr', 'expires' => (14610 +  90) * 24 * 3600],
    ['m5' => 'may', 'expires' => (14610 + 120) * 24 * 3600],
    ['m6' => 'jun', 'expires' => (14610 + 151) * 24 * 3600],
    ['m7' => 'jul', 'expires' => (14610 + 181) * 24 * 3600],
    ['m8' => 'aug', 'expires' => (14610 + 212) * 24 * 3600],
    ['m9' => 'sep', 'expires' => (14610 + 243) * 24 * 3600],
    ['ma' => 'oct', 'expires' => (14610 + 273) * 24 * 3600],
    ['mb' => 'nov', 'expires' => (14610 + 304) * 24 * 3600],
    ['mc' => 'dec', 'expires' => (14610 + 334) * 24 * 3600],
],
--- expected
[
    q{m1=jan; expires=Fri, 01-Jan-2010 00:00:00 GMT},
    q{m2=feb; expires=Mon, 01-Feb-2010 00:00:00 GMT},
    q{m3=mar; expires=Mon, 01-Mar-2010 00:00:00 GMT},
    q{m4=apr; expires=Thu, 01-Apr-2010 00:00:00 GMT},
    q{m5=may; expires=Sat, 01-May-2010 00:00:00 GMT},
    q{m6=jun; expires=Tue, 01-Jun-2010 00:00:00 GMT},
    q{m7=jul; expires=Thu, 01-Jul-2010 00:00:00 GMT},
    q{m8=aug; expires=Sun, 01-Aug-2010 00:00:00 GMT},
    q{m9=sep; expires=Wed, 01-Sep-2010 00:00:00 GMT},
    q{ma=oct; expires=Fri, 01-Oct-2010 00:00:00 GMT},
    q{mb=nov; expires=Mon, 01-Nov-2010 00:00:00 GMT},
    q{mc=dec; expires=Wed, 01-Dec-2010 00:00:00 GMT},
]

