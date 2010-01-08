my @alphabet = qw( A C G T );
for (1..4) {
   for (1..80) {
      print @alphabet[ int rand 4 ];
   }
   print "\n";
}


