use Test::More tests => 2;

use Bio::BroodComb;
use FindBin qw($Bin);

ok(my $bc = Bio::BroodComb->new(),       "new()");
ok($bc->initialize_database,             "initialize_database()");

$bc->load_large_seq(file => "$Bin/data/large_seq.fasta");
$bc->load_small_seq(file => "$Bin/data/small_seq.fasta");


