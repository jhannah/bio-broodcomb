package Bio::BroodComb::PCR;

use Bio::Tools::SeqPattern;
use Bio::SeqIO;
use Moose::Role;
## Moose::Meta::Attribute::Native::Trait::Array 
#has 'PrimerSets' => (is => 'rw', isa => 'ArrayRef', traits => ['Array'], default => sub {[]},
#   handles => {
#      all_primersets   => 'elements',
#      count_primersets => 'count',
#      add_primerset    => 'push',
#   }
#);
#has 'small_seq_format' => (is => 'rw', isa => 'Str');
no Moose::Role;

my $debug = 1;

=head1 NAME

Bio::BroodComb::PCR - In-silico PCR tools for BroodComb

=cut

=head1 SYNOPSIS

This class contains the logic for BroodComb to perform in-silico PCR operations.
You don't use this class directly, you use its features via a Bio::BroodComb
object.

  use Bio::BroodComb;
  my $bc = Bio::BroodComb->new();
  $bc->load_large_seq(file => "large_seq.fasta");
  $bc->add_primerset(
     description    => "U5/R",   # however you want it reported
     forward_primer => 'GCGGGCAGCAATACTGCTTTGTAA',
     reverse_primer => 'ACCAGCGTTCAGCATATGGAGGAT',
  );
  $bc->find_pcr_hits();
  $bc->find_pcr_products();
  print $bc->pcr_report1;

=head1 METHODS

=head2 add_primerset

Adds a primer set to BroodComb (the primer_sets table).

  $bc->add_primerset(
     description    => "U5/R",   # however you want it reported
     forward_primer => 'GCGGGCAGCAATACTGCTTTGTAA',
     reverse_primer => 'ACCAGCGTTCAGCATATGGAGGAT',
  );

=cut

sub add_primerset {
   my ($self, %args) = @_;

   my $rs = $self->schema->resultset('BCSchema::PrimerSets');
   $rs->create({
      # id             =>    # let SQLite set this
      forward_primer => $args{forward_primer},
      reverse_primer => $args{reverse_primer},
      description    => $args{description},
   });
   print "primerset added\n";
}


=head2 find_pcr_hits

Search each large_seq for either side of all our primer sets.
Results are populated into 'pcr_hits'.

=cut

sub find_pcr_hits {
   my ($self) = @_;

   my $in = Bio::SeqIO->new(
      -file   => $self->large_seq_file,
      -format => $self->large_seq_format,
   );
   my $builder = $in->sequence_builder();
   $builder->want_none();
   $builder->add_wanted_slot('accession_number','desc','seq');
   my $rs_large = $self->schema->resultset('BCSchema::LargeSeq');
   my $rs_ps    = $self->schema->resultset('BCSchema::PrimerSets');
   my $rs_hits  = $self->schema->resultset('BCSchema::PcrHits');
   while (my $seq = $in->next_seq) {
      my $acc = $seq->accession_number;
      if ($acc eq 'unknown') {
         $acc = $seq->id;
      }
      my $seq = uc($seq->seq);
      $debug && print "Searching $acc\n";

      my $all_ps = $rs_ps->search();
      while (my $ps = $all_ps->next) {
         $debug && print "Looking for " . $ps->description . "\n";
         
         # my $forward = Bio::Seq->new( -seq => $ps->forward_primer );
         # my $reverse = Bio::Seq->new( -seq => $ps->reverse_primer );
         # Use SeqPattern instead so we can magically handle ambiguity codes...
         my $forward = new Bio::Tools::SeqPattern(-seq =>$ps->forward_primer, -type =>'Dna');
         my $reverse = new Bio::Tools::SeqPattern(-seq =>$ps->reverse_primer, -type =>'Dna');

         my $i = 0;  # A little iterator to keep track of which of our four
                     # scenarios we're in.
  
         foreach my $search ( 
            $forward->expand,               # $i = 1
            $forward->revcom(1)->expand,    # $i = 2
            $reverse->expand,               # $i = 3
            $reverse->revcom(1)->expand,    # $i = 4
         ) {
            $search = uc($search);
            if (++$i == 5) { $i = 1; }

            $debug && print "   Specifically: $search\n";

            while ($seq =~ /$search/g) {
               my $end   = pos($seq);
               my $start = $end - length($&) + 1;

               my $hit = $rs_hits->new({
                  primer_set_id       => $ps->id,
                  database_filename   => $self->large_seq_file,
                  #database_acc        => $acc,
               });
               if ($i == 1 or $i == 2) {
                  $hit->primer_set_direction("forward");
               } else { 
                  $hit->primer_set_direction("reverse");
               }
               if ($i == 2 or $i == 4) {
                  ($start, $end) = ($end, $start);
               }
               $hit->begin($start);
               $hit->end($end);

               # die "there's a reverse sequence" if ($start > $end);

               $hit->insert;
               $debug && print "Found '$&' while searching for " . $hit->id . "\n";
            }
         }
      }
   }
   return 1;
}


=head2 find_pcr_products

Given all the 'hits' that find_hits() found, populate the 'products' table.

=cut

sub find_pcr_products {
   my ($self) = @_;

   # Delete everything (start over):
   $self->schema->resultset('Products')->search({})->delete;

   # Grab all the forward hits...
   my $rs1 = $self->schema->resultset('Hits')->search(
      {
         primer_set_direction => 'forward',
      },
      {
         columns  => [ qw/ primer_set_id database_acc start end / ],
         distinct => 1,
      }
   );
   while (my $fh = $rs1->next) {   # fh = forward_hit
      my $rs2 = $self->schema->resultset('Hits')->search({
         primer_set_direction => 'reverse',
         primer_set_id        => $fh->primer_set_id,
         database_acc         => $fh->database_acc,
      });
      while (my $rh = $rs2->next) {   # rh = reverse_hit
         printf(
            "%4s %10s %14s %14s\n", 
            $fh->primer_set_id, 
            $fh->database_acc, 
            arrow($fh->start, $fh->end),
            arrow($rh->start, $rh->end),
         );

         my $product_start;
         my $product_end;
         if ($fh->start < $fh->end) {
            if ($rh->start <= $fh->end || $rh->end <= $fh->end) {
               print "   reverse is behind the forward\n";
               next;
            }
            if ($rh->start < $rh->end) {
               print "   reverse is in the wrong orientation\n";
               next;
            }
            $product_start = $fh->end + 1;
            $product_end =   $rh->end - 1;
         } else {
            if ($rh->end >= $fh->end || $rh->start >= $fh->end) {
               print "   reverse is behind the forward\n";
               next;
            }
            if ($rh->start > $rh->end) {
               print "   reverse is in the wrong orientation\n";
               next;
            }
            $product_start = $fh->end - 1;
            $product_end =   $rh->end + 1;
         }


         $self->schema->resultset('Products')->create({
            primer_set_id        => $fh->primer_set_id,
            database_filename    => $fh->database_filename,
            database_acc         => $fh->database_acc,
            forward_primer_start => $fh->start,
            forward_primer_end   => $fh->end,
            product_start        => $product_start,
            product_end          => $product_end,
            reverse_primer_start => $rh->start,
            reverse_primer_end   => $rh->end,
         });
      }
   }
}


sub arrow {
   my ($n1, $n2) = @_;
   if ($n1 < $n2) {
      return sprintf "%4s -> %-4s", $n1, $n2;
   } 
   return sprintf "%4s <- %-4s", $n1, $n2;
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

1; # End of Bio::BroodComb::PCR;
