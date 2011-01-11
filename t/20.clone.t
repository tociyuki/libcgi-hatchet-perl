use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 1 * blocks;

run {
    my($block) = @_;
    my $q0 = CGI::Hatchet->new;

    my $attr = $block->name;
    my $input = (eval $block->input)->($q0->$attr, $q0);
    my $expected = $block->expected;
    my $description = $block->description || $block->name;

    $q0->replace($attr => $input);
    my $q1 = $q0->new;

    if (! defined $expected) {
        is $q1->$attr, $input, $description;
    }
    else {
        $expected = eval $expected;
        if (! ref $expected) {
            is $q1->$attr, $expected, $description;
        }
        elsif (ref $expected eq 'ARRAY') {
            is_deeply $q1->$attr, $expected, $description;
        }
        elsif (ref $expected eq 'HASH') {
            my @keys = $q1->$attr;
            is_deeply +{
                'keys' => {map { $_ => 1 } @keys},
                map { $_ => [ $q1->$attr($_) ] } @keys
            }, $expected, $description;
        }
    }
};

__END__

=== keyword_name
--- input
sub{ '_' . shift }

=== max_post
--- input
sub{ 4 * shift }

=== enable_upload
--- input
sub{ ! shift }

=== block_size
--- input
sub{ 4 * shift }

=== crlf
--- input
sub{ 'injected' }

=== max_header
--- input
sub{ 4 * shift }

=== error
--- input
sub{ 'injected' }
--- expected
undef

=== code
--- input
sub{ '200' }
--- expected
undef

=== content_type
--- input
sub{ 'application/x-perl-test' }
--- expected
undef

=== content_length
--- input
sub{ 128 }
--- expected
undef

=== body
--- input
sub{ ['Hello', 'World!'] }
--- expected
undef

=== fatals_to_browser
--- input
sub{ ! shift }

=== error_page_builder
--- input
sub{ 'injected' }

=== param
--- input
sub{ ['a' => 'A', 'b' => 'B', 'a' => 'A1'] }
--- expected
{'keys' => {}}

=== upload
--- input
sub{ ['a' => 'A', 'b' => 'B', 'a' => 'A1'] }
--- expected
{'keys' => {}}

=== request_cookie
--- input
sub{ ['a' => 'A', 'b' => 'B', 'a' => 'A1'] }
--- expected
{'keys' => {}}

=== header
--- input
sub{ ['A' => 'a0', 'A' => 'a1', 'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v'] }
--- expected
{'keys' => {}}

=== cookie
--- input
sub{ ['a' => 'a0', 'b' => {name => 'b', value => 'b0'}] }
--- expected
{'keys' => {}}

