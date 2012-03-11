package mop;

use 5.014;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    $::SELF   = undef;
    $::CLASS  = undef;
    $::CALLER = undef;
}

use mop::class;
use mop::syntax;

use Devel::CallParser;

BEGIN { XSLoader::load(__PACKAGE__, our $VERSION) }

sub import {
    shift;
    my %options = @_;
    mop::syntax->setup_for( $options{'-into'} // caller )
}

sub WALKCLASS {
    my ($dispatcher, $solver) = @_;
    { $solver->( $dispatcher->() || return ); redo }
}

sub WALKMETH {
    my ($dispatcher, $method_name) = @_;
    { ( $dispatcher->() || return )->get_local_methods->{ $method_name } || redo }
}

1;

__END__