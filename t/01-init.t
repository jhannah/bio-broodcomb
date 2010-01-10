use Test::More tests => 2;

use Bio::BroodComb;

ok(my $bc = Bio::BroodComb->new(),       "new()");
ok($bc->create_database,                 "create_database()");

