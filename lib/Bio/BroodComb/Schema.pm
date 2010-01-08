package Bio::BroodComb::Schema;

use DBI;
use Moose::Role;
has '_sql_schema' => (is => 'ro', isa => 'Str', default => sub { _my_sql_schema() });
has 'db_file'     => (is => 'rw', isa => 'Str', default => sub { 'BroodComb.sqlite' });
has 'dbh'         => (is => 'rw', isa => 'Object');
no Moose::Role;

=head1 NAME

Bio::BroodComb::Schema - RDBMS Schema information for BroodComb

=cut

=head1 SYNOPSIS

This class contains the logic for BroodComb database schema operations.
You don't use this class directly, you use its features via a Bio::BroodComb
object.

   use Bio::BroodComb;
   my $bc = Bio::BroodComb->new();
   ...

=head1 METHODS

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

=head1 SUPPORT

See perldoc Bio::BroodComb.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jay Hannah.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Bio::BroodComb::Schema;
