package Bio::BroodComb::SubSeq;

use Bio::SeqIO;
use Moose::Role;
no Moose::Role;

=head1 NAME

Bio::BroodComb::SubSeq - Subsequence tools for BroodComb

=cut

=head1 SYNOPSIS

This class contains the logic for BroodComb to perform subsequence operations.
You don't use this class directly, you use its features via a Bio::BroodComb
object.

   use Bio::BroodComb;
   my $bc = Bio::BroodComb->new();
   $bc->load_large_seq(file => "$Bin/data/large_seq.fasta");
   $bc->load_small_seq(file => "$Bin/data/small_seq.fasta");
   $bc->find_subseqs();
   print $bc->subseq_report1;

=head1 METHODS

=head2 load_large_seq

Tells BroodComb where your "large sequence" file is.

This data is memorized into the "large_seq" table. We assume your large sequences may
be truly massive, so the sequences themselves are not imported into the database, we
just build reference information.

  $bc->load_large_seq(file => "large_seq.fasta");

=cut

sub load_large_seq {
   my ($self, %args) = @_;
   my $in = Bio::SeqIO->new(-file => $args{file});
   while (my $seq = $in->next_seq) {
      print $seq->seq . "\n";
   }
}


=head2 load_small_seq 

Tells BroodComb where your "small sequence" file is.

This data is memorized into the "small_seq" table.
The sequence itself and reference information we need are loaded.

  $bc->load_small_seq(file => "small_seq.fasta");

=cut

sub load_small_seq {
   my ($self, %args) = @_;
   my $in = Bio::SeqIO->new(-file => $args{file});
   while (my $seq = $in->next_seq) {
      print $seq->seq . "\n";
   }
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 SUPPORT

See perldoc Bio::BroodComb.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jay Hannah.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Bio::BroodComb::SubSeq;
