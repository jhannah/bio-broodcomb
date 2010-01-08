use Test::More tests => 2;

use Bio::BroodComb;
use FindBin qw($Bin);
use lib "$Bin/lib";
use bctest_common;


# Do the deed.
ok(my $bc = Bio::BroodComb->new(),                              "new()");
ok($bc->initialize_database,                                    "initialize_database()");
ok($bc->load_large_seq(file => "$Bin/data/large_seq.fasta"),    "load_large_seq()");
ok($bc->load_small_seq(file => "$Bin/data/small_seq.fasta"),    "load_small_seq()");
ok($bc->find_subseqs(),                                         "find_subseqs()");
$bc->subseq_report1;

# Verify the results.
my $schema = bctest_common::init($bc->data_source);
is ($schema->resultset('BCTest::SmallSeq')->search()->count(), 3, "small_seq row count");
is ($schema->resultset('BCTest::LargeSeq')->search()->count(), 6, "large_seq row count");


