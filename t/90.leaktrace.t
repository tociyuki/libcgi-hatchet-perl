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

    my $formdata = <<'EOS';
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=source

+++++++++[>++++++++>+++++++++++>+++++<<<-]
>.>++.+++++++..+++.>-.------------.<
++++++++.--------.+++.------.--------.>+.
--LMK8SN1abxqdYVn0QlDRB
Content-Disposition: form-data; name=interp; filename="bf.pl"
Content-Type: application/x-perl

use strict;
use warnings;

my $bf = shift @ARGV;
my $N = 100;
my @M = (0) x $N;
my $BF = {
  '>' => q{++$p;},
  '<' => q{--$p;},
  '+' => q{$M[$p] = $p >= 0 && $p < $N ? $M[$p] + 1 : die 'overflow';},
  '-' => q{$M[$p] = $p >= 0 && $p < $N ? $M[$p] - 1 : die 'overflow';},
  '.' => q{print chr($p >= 0 && $p < $N ? $M[$p] : die 'overflow');},
  ',' => q{die 'overflow' if $p < 0 || $p >= $N; $M[$p] = ord getc;},
  '[' => q{while ($p >= 0 && $p < $N ? $M[$p] : die 'overflow') } . '{',
  ']' => '}',
};
my $p = 0;
my $pl = join q{}, map { $BF->{$_} || q{} } split //msx, $bf;
my $code = eval "sub{$pl}";
if ($@) {
    die "compile error : $bf";
}
$code->();

--LMK8SN1abxqdYVn0QlDRB--
EOS

    open my($fh), '<', \$formdata;
    my $env = {
        'psgi.input' => $fh,
        REQUEST_METHOD => 'POST',
        CONTENT_TYPE => 'multipart/form-data; boundary=LMK8SN1abxqdYVn0QlDRB',
        CONTENT_LENGTH => length $formdata,
    };
    my $q = CGI::Hatchet->new(
        enable_upload => 0,
        crlf => "\n",
    );
    $q->scan_formdata($env);
    close $fh;
    return;
}

