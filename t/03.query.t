use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

filters {
    option => [qw(eval)],
    env => [qw(eval)],
    expected => [qw(eval)],
};

run {
    my($block) = @_;
    my $q = CGI::Hatchet->new($block->option);
    is_deeply $q->scan_formdata($block->env), $block->expected, $block->name;
};

__END__

=== simple a & b & c
--- option
--- env
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
    body_param => [],
}

=== simple a ; b ; c
--- option
--- env
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
    body_param => [],
}

=== complex foo, bar, keyword
--- option
--- env
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
    body_param => [],
}

=== multi values
--- option
--- env
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
    body_param => [],
}

=== multi keyword values
--- option
{keyword_name => 'a'}
--- env
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'A&b=B&a=C&D',
}
--- expected
{
    query_param => [
        'a' => 'A',
        'b' => 'B',
        'a' => 'C',
        'a' => 'D',
    ],
    body_param => [],
}

=== decode uri
--- option
--- env
{
    REQUEST_METHOD => 'GET',
    QUERY_STRING => '%61%62++%63d=%65%66++%67h',
}
--- expected
{
    query_param => [
        'ab  cd' => 'ef  gh',
    ],
    body_param => [],
}

