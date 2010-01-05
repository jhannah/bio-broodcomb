#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::BroodComb' ) || print "Bail out!
";
}

diag( "Testing Bio::BroodComb $Bio::BroodComb::VERSION, Perl $], $^X" );
