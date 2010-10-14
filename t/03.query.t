use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    input => [qw(eval test_scan_formdata)],
    expected => [qw(eval)],
};

run_is_deeply 'input' => 'expected';

sub test_scan_formdata {
    my($env) = @_;
    return CGI::Hatchet->new->scan_formdata($env);
}

__END__

=== simple a & b & c
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'a=A&b=B&c=C',
}
--- expected
{
    query_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
}

=== simple a ; b ; c
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'a=A;b=B;c=C',
}
--- expected
{
    query_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
}

=== complex foo, bar, keyword
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'foo=&bar===BAR=BAR==&=cow&baz&=&&',
}
--- expected
{
    query_param => [
        'foo' => q{},
        'bar' => '==BAR=BAR==',
        'keyword' => 'baz',
    ],
}

=== multi values
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'a=A&a=B&a=C',
}
--- expected
{
    query_param => [
        'a' => 'A',
        'a' => 'B',
        'a' => 'C',
    ],
}

=== multi keyword values
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'A&b=B&keyword=C&D',
}
--- expected
{
    query_param => [
        'keyword' => 'A',
        'b' => 'B',
        'keyword' => 'C',
        'keyword' => 'D',
    ],
}

=== decode uri
--- input
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => '%61%62++%63d=%65%66++%67h',
}
--- expected
{
    query_param => [
        'ab  cd' => 'ef  gh',
    ],
}

