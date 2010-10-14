use strict;
use warnings;
use Test::More tests => 46;
use CGI::Hatchet;

{
    my $formdata = 'a=A&b=B&c=C';
    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new(env => {
        'psgi.input' => $fh,
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => length $formdata,
    });
    close $fh;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

{
    my $formdata = 'a=A&b=B&c=C';
    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new;
    $q->request_method('POST');
    $q->content_type('application/x-www-form-urlencoded');
    $q->content_length(length $formdata);
    $q->scan_formdata($fh);
    close $fh;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

sub post_formdata {
    my($formdata, %opt) = @_;
    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new(env => {
        'psgi.input' => $fh,
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => length $formdata,
    }, %opt);
    close $fh;
    return $q;
}

{
    my $q = post_formdata('a=A;b=B;c=C');
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
}

{
    my $q = post_formdata('foo=&bar===BAR=BAR==&=cow&baz&=&&');
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('foo')), q{}, 'foo is empty.');
    is((scalar $q->param('bar')), '==BAR=BAR==', 'bar is "==BAR=BAR=="');
    is((scalar $q->param('keyword')), 'baz', 'keyword is baz');
}

{
    my $q = post_formdata('a=A&a=B&a=C');
    my @keys = $q->param;
    is((scalar @keys), 1, 'returns correct number 1');
    is((scalar $q->param('a')), 'A', 'scalar a is A');
    is_deeply [$q->param('a')], ['A', 'B', 'C'], 'array a is [A, B, C]';
}

{
    my $q = post_formdata('A&b=B&a=C&D', keyword_name => 'a');
    my @keys = $q->param;
    is((scalar @keys), 2, 'returns correct number 2');
    is((scalar $q->param('a')), 'A', 'scalar a is A');
    is_deeply [$q->param('a')], ['A', 'C', 'D'], 'array a is [A, C, D]';
    is((scalar $q->param('b')), 'B', 'b is B');
}

{
    my $q = post_formdata('%61%62++%63d=%65%66++%67h');
    is_deeply [$q->param], ['ab  cd'], 'decode "%61%62++%63d"';
    is_deeply [$q->param('ab  cd')], ['ef  gh'], '"ab  cd" is "ef  gh"';
}

{
    my $formdata = 'a=A&b=B&c=C';
    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new(env => {
        'psgi.input' => $fh,
        REQUEST_METHOD => 'POST',
        QUERY_STRING => 'a=QA&b=QB',
        CONTENT_TYPE => 'application/x-www-form-urlencoded',
        CONTENT_LENGTH => length $formdata,
    });
    close $fh;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('a')), 'A', 'a is A');
    is((scalar $q->param('b')), 'B', 'b is B');
    is((scalar $q->param('c')), 'C', 'c is C');
    my @query_keys = $q->query_param;
    is((scalar @query_keys), 2, 'returns correct number 2');
    is((scalar $q->query_param('a')), 'QA', 'a is QA');
    is((scalar $q->query_param('b')), 'QB', 'b is QB');
}

{
my $jugemjs = <<'EOS' x 100;
// Jugeme.js -- A decoder of the quoted string
// Copyright (c) 2003 MIZUTANI Tociyuki All Rights Reserved.

var jugemu='AcEWseLMK8SN1abxqdYVn0QlDRB+/iX9pkTy43HPF65GUuOhojmtfzrvwgJC2IZ7=';

function jugemude(s) {
  var t='',p=-8,a=0,q=0,c,m,n;
  for(var i=0;i<s.length;i++) {
    a=(a<<6)|((jugemu.indexOf(s.charAt(i)))&63); p+=6;
    if(p>=0) {
      if((c=(a>>p)&255)>0)
        t+=String.fromCharCode(c);
      a&=63; p-=8;
    }
  }
  return t;
}
var qe6=jugemude('xLspBM83RyfT+Qe6+MdhbPdhDr3giQu6qLejiQsORQzkBQoO+HnOBPATxPdhDr3giQu6qLejiQsORQzkBQoO+HnOBPA2NrsZ');
EOS

my $formdata = <<"EOS";
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="lin"

ok
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=fil; filename="jugemude.js"
Content-Type: application/x-javascript; charset=UTF-8

$jugemjs
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="scr"

test

test2

--LMK8SN1abxqdYVn0QlDRB--
EOS

    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new(
        enable_upload => 1,
        crlf => "\n",
        env => {
            'psgi.input' => $fh,
            REQUEST_METHOD => 'POST',
            CONTENT_TYPE => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
            CONTENT_LENGTH => length $formdata,
        },
    );
    close $fh;
    my @keys = $q->param;
    is((scalar @keys), 3, 'returns correct number 3');
    is((scalar $q->param('lin')), 'ok', 'lin is ok');
    is((scalar $q->param('fil')), 'jugemude.js', 'fil is jugemude.js');
    is((scalar $q->param('scr')), "test\n\ntest2\n", 'scr is test..');
    my @info = $q->upload_info;
    is((scalar @info), 1, 'returns correct number 1');
    my $info = $q->upload_info('jugemude.js');
    my $uph = $info->{handle};
    seek $uph, 0, 0;
    my $data = do{ local $/ = undef; <$uph> };
    is $data, $jugemjs, 'data jugemude.js';
}

{
my $jugemjs = <<'EOS';
// Jugeme.js -- A decoder of the quoted string
// Copyright (c) 2003 MIZUTANI Tociyuki All Rights Reserved.

var jugemu='AcEWseLMK8SN1abxqdYVn0QlDRB+/iX9pkTy43HPF65GUuOhojmtfzrvwgJC2IZ7=';

function jugemude(s) {
  var t='',p=-8,a=0,q=0,c,m,n;
  for(var i=0;i<s.length;i++) {
    a=(a<<6)|((jugemu.indexOf(s.charAt(i)))&63); p+=6;
    if(p>=0) {
      if((c=(a>>p)&255)>0)
        t+=String.fromCharCode(c);
      a&=63; p-=8;
    }
  }
  return t;
}
var qe6=jugemude('xLspBM83RyfT+Qe6+MdhbPdhDr3giQu6qLejiQsORQzkBQoO+HnOBPATxPdhDr3giQu6qLejiQsORQzkBQoO+HnOBPA2NrsZ');
EOS

my $formdata = <<"EOS";
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="lin"

ok
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=fil; filename="jugemude.js"
Content-Type: application/x-javascript; charset=UTF-8

$jugemjs
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="scr"

test

test2

--LMK8SN1abxqdYVn0QlDRB--
EOS

    open my($fh), '<', \$formdata;
    my $q = CGI::Hatchet->new(
        enable_upload => 0,
        crlf => "\n",
        env => {
            'psgi.input' => $fh,
            REQUEST_METHOD => 'POST',
            CONTENT_TYPE => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
            CONTENT_LENGTH => length $formdata,
        },
    );
    close $fh;
    my @keys = $q->param;
    is((scalar @keys), 2, 'returns correct number 2');
    is((scalar $q->param('lin')), 'ok', 'lin is ok');
    is((scalar $q->param('fil')), undef, 'fil is undef');
    is((scalar $q->param('scr')), "test\n\ntest2\n", 'scr is test..');
    my @info = $q->upload_info;
    is((scalar @info), 0, 'returns correct number 0');
    is((scalar $q->upload_info('jugemude.js')), undef, 'jugemude.js is undef');
}

{
    my $q = CGI::Hatchet->new(
        enable_upload => 1,
        crlf => "\n",
    );
    my $jugemu = '!' x $q->max_post;

my $formdata = <<"EOS";
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="lin"

ok
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=fil; filename="jugemu"
Content-Type: application/x-javascript; charset=UTF-8

$jugemu
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="scr"

test

test2

--LMK8SN1abxqdYVn0QlDRB--
EOS

    open my($fh), '<', \$formdata;
    $q->prepare_env({
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
        CONTENT_LENGTH => length $formdata,
    });
    eval {
        $q->scan_formdata($fh);
    };
    ok $@, 'die on max_post.';
    my $err = $q->error;
    is_deeply [$err->[0], $err->[2][0]],
              [400, 'Bad Request'], 'too large error.';
}

