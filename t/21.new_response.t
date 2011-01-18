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
    my @inject = $block->inject ? (eval $block->inject) : ();
    my $expected = $block->expected;
    my $description = $block->description || $block->name;

    $q0->replace($attr => $input);
    my $q1 = $q0->new_response(@inject);

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
--- expected
undef

=== max_post
--- input
sub{ 4 * shift }
--- expected
undef

=== enable_upload
--- input
sub{ ! shift }
--- expected
undef

=== block_size
--- input
sub{ 4 * shift }
--- expected
undef

=== crlf
--- input
sub{ 'injected' }

=== max_header
--- input
sub{ 4 * shift }
--- expected
undef

=== error
--- input
sub{ 'injected' }

=== code
--- input
sub{ '200' }
--- expected
undef

=== code
code with inject
--- input
sub{ '200' }
--- inject
('304')
--- expected
'304'

=== code
code is undef to injected undef
--- input
sub{ '200' }
--- inject
(undef)
--- expected
undef

=== code
drop code inject on error
--- input
sub{ $_[1]->error('bad'); '500' }
--- inject
('200')
--- expected
'500'

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

=== content_length
drop content_length on inject body
--- input
sub{ 128 }
--- inject
('200', [], ['inject'])
--- expected
undef

=== body
--- input
sub{ ['Hello', 'World!'] }
--- expected
undef

=== body
replace body with inject
--- input
sub{ ['Hello', 'World!'] }
--- inject
(undef, [], 'injected')
--- expected
'injected'

=== body
undef body with inject undef
--- input
sub{ ['Hello', 'World!'] }
--- inject
(undef, undef, undef)
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

=== header
replace header with inject
--- input
sub{ ['A' => 'a0', 'A' => 'a1', 'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v'] }
--- inject
(undef, ['B' => 'b'])
--- expected
{
    'keys' => {map { $_ => 1 } 'B'},
    'B' => ['b'],
}

=== header
clear header with inject empty array
--- input
sub{ ['A' => 'a0', 'A' => 'a1', 'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v'] }
--- inject
(undef, [])
--- expected
{'keys' => {}}

=== header
pass header with inject undef
--- input
sub{ ['A' => 'a0', 'A' => 'a1', 'Set-Cookie' => 'u=', 'Set-Cookie' => 'k=v'] }
--- inject
(undef, undef)
--- expected
{'keys' => {}}

=== cookie
--- input
sub{ ['a' => 'a0', 'b' => {name => 'b', value => 'b0'}] }
--- expected
{'keys' => {}}

