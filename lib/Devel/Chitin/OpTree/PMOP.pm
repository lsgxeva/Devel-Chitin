package Devel::Chitin::OpTree::PMOP;
use base 'Devel::Chitin::OpTree::LISTOP';

use Devel::Chitin::Version;
use B qw(PMf_CONTINUE PMf_ONCE PMf_GLOBAL PMf_MULTILINE PMf_KEEP PMf_SINGLELINE
         PMf_EXTENDED PMf_FOLD OPf_KIDS);

use strict;
use warnings;

sub pp_qr {
    shift->_match_op('qr')
}

sub pp_match {
    my $self = shift;

    $self->_get_bound_variable_for_match
        . $self->_match_op('m');
}

sub pp_pushre {
    shift->_match_op('', @_);
}

sub _get_bound_variable_for_match {
    my $self = shift;

    my($var, $op) = ('', '');
    if ($self->op->flags & B::OPf_STACKED) {
        $var = $self->first->deparse;
        $op = $self->parent->op->name eq 'not'
                    ? ' !~ '
                    : ' =~ ';
    } elsif (my $targ = $self->op->targ) {
        $var = $self->_padname_sv($targ)->PV;
        $op = ' =~ ';

    }
    $var . $op;
}

sub pp_subst {
    my $self = shift;

    my @children = @{ $self->children };

    # children always come in this order, though they're not
    # always present: bound-variable, replacement, regex
    my $var = $self->_get_bound_variable_for_match;

    shift @children if $self->op->flags & B::OPf_STACKED; # bound var was the first child

    my $re;
    if ($children[1] and $children[1]->op->name eq 'regcomp') {
        $re = $children[1]->deparse(in_regex => 1,
                                    regex_x_flag => $self->op->pmflags & PMf_EXTENDED);
    } else {
        $re = $self->op->precomp;
    }

    my $replacement = $children[0]->deparse(skip_quotes => 1, skip_concat => 1);

    my $flags = _match_flags($self);
    "${var}s/${re}/${replacement}/${flags}";
}

sub _match_op {
    my($self, $operator, %params) = @_;

    my $re = $self->op->precomp;
    if (defined($re)
        and $self->op->name eq 'pushre'
        and $self->op->flags & B::OPf_SPECIAL
    ) {
        return q(' ') if $re eq '\s+';
        return q('') if $re eq '';
    }

    my $children = $self->children;
    foreach my $child ( @$children ) {
        if ($child->op->name eq 'regcomp') {
            $re = $child->deparse(in_regex => 1,
                                  regex_x_flag => $self->op->pmflags & PMf_EXTENDED);
            last;
        }
    }

    my $flags = _match_flags($self);

    my $delimiter = exists($params{delimiter}) ? $params{delimiter} : '/';

    join($delimiter, $operator, $re, $flags);
}

my @MATCH_FLAGS;
BEGIN {
    @MATCH_FLAGS = ( PMf_CONTINUE,      'c',
                     PMf_ONCE,          'o',
                     PMf_GLOBAL,        'g',
                     PMf_FOLD,          'i',
                     PMf_MULTILINE,     'm',
                     PMf_KEEP,          'o',
                     PMf_SINGLELINE,    's',
                     PMf_EXTENDED,      'x',
                   );
    if ($^V ge v5.10.0) {
        push @MATCH_FLAGS, B::RXf_PMf_KEEPCOPY(), 'p';
    }
    if ($^V ge v5.22.0) {
        push @MATCH_FLAGS, B::RXf_PMf_NOCAPTURE(), 'n';
    }
}

sub _match_flags {
    my $self = shift;

    my $match_flags = $self->op->pmflags;
    my $flags = '';
    for (my $i = 0; $i < @MATCH_FLAGS; $i += 2) {
        $flags .= $MATCH_FLAGS[$i+1] if ($match_flags & $MATCH_FLAGS[$i]);
    }
    $flags;
}

1;