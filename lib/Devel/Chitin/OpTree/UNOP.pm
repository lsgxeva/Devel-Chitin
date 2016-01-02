package Devel::Chitin::OpTree::UNOP;
use base 'Devel::Chitin::OpTree';

use Devel::Chitin::Version;

use strict;
use warnings;

sub first {
    shift->{children}->[0];
}

sub pp_leavesub {
    my $self = shift;
    $self->first->deparse;
}


# Normally, pp_list is a LISTOP, but this happens when a pp_list is turned
# into a pp_null by the optimizer, and it has one child
sub pp_list {
    my $self = shift;
    $self->first->deparse;
}

sub pp_srefgen {
    my $self = shift;
    '\\' . $self->first->deparse;
}

sub pp_rv2sv {
    my $self = shift;
    '$' . $self->first->deparse;
}

sub pp_rv2av {
    my $self = shift;
    '@' . $self->first->deparse;
}

sub pp_rv2hv {
    my $self = shift;
    '%' . $self->first->deparse;
}

sub pp_rv2cv {
    my $self = shift;
    $self->first->deparse;
}

sub pp_entersub {
    my $self = shift;

    my @params_ops;
    if ($self->first->op->flags & B::OPf_KIDS) {
        # normal sub call
        # first is a pp_list containing a pushmark, followed by the arg
        # list, followed by the sub name
        (undef, @params_ops) = @{ $self->first->children };

    } elsif ($self->first->op->name eq 'pushmark'
            or
            $self->first->op->name eq 'padrange'
    ) {
        # method call
        # the args are children of $self: a pushmark/padrange, invocant, then args, then method_named() with the method name
        (undef, undef, @params_ops) = @{ $self->children };

    } else {
        die "unknown entersub first op " . $self->first->op->name;
    }
    my $sub_name_op = pop @params_ops;

    return _deparse_sub_invocation($sub_name_op)
            . '( '
                . join(', ', map { $_->deparse } @params_ops)
            . ' )';
}

sub _deparse_sub_invocation {
    my $op = shift;

    my $op_name = $op->op->name;
    if ($op_name eq 'rv2cv'
        or
        ( $op->is_null and $op->_ex_name eq 'pp_rv2cv' )
    ) {
        # subroutine call

        if ($op->first->op->name eq 'gv') {
            # normal sub call: Some::Sub::named(...)
            $op->deparse;
        } else {
            # subref call
            $op->deparse . '->';
        }

    } elsif ($op_name eq 'method_named' or $op_name eq 'method') {
        join('->',  $op->parent->children->[1]->deparse(skip_quotes => 1),  # class
                    $op->deparse(skip_quotes => 1));

    } else {
        die "unknown sub invocation for $op_name";
    }
}

sub pp_method {
    my $self = shift;
    $self->first->deparse;
}

sub pp_av2arylen {
    my $self = shift;

    substr(my $list_name = $self->first->deparse, 0, 1, ''); # remove sigil
    '$#' . $list_name;
}

#                   OP name        Perl fcn    targmy?
foreach my $a ( [ pp_entereval  => 'eval',      0 ],
                [ pp_schomp     => 'chomp',     1 ],
                [ pp_schop      => 'chop',      1 ],
                [ pp_chr        => 'chr',       1 ],
                [ pp_hex        => 'hex',       1 ],
                [ pp_lc         => 'lc',        0 ],
                [ pp_lcfirst    => 'lcfirst',   0 ],
                [ pp_uc         => 'uc',        0 ],
                [ pp_ucfirst    => 'ucfirst',   0 ],
                [ pp_length     => 'length',    1 ],
                [ pp_oct        => 'oct',       1 ],
                [ pp_ord        => 'ord',       1 ],
                [ pp_scalar     => 'scalar',    0 ],
                [ pp_abs        => 'abs',       1 ],
                [ pp_cos        => 'cos',       1 ],
                [ pp_sin        => 'sin',       1 ],
                [ pp_exp        => 'exp',       1 ],
                [ pp_int        => 'int',       1 ],
                [ pp_log        => 'log',       1 ],
                [ pp_rand       => 'rand',      1 ],
                [ pp_sqrt       => 'sqrt',      1 ],
                [ pp_srand      => 'srand',     1 ],
                [ pp_pop        => 'pop',       0 ],
                [ pp_shift      => 'shift',     0 ],
) {
    my($pp_name, $perl_name, $targmy) = @$a;
    my $sub = sub {
        my $self = shift;
        my $arg = $self->first->deparse;

        my $target = $targmy ? $self->_maybe_targmy : '';
        $target . join(' ', $perl_name,
                            $arg eq '$_' ? () : $arg);
    };
    no strict 'refs';
    *$pp_name = $sub;
}

1;
