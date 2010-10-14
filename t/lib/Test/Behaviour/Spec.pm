package Test::Behaviour::Spec;
use strict;
use warnings;
use Exporter;

use version; our $VERSION = '0.01';

our @EXPORT = qw(describe it spec);
our @ISA = qw(Exporter);

our $subject = q{};
our $statement = q{};

sub describe {
    $subject = shift || q{};
    $statement = q{};
}

sub it   { $statement = shift || q{} }
sub spec { join(q{ }, $subject, $statement) }

1;

