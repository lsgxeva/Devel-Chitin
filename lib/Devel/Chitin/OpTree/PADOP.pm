package Devel::Chitin::OpTree::PADOP;
use base 'Devel::Chitin::OpTree';

use Devel::Chitin::Version;

use strict;
use warnings;

sub pp_gv {
    my $self = shift;
    my $gv = $self->_padval_sv($self->op->padix);
    $self->_gv_name( $gv );
}
*pp_gvsv = \&pp_gv;

1;