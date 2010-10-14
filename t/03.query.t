use strict;
use warnings;
use Test::More tests => 26;
use CGI::Hatchet;

{
    my $q = CGI::Hatchet->new(env => {
        QUERY_STRING => 'a=A&b=B&c=C',
    });

    is($q->query_string, 'a=A&b=B&c=C');
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

{
    my $q = CGI::Hatchet->new;
    $q->query_string('a=A&b=B&c=C');
    $q->scan_formdata;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

{
    my $q = CGI::Hatchet->new;
    $q->query_string('a=A;b=B;c=C');
    $q->scan_formdata;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

{
    my $q = CGI::Hatchet->new;
    $q->query_string('foo=&bar===BAR=BAR==&=cow&baz&=&&');
    $q->scan_formdata;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('foo')), q{}, 'foo is empty.');
    is((scalar $q->param('bar')), '==BAR=BAR==', 'bar is "==BAR=BAR=="');
    is((scalar $q->param('keyword')), 'baz', 'keyword is baz');
}

{
    my $q = CGI::Hatchet->new;
    $q->query_string('a=A&a=B&a=C');
    $q->scan_formdata;
    my @keys = $q->param;
    is((scalar @keys), 1, 'returns correct number 1');
    is((scalar $q->param('a')), 'A', 'scalar a is A');
    is_deeply [$q->param('a')], ['A', 'B', 'C'], 'array a is [A, B, C]';
}

{
    my $q = CGI::Hatchet->new;
    $q->keyword_name('a');
    $q->query_string('A&b=B&a=C&D');
    $q->scan_formdata;
    my @keys = $q->param;
    is((scalar @keys), 2, 'returns correct number 2');
    is((scalar $q->param('a')), 'A', 'scalar a is A');
    is_deeply [$q->param('a')], ['A', 'C', 'D'], 'array a is [A, C, D]';
    is((scalar $q->param('b')), 'B', 'b is B');
}

{
    my $q = CGI::Hatchet->new;
    $q->query_string('%61%62++%63d=%65%66++%67h');
    $q->scan_formdata;
    is_deeply [$q->param], ['ab  cd'], 'decode "%61%62++%63d"';
    is_deeply [$q->param('ab  cd')], ['ef  gh'], '"ab  cd" is "ef  gh"';
}

