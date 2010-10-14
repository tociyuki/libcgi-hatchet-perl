use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Hatchet',
    AUTHOR              => 'MIZUTANI Tociyuki <tociyuki@gmail.com>',
    VERSION_FROM        => 'lib/CGI/Hatchet.pm',
    ABSTRACT_FROM       => 'lib/CGI/Hatchet.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
