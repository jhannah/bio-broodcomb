use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bio::BroodComb',
    AUTHOR              => q{Jay Hannah <jay@jays.net>},
    VERSION_FROM        => 'lib/Bio/BroodComb.pm',
    ABSTRACT_FROM       => 'lib/Bio/BroodComb.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'Moose'           => 0,
        'DBIx::Class'     => 0,
        'DBD::SQLite'     => 0,
        'Bio::SeqIO'      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bio-BroodComb-*' },
);
