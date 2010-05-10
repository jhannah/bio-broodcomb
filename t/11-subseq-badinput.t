use Test::More tests => 4;
use Test::Exception;

use Bio::BroodComb;
use FindBin qw($Bin);

my $bc = Bio::BroodComb->new();

throws_ok { $bc->load_large_seq(file => "$Bin/data/nonexistant.fasta") }
   qr/No such file or directory/,            "load_large_seq() - nonexistant";

throws_ok { $bc->load_large_seq(file => "$Bin/data/bogus.fasta") }
   qr/does not appear to be FASTA format/,   "load_large_seq() - bogus";

throws_ok { $bc->load_small_seq(file => "$Bin/data/nonexistant.fasta") }
   qr/No such file or directory/,            "load_small_seq() - nonexistant";

throws_ok { $bc->load_small_seq(file => "$Bin/data/bogus.fasta") }
   qr/does not appear to be FASTA format/,   "load_small_seq() - bogus";

