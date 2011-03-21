use strict;
use warnings;
use Test::Base;
use CGI::Hatchet;

plan tests => 2 * blocks;

filters {
    option => [qw(eval)],
    env => [qw(eval)],
    expected => [qw(eval)],
};

run {
    my($block) = @_;
    my $q = CGI::Hatchet->new($block->option);
    my $env = $block->env;
    my $formdata = $block->formdata;
    if ($env->{CONTENT_TYPE} =~ m{www-form-urlencoded}msx) {
        chomp $formdata;
    }
    my $expected = $block->expected;
    my $upload_body = $block->body;
    my $expected_upload = @{$expected->{upload_info} || []};
    if ($expected_upload) {
        $formdata =~ s{<body>}{$upload_body}msx;
    }
    open my($fh), '<', \$formdata;
    $env->{'psgi.input'} = $fh;
    $env->{'CONTENT_LENGTH'} = length $formdata;
    my $ph = $q->scan_formdata($env);
    close $fh;
    my $got_body;
    if ($expected_upload) {
        my $uph = delete $ph->{upload_info}[1]{handle};
        seek $uph, 0, 0;
        $got_body = do{ local $/ = undef; <$uph> };
        $expected->{upload_info}[1]{'CONTENT_LENGTH'} = length $upload_body;
    }
    is_deeply $ph, $expected, $block->name . ' param';
    SKIP: {
        skip 'without upload', 1 unless $expected_upload;
        is $got_body, $upload_body, $block->name . ' upload body';
    }
};

__END__

=== simple
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
a=A&b=B&c=C
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
}
--- body

=== simple with query_param
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
    QUERY_STRING => 'q=Q&r=R',
}
--- formdata
a=A&b=B&c=C
--- expected
{
    query_param => [
        'q' => 'Q',
        'r' => 'R',
    ],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
}
--- body

=== simple a ; b ; c
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
a=A;b=B;c=C
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
}
--- body

=== complex foo, bar, keyword
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
foo=&bar===BAR=BAR==&=cow&baz&=&&
--- expected
{
    query_param => [],
    body_param => [
        'foo' => q{},
        'bar' => '==BAR=BAR==',
        'keyword' => 'baz',
    ],
}
--- body

=== multi values
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
a=A&a=B&a=C
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'a' => 'B',
        'a' => 'C',
    ],
}
--- body

=== multi keyword values
--- option
{keyword_name => 'a'}
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
A&b=B&a=C&D
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'a' => 'C',
        'a' => 'D',
    ],
}
--- body

=== decode uri
--- option
--- env
{
    REQUEST_METHOD => 'POST',
    CONTENT_TYPE => 'application/x-www-form-urlencoded',
}
--- formdata
%61%62++%63d=%65%66++%67h
--- expected
{
    query_param => [],
    body_param => [
        'ab  cd' => 'ef  gh',
    ],
}
--- body

=== simple multipart
--- option
{crlf => "\n"}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="a"

A
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="b"

B
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=a

A1
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="c"

C
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'a' => 'A1',
        'c' => 'C',
    ],
    upload_info => [],
}
--- body

=== multipart encoded name
--- option
{crlf => "\n"}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="=?UTF-8?B?44GC44GE?="

hiragana a hiragana i
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="%E3%82%A2%E3%82%A4"

katakana a katakana i
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        "\x{3042}\x{3044}" => 'hiragana a hiragana i',
        "\x{30a2}\x{30a4}" => 'katakana a katakana i',
    ],
    upload_info => [],
}
--- body

=== small block_size
--- option
{crlf => "\n", block_size => 8}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="a"

A
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="b"

B
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=a

A1
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="c"

C
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'a' => 'A1',
        'c' => 'C',
    ],
    upload_info => [],
}
--- body

=== multiline header
--- option
{crlf => "\n"}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="a"

A
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition:
 form-data; name="b"

B
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: 
 form-data;
 name="a"

A1
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition:
 form-data;
 
 name="c"

C
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'a' => 'A1',
        'c' => 'C',
    ],
    upload_info => [],
}
--- body

=== disable upload
--- option
{crlf => "\n", enable_upload => 0}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="a"

A
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="b"

B
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="up"; filename="ignore.txt"
Content-Type: text/plain

<body>
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="c"

C
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'c' => 'C',
    ],
    upload_info => [],
}
--- body
blib*
Makefile
Makefile.old
Build
Build.bat
_build*
pm_to_blib*
*.tar.gz
.lwpcookies
cover_db
pod2htm*.tmp

=== enable upload
--- option
{crlf => "\n", enable_upload => 1}
--- env
{
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE' => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
}
--- formdata
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="a"

A
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="b"

B
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="up"; filename="Artistic"
Content-Type: text/plain

<body>
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="c"

C
--LMK8SN1abxqdYVn0QlDRB--
--- expected
{
    query_param => [],
    body_param => [
        'a' => 'A',
        'b' => 'B',
        'up' => 'Artistic',
        'c' => 'C',
    ],
    upload_info => [
        'Artistic' => {
            'name' => 'up',
            'filename' => 'Artistic',
            'CONTENT_DISPOSITION' => q{form-data; name="up"; filename="Artistic"},
            'CONTENT_TYPE' => 'text/plain',
        },
    ],
}
--- body




			 The "Artistic License"

				Preamble

The intent of this document is to state the conditions under which a
Package may be copied, such that the Copyright Holder maintains some
semblance of artistic control over the development of the package,
while giving the users of the package the right to use and distribute
the Package in a more-or-less customary fashion, plus the right to make
reasonable modifications.

Definitions:

	"Package" refers to the collection of files distributed by the
	Copyright Holder, and derivatives of that collection of files
	created through textual modification.

	"Standard Version" refers to such a Package if it has not been
	modified, or has been modified in accordance with the wishes
	of the Copyright Holder as specified below.

	"Copyright Holder" is whoever is named in the copyright or
	copyrights for the package.

	"You" is you, if you're thinking about copying or distributing
	this Package.

	"Reasonable copying fee" is whatever you can justify on the
	basis of media cost, duplication charges, time of people involved,
	and so on.  (You will not be required to justify it to the
	Copyright Holder, but only to the computing community at large
	as a market that must bear the fee.)

	"Freely Available" means that no fee is charged for the item
	itself, though there may be fees involved in handling the item.
	It also means that recipients of the item may redistribute it
	under the same conditions they received it.

1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.

2. You may apply bug fixes, portability fixes and other modifications
derived from the Public Domain or from the Copyright Holder.  A Package
modified in such a way shall still be considered the Standard Version.

3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and
when you changed that file, and provided that you do at least ONE of the
following:

    a) place your modifications in the Public Domain or otherwise make them
    Freely Available, such as by posting said modifications to Usenet or
    an equivalent medium, or placing the modifications on a major archive
    site such as uunet.uu.net, or by allowing the Copyright Holder to include
    your modifications in the Standard Version of the Package.

    b) use the modified Package only within your corporation or organization.

    c) rename any non-standard executables so the names do not conflict
    with standard executables, which must also be provided, and provide
    a separate manual page for each non-standard executable that clearly
    documents how it differs from the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

4. You may distribute the programs of this Package in object code or
executable form, provided that you do at least ONE of the following:

    a) distribute a Standard Version of the executables and library files,
    together with instructions (in the manual page or equivalent) on where
    to get the Standard Version.

    b) accompany the distribution with the machine-readable source of
    the Package with your modifications.

    c) give non-standard executables non-standard names, and clearly
    document the differences in manual pages (or equivalent), together
    with instructions on where to get the Standard Version.

    d) make other distribution arrangements with the Copyright Holder.

5. You may charge a reasonable copying fee for any distribution of this
Package.  You may charge any fee you choose for support of this
Package.  You may not charge a fee for this Package itself.  However,
you may distribute this Package in aggregate with other (possibly
commercial) programs as part of a larger (possibly commercial) software
distribution provided that you do not advertise this Package as a
product of your own.  You may embed this Package's interpreter within
an executable of yours (by linking); this shall be construed as a mere
form of aggregation, provided that the complete Standard Version of the
interpreter is so embedded.

6. The scripts and library files supplied as input to or produced as
output from the programs of this Package do not automatically fall
under the copyright of this Package, but belong to whoever generated
them, and may be sold commercially, and may be aggregated with this
Package.  If such scripts or library files are aggregated with this
Package via the so-called "undump" or "unexec" methods of producing a
binary executable image, then distribution of such an image shall
neither be construed as a distribution of this Package nor shall it
fall under the restrictions of Paragraphs 3 and 4, provided that you do
not represent such an executable image as a Standard Version of this
Package.

7. C subroutines (or comparably compiled subroutines in other
languages) supplied by you and linked into this Package in order to
emulate subroutines and variables of the language defined by this
Package shall not be considered part of this Package, but are the
equivalent of input as in Paragraph 6, provided these subroutines do
not change the language in any way that would cause it to fail the
regression tests for the language.

8. Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution.  Such use shall not be
construed as a distribution of this Package.

9. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.

10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

				The End

