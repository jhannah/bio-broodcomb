use Test::More tests => 2;

use Bio::BroodComb;

ok(my $bc = Bio::BroodComb->new(),       "new()");
ok($bc->initialize_database,             "initialize_database()");

