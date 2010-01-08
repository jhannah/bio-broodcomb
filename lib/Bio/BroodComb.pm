package Bio::BroodComb;

use DBI;
use Bio::SeqIO;
use Moose;
has '_sql_schema' => (is => 'ro', isa => 'Str', default => sub { _my_sql_schema() });
has 'db_file'     => (is => 'rw', isa => 'Str', default => sub { 'BroodComb.sqlite' });
has 'dbh'         => (is => 'rw', isa => 'Object');
no Moose;


=head1 NAME

Bio::BroodComb - A collection of sequence analysis tools

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

A collection of sequence analysis tools.

    use Bio::BroodComb;
    my $bc = Bio::BroodComb->new();
    $bc->initialize_database;

=head1 METHODS

=head2 new

   my $bc = Bio::BroodComb->new();

=cut

# BUILD is Moose's after 'new'
sub BUILD {
   my ($self) = @_;
   my $db_file = $self->db_file;
   my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file","","", { RaiseError => 1, PrintError => 1 });
   $self->dbh($dbh);
}


=head2 initialize_database

Creates a new BroodComb database of empty tables. 

  $bc->initialize_database(
     db_file => "/tmp/bc.sqlite";   # Defaults to CWD "BroodComb.sqlite"
  );

=cut

sub initialize_database {
   my ($self, %args) = @_;
   if ($args{db_file}) {
      $self->db_file($args{db_file});
   }
   $DB::single = 1;
   # Hmmm... SQLite silently fails if we don't split the statements apart.
   my @sql = split /;/, $self->_sql_schema;
   foreach my $sql (@sql) {
      next unless ($sql && $sql =~ /\w/);   # don't run the blank one at the end.
      # print "$sql\n";
      $self->dbh->do($sql);
   }

   return 1;
}


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

sub load_small_seq {
   my ($self, %args) = @_;
   my $in = Bio::SeqIO->new(-file => $args{file});
   while (my $seq = $in->next_seq) {
      print $seq->seq . "\n";
   }
}


sub _my_sql_schema {
   return <<EOT;
drop table if exists large_seq;
create table large_seq (
  id integer primary key,
  accession text not null,
  length integer not null,
  classification text
);
create unique index ix1 ON large_seq (accession);

drop table if exists small_seq;
create table small_seq (
  id integer primary key,
  seq text not null,
  palindromic text,
  rebase_name text,
  methylation text
);
create unique index ix2 ON small_seq (seq);

drop table if exists hits;
create table hits (
  id integer primary key,
  large_seq_id integer not null,
  small_seq_id integer not null,
  raw_hit_count integer not null,
  normalized_hit_count1 integer
);
create unique index ix3 ON hits (large_seq_id, small_seq_id);

drop table if exists hit_positions;
create table hit_positions (
  id integer primary key,
  large_seq_id integer not null,
  small_seq_id integer not null,
  begin integer not null,
  end integer not null
);
create unique index ix4 ON hit_positions (large_seq_id, small_seq_id, begin, end);
EOT
}


=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-broodcomb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-BroodComb>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::BroodComb

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-BroodComb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-BroodComb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-BroodComb>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-BroodComb/>

=item * Version Control

L<http://github.com/jhannah/bio-broodcomb>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jay Hannah.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Bio::BroodComb
