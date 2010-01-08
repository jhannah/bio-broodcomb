package # hide from PAUSE
   bctest_common;

use DBIx::Class::Schema::Loader qw/ make_schema_at /; 

=head2 init

Create a DBIx::Class::Schema object (in memory only) so we can interact with our database
via DBIx::Class. This autodetects all our table, columns, etc. on the fly.

=cut

sub init {
   my ($data_source) = @_;
   make_schema_at( 
      'BCTest', 
      { 
         debug  => 0, 
         naming => 'v4',    # Move to v5 whenever new DBIx::Class 0.09 
                            # and DBIx::Class::Schema::Loader ship (Mar 2010?)
      }, 
      [ $data_source, '', '' ], 
   ); 
   return 'BCTest'->clone;    # I don't understand this, but this is what DBIx::Class::Schema::Loader
                              # tests do to get a functional schema....
}

1;

