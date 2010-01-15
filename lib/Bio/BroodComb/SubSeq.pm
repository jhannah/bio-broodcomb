package Bio::BroodComb::SubSeq;

use Bio::SeqIO;
use Moose::Role;
has 'large_seq_file'   => (is => 'rw', isa => 'Str');
has 'large_seq_format' => (is => 'rw', isa => 'Str');
has 'small_seq_file'   => (is => 'rw', isa => 'Str');
has 'small_seq_format' => (is => 'rw', isa => 'Str');
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
   $bc->load_large_seq(file => "large_seq.fasta");
   $bc->load_small_seq(file => "small_seq.fasta");
   $bc->find_subseqs();
   print $bc->subseq_report1;

=head1 METHODS

=head2 load_large_seq

Tells BroodComb where your "large sequence" file is.

This data is memorized into the "large_seq" table. We assume your large sequences may
be truly massive, so the sequences themselves are not imported into the database, we
just build reference information.

  $bc->load_large_seq(
     file   => "large_seq.fasta", 
     format => "fasta"            # optional
  );

=cut

sub load_large_seq {
   my ($self, %args) = @_;

   $self->large_seq_file(  $args{file});
   $self->large_seq_format($args{format}) if $args{format};

   my $rs = $self->schema->resultset('BCSchema::LargeSeq');
   my $in = Bio::SeqIO->new(-file => $args{file}, -format => $args{format});
   my %known_ids;
   while (my $seq = $in->next_seq) {
      #print $seq->id . "\n";
      if ($known_ids{$seq->id}) {
         warn "Skipping duplicate entry for sequence ID " . $seq->id;
         next;
      }
      $rs->create({
         accession => $seq->id,
         length    => length($seq->seq),
      });
      $known_ids{$seq->id} = 1;
   }
   return 1;
}


=head2 load_small_seq 

Tells BroodComb where your "small sequence" file is.

This data is memorized into the "small_seq" table.
The sequence itself and reference information we need are loaded.

  $bc->load_small_seq(
     file   => "small_seq.fasta", 
     format => "fasta",            # optional
  );

=cut

sub load_small_seq {
   my ($self, %args) = @_;

   $self->small_seq_file(  $args{file});
   $self->small_seq_format($args{format}) if $args{format};

   my $rs = $self->schema->resultset('BCSchema::SmallSeq');
   my $in = Bio::SeqIO->new(-file => $args{file}, -format => $args{format});
   my %known_seqs;
   while (my $seq = $in->next_seq) {
      print $seq->seq . "\n";
      if ($known_seqs{$seq->seq}) {
         warn "Skipping duplicate sequence " . $seq->seq;
         next;
      }
      $rs->create({
         seq         => $seq->seq,
         #palindromic => undef,
         #rebase_name => undef,
         #methylation => undef,
      });
      $known_seqs{$seq->seq} = 1;
   }
   return 1;
}


=head2 find_subseqs 

Search for each small_seq in large_seq. Record each hit in the hit_positions table.

=cut

sub find_subseqs {
   my ($self) = @_;

   my $in_large = Bio::SeqIO->new(
      -file   => $self->large_seq_file, 
      -format => $self->large_seq_format,
   );
   my $rs_large =      $self->schema->resultset('BCSchema::LargeSeq');
   my $hit_positions = $self->schema->resultset('BCSchema::SubseqHitPositions');

   my %done_accessions;
   while (my $large_seq = $in_large->next_seq) {
      next if ($done_accessions{$large_seq->id});
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
            printf("%s %s %s %s\n", $large_seq_db->id, $small_seq_db->id, $begin, $end);

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
      # Memorize a hash of large sequence accessions we've already processed so if there
      # are dupes that we skipped in load, we skip them here too.
      $done_accessions{$large_seq->id} = 1;
   }

   return 1;
}


=head2 subseq_report_hit_position1

Returns a text report listing all hit_positions, ordered and grouped by accession.

=cut

sub subseq_report_hit_position1 {
   my ($self) = @_;

   my $rval;
   my $strsql = <<EOT;
select l.accession, s.seq, hp.begin, hp.end
from subseq_hit_positions hp, large_seq l, small_seq s
where hp.large_seq_id = l.id
and hp.small_seq_id = s.id
order by l.accession
EOT
   my $sth = $self->dbh->prepare($strsql);
   $sth->execute;
   my $last_acc = "";
   while (my @row = $sth->fetchrow) {
      if ($row[0] ne $last_acc) {
         $rval .= "$row[0]\n";
         $last_acc = $row[0];
      }
      $rval .= "   $row[1] found at $row[2]..$row[3]\n";
   }
   return $rval;
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
