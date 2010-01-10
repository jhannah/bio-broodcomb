package Bio::BroodComb::SubSeq;

use Bio::SeqIO;
use Moose::Role;
has 'large_seq_file' => (is => 'rw', isa => 'Str');
has 'small_seq_file' => (is => 'rw', isa => 'Str');
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
   $self->large_seq_file($args{file});
   my $rs = $self->schema->resultset('BCSchema::LargeSeq');
   my $in = Bio::SeqIO->new(-file => $args{file});
   while (my $seq = $in->next_seq) {
      $rs->create({
         accession => $seq->id,
         length    => length($seq->seq),
      });
   }
   return 1;
}


=head2 load_small_seq 

Tells BroodComb where your "small sequence" file is.

This data is memorized into the "small_seq" table.
The sequence itself and reference information we need are loaded.

  $bc->load_small_seq(file => "small_seq.fasta");

=cut

sub load_small_seq {
   my ($self, %args) = @_;
   $self->small_seq_file($args{file});
   my $rs = $self->schema->resultset('BCSchema::SmallSeq');
   my $in = Bio::SeqIO->new(-file => $args{file});
   while (my $seq = $in->next_seq) {
      # print $seq->seq . "\n";
      $rs->create({
         seq         => $seq->seq,
         #palindromic => undef,
         #rebase_name => undef,
         #methylation => undef,
      });
   }
   return 1;
}


=head2 find_subseqs 

Search for each small_seq in large_seq. Record each hit in the hit_positions table.

=cut

sub find_subseqs {
   my ($self) = @_;
   my $in_large = Bio::SeqIO->new(-file=>$self->large_seq_file);
   my $rs_large =      $self->schema->resultset('BCSchema::LargeSeq');
   my $hit_positions = $self->schema->resultset('BCSchema::HitPositions');
   while (my $large_seq = $in_large->next_seq) {
      my $large_seq_db = $rs_large->search({accession => $large_seq->id})->first();
      #print $large_seq->id . "\n";
      #print $large_seq_db->accession . "\n";
      my $large_seq_str = $large_seq->seq;
      my $rs_small = $self->schema->resultset('BCSchema::SmallSeq')->search();
      while (my $small_seq_db = $rs_small->next) {
         #print "   " . $small_seq_db->seq . "\n";
         my $small_seq_str = $small_seq_db->seq;

         # Forward search.
         while ($large_seq_str =~ /$small_seq_str/g) {
            my $begin = pos($large_seq_str) - length($small_seq_str) + 1;
            my $end =   pos($large_seq_str);
            #$found_count++;
            #print "   Found $small_seq_str at [$begin..$end]\n";
            $hit_positions->create({
               large_seq_id => $large_seq_db->id, 
               small_seq_id => $small_seq_db->id,
               begin        => $begin,
               end          => $end,
            });
         }

         # Reverse search. Assume alphabet is DNA for now.
         my $reverse = $small_seq_str;
         $reverse =~ tr/ACGT/TGCA/;
         $reverse = join "", reverse (split //, $reverse);
         while ($large_seq_str =~ /$reverse/g) {
            my $begin = pos($large_seq_str) - length($small_seq_str) + 1;
            my $end =   pos($large_seq_str);
            ($begin, $end) = ($end, $begin);
            #$found_count++;
            #print "   Found $small_seq_str at [$begin..$end]\n";
            $hit_positions->create({
               large_seq_id => $large_seq_db->id, 
               small_seq_id => $small_seq_db->id,
               begin        => $begin,
               end          => $end,
            });
         }

      }
      
   }

   return 1;
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
