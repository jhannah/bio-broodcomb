use Test::More tests => 11;

use DBIx::Class::ResultClass::HashRefInflator;
use Bio::BroodComb;
use FindBin qw($Bin);

ok(my $bc = Bio::BroodComb->new(),                              "new()");
my $schema = $bc->schema;
ok($bc->create_tables,                                          "create_tables()");

ok($bc->load_large_seq(file => "$Bin/data/large_seq.fasta"),    "load_large_seq()");
is($schema->resultset('BCSchema::LargeSeq')->search()->count(), 3, "large_seq row count");

ok($bc->add_primerset(
   description    => "U5/R",   # however you want it reported
   forward_primer => 'GCGGATATAT',
   reverse_primer => 'TGCCCTACGG',
),                                                              "add_primerset()");
is ($schema->resultset('BCSchema::PrimerSets')->search()->count(), 1, "primer_sets row count");

# ------------------
ok($bc->find_pcr_hits(),                                        "find_pcr_hits()");
my $rs = $schema->resultset('BCSchema::PcrHits')->search(
   {}, 
   {
      columns  => [ qw/ id primer_set_id primer_set_direction database_acc begin end / ],
      order_by => 'id'
   }
);
$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
$DB::single = 1;
my $expect = [
   {id=>1,primer_set_id=>1,primer_set_direction=>'forward',database_acc=>'one',begin=>6, end=>15},
   {id=>2,primer_set_id=>1,primer_set_direction=>'reverse',database_acc=>'one',begin=>69,end=>60},
];
is_deeply([ $rs->all ],  $expect,                               "pcr_hits data");

# ------------------
ok($bc->find_pcr_products(),                                    "find_pcr_products()");
my $rs = $schema->resultset('BCSchema::Products')->search(
   {}, 
   { 
      columns => [ qw/
         id
         primer_set_id
         database_acc
         forward_primer_begin
         forward_primer_end
         product_begin
         product_end
         reverse_primer_begin
         reverse_primer_end
      / ],
      order_by => 'id',
   }
);
$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
my $expect = [ {
   id                   => 1,
   primer_set_id        => 1,
   database_acc         => 'one',
   forward_primer_begin => 6,
   forward_primer_end   => 15,
   product_begin        => 16,
   product_end          => 59,
   reverse_primer_begin => 69,
   reverse_primer_end   => 60,
} ];
is_deeply([ $rs->all ],  $expect,                               "pcr_hits data");

# ------------------------
ok($bc->pcr_report1,                                            "pcr_report1()");



1;



