use strict;
use warnings;
my $LEAKTRACE;
BEGIN { $LEAKTRACE = eval{ require Test::LeakTrace }; }
use Test::More $LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;
use CGI::Hatchet;

process_cgi_hatchet();

leaks_cmp_ok { process_cgi_hatchet() } '<', 1;

sub process_cgi_hatchet {

    my $formdata = <<"EOS";
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name="lin"

ok
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=fil; filename="jugemude.js"
Content-Type: application/x-javascript; charset=UTF-8

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
    return;
}

