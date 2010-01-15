package Bio::BroodComb::Schema;

use DBI;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Moose::Role;
has '_sql_schema' => (is => 'ro', isa => 'Str', default => sub { _my_sql_schema() });
has 'db_file'     => (is => 'rw', isa => 'Str', default => sub { 'BroodComb.sqlite' });
has 'data_source' => (is => 'rw', isa => 'Str');
has 'dbh'         => (is => 'rw', isa => 'Object');
has 'schema'      => (is => 'rw', isa => 'Object');   # DBIx::Class::Schema object
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

=cut


sub _schema_startup {
   my ($self) = @_;

   my $db_file = $self->db_file;
   my $db_existed_already = -r $db_file;
   $self->data_source("dbi:SQLite:dbname=$db_file");
   my $dbh = DBI->connect($self->data_source,"","", { RaiseError => 1, PrintError => 1 });
   $self->dbh($dbh);
   unless ($db_existed_already) {
      $self->create_tables;
   }
   $self->schema($self->_create_dbic_schema);
}


=head2 create_tables

Creates a new BroodComb database of empty tables. 

  $bc->create_tables(
     db_file => "/tmp/bc.sqlite";   # Defaults to CWD "BroodComb.sqlite"
  );

=cut

sub create_tables {
   my ($self, %args) = @_;
   if ($args{db_file}) {
      $self->db_file($args{db_file});
   }
   # Hmmm... SQLite silently fails if we don't split the statements apart.
   my @sql = split /;/, $self->_sql_schema;
   foreach my $sql (@sql) {
      next unless ($sql && $sql =~ /\w/);   # don't run the blank one at the end.
      # print "$sql\n";
      $self->dbh->do($sql);
   }

   return 1;
}


=head2 _create_dbic_schema

Create a DBIx::Class::Schema object (in memory only) so we can interact with our database
via DBIx::Class. This autodetects all our table, columns, etc. on the fly.

=cut

sub _create_dbic_schema {
   my ($self) = @_;
   make_schema_at(
      'BCSchema',
      {
         debug  => 0,
         naming => 'v4',    # Move to v5 whenever new DBIx::Class 0.09
                            # and DBIx::Class::Schema::Loader ship (Mar 2010?)
      },
      [ $self->data_source, '', '' ],
   );
   return 'BCSchema'->clone;    # I don't understand this, but this is what DBIx::Class::Schema::Loader
                                 # tests do to get a functional schema....
}


sub _my_sql_schema {

   # These are the Bio::BroodComb::SubSeq tables
   my $rval = <<EOT;
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

drop table if exists subseq_hits;
create table subseq_hits (
   id integer primary key,
   large_seq_id integer not null,
   small_seq_id integer not null,
   raw_hit_count integer not null,
   normalized_hit_count1 integer
);
create unique index ix3 ON subseq_hits (large_seq_id, small_seq_id);

drop table if exists subseq_hit_positions;
create table subseq_hit_positions (
   id integer primary key,
   large_seq_id integer not null,
   small_seq_id integer not null,
   begin integer not null,
   end integer not null
);
create unique index ix4 ON subseq_hit_positions (large_seq_id, small_seq_id, begin, end);
EOT

   # These are the Bio::BroodComb::PCR tables
   $rval .= <<EOT;
drop table if exists primer_sets;
create table primer_sets (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   forward_primer text,
   reverse_primer text,
   description text
);

drop table if exists pcr_hits;
create table pcr_hits (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   primer_set_id int,
   primer_set_direction text,
   database_filename text,
   database_acc text,
   begin int,
   end int
);

drop table if exists products;
create table products (
   id INTEGER PRIMARY KEY AUTOINCREMENT,
   primer_set_id int,
   database_filename char(12),
   database_acc char(8),
   forward_primer_begin int,
   forward_primer_end int,
   product_begin int,
   product_end int,
   reverse_primer_begin int,
   reverse_primer_end int
);
EOT
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

1; # End of Bio::BroodComb::Schema;
