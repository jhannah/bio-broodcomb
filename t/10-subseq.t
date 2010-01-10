use Test::More tests => 8;

use Bio::BroodComb;
use FindBin qw($Bin);


# Do the deed.
ok(my $bc = Bio::BroodComb->new(),                              "new()");
ok($bc->create_database,                                        "create_database()");
ok($bc->load_large_seq(file => "$Bin/data/large_seq.fasta"),    "load_large_seq()");
ok($bc->load_small_seq(file => "$Bin/data/small_seq.fasta"),    "load_small_seq()");
ok($bc->find_subseqs(),                                         "find_subseqs()");
#$bc->subseq_report1;

# Verify the results.
my $schema = $bc->schema;
is ($schema->resultset('BCTest::LargeSeq')->search()->count(), 3, "large_seq row count");
is ($schema->resultset('BCTest::SmallSeq')->search()->count(), 6, "small_seq row count");
my $rs = $schema->resultset('BCTest::HitPositions')->search({}, {order_by => 'id'});;
$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
my $expect = [
   {id=>1, large_seq_id=>1,small_seq_id=>1,begin=>6, end=>10},
   {id=>2, large_seq_id=>1,small_seq_id=>2,begin=>75,end=>71},
   {id=>3, large_seq_id=>1,small_seq_id=>5,begin=>72,end=>68},
   {id=>4, large_seq_id=>2,small_seq_id=>3,begin=>6, end=>10},
   {id=>5, large_seq_id=>2,small_seq_id=>3,begin=>57,end=>61},
   {id=>6, large_seq_id=>2,small_seq_id=>4,begin=>4, end=>8},
   {id=>7, large_seq_id=>2,small_seq_id=>4,begin=>21,end=>25},
   {id=>8, large_seq_id=>2,small_seq_id=>5,begin=>25,end=>29},
   {id=>9, large_seq_id=>3,small_seq_id=>5,begin=>75,end=>71},
   {id=>10,large_seq_id=>3,small_seq_id=>6,begin=>56,end=>60},
];
is_deeply([ $rs->all ],  $expect,                                 "hit_positions data");


1;



