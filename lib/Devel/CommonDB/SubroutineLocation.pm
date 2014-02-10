package Devel::CommonDB::SubroutineLocation;

use strict;
use warnings;

use Carp;

my @properties = qw(package subroutine line filename end code);
foreach my $prop ( @properties ) {
    my $sub = sub { shift->{$prop} };
    no strict 'refs';
    *$prop = $sub;
}

sub new {
    my($class, %props) = @_;

    foreach my $prop ( @properties ) {
        Carp::croak("$prop is a required property") unless (defined $props{$prop});
    }

    return bless \%props, $class;
}

1;

__END__

=pod

=head1 NAME

Devel::CommonDB::SubroutineLocation - A class to represent the location of a subroutine

=head1 SYNOPSIS

  my $sub_name = 'The::Package::subname';
  my $loc = $debugger->subroutine_location($subname);
  printf("subroutine %s is in package %s in file %s from line %d to %d\n",
        $loc->subroutine,
        $loc->package,
        $loc->filename,
        $loc->line,
        $loc->end);

=head1 DESCRIPTION

This class is used to represent a subroutine with location in the debugged
program.

=head1 METHODS

  Devel::CommonDB::SubroutineLocation->new(%params)

Construct a new instance.  The following parameters are accepted; all are
required.

=over 4

=item package

The package the subroutine was declared in.

=item filename

The file in which the subroutine appears.

=item subroutine

The name of the subroutine.

=item line

The line the subroutine starts.

=item end

The line the subroutine ends.

=item code

A callable coderef for the subroutine.

=back

Each construction parameter also has a read-only method to retrieve the value.

=head1 SEE ALSO

L<Devel::CommonDB::Location>, L<Devel::CommonDB>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
