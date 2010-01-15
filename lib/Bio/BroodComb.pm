package Bio::BroodComb;

use Moose;
with qw(
   Bio::BroodComb::Schema
   Bio::BroodComb::SubSeq
   Bio::BroodComb::PCR
);
no Moose;


=head1 NAME

Bio::BroodComb - A collection of sequence analysis tools

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

A collection of sequence analysis tools.

    use Bio::BroodComb;
    my $bc = Bio::BroodComb->new();
    $bc->create_database;

Things you can do (see the perldoc for the modules below):

   Bio::BroodComb::SubSeq - subsequence operations
   Bio::BroodComb::Schema - database operations

=head1 METHODS

=head2 new

   my $bc = Bio::BroodComb->new();

=cut

# BUILD is Moose's after 'new'
sub BUILD {
   my ($self) = @_;
   $self->_schema_startup;
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
