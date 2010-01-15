use Test::More tests => 9;

use Bio::BroodComb;
use FindBin qw($Bin);

# Do the deed.
ok(my $bc = Bio::BroodComb->new(),                              "new()");
ok($bc->create_database,                                        "create_database()");
ok($bc->load_large_seq(file => "$Bin/data/large_seq.fasta"),    "load_large_seq()");
ok($bc->add_primerset(
      description    => "U5/R",   # however you want it reported
      forward_primer => 'GCGGATATAT',
      reverse_primer => 'TGCCCTACGG',
),                                                              "add_primerset()");
ok($bc->find_pcr_hits(),                                        "find_pcr_hits()");
exit;

ok($bc->find_pcr_products(),                                    "find_pcr_products()");
ok(print $bc->pcr_report1,                                      "pcr_report1()");


# Verify the results.
my $schema = $bc->schema;
is ($schema->resultset('BCSchema::LargeSeq')->search()->count(), 3, "large_seq row count");
is ($schema->resultset('BCSchema::SmallSeq')->search()->count(), 3, "small_seq row count");
my $rs = $schema->resultset('BCSchema::SubseqHitPositions')->search({}, {order_by => 'id'});;
$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
my $expect = [
   {id=>1, large_seq_id=>1,small_seq_id=>1,begin=>6, end=>15},
   {id=>2, large_seq_id=>1,small_seq_id=>2,begin=>69,end=>60},
   {id=>3, large_seq_id=>3,small_seq_id=>3,begin=>30,end=>39},
];
is_deeply([ $rs->all ],  $expect,                                 "hit_positions data");


1;



