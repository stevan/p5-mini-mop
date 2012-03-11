package mop::syntax;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Sub::Name ();

sub setup_for {
    my $class = shift;
    my $pkg   = shift;
    {
        no strict 'refs';
        *{ $pkg . '::class'    } = \&class;
        *{ $pkg . '::method'   } = \&method;
        *{ $pkg . '::has'      } = \&has;
        *{ $pkg . '::BUILD'    } = \&BUILD;
        *{ $pkg . '::DEMOLISH' } = \&DEMOLISH;
        *{ $pkg . '::super'    } = \&super;
    }
}

sub class { }

sub method { $::CLASS->add_method( @_ ) }

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    $::CLASS->add_attribute( $name, $default );
}

sub build_class {
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };
    my $class = mop::class->new($caller eq 'main' ? $name : "${caller}::${name}");
    $class->set_superclass( $metadata{ 'extends' } ) if exists $metadata{ 'extends' };
    $class;
}

sub finalize_class {
    my ($name, $class, $caller) = @_;
    $class->finalize;
    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $class } );
    }
}

sub BUILD {
    my ($body) = @_;
}

sub DEMOLISH {
    my ($body) = @_;
}

sub super {
    die "Cannot call super() outside of a method" unless defined $::SELF;
    my $invocant    = $::SELF;
    my $method_name = (split '::' => ((caller(1))[3]))[-1];
    my $dispatcher  = $::CLASS->get_dispatcher;
    # find the method currently being called
    my $method = mop::WALKMETH( $dispatcher, $method_name );
    while ( $method != $::CALLER ) {
        $method = mop::WALKMETH( $dispatcher, $method_name );
    }
    # and advance past it  by one
    $method = mop::WALKMETH( $dispatcher, $method_name )
              || die "No super method ($method_name) found";
    $method->execute( $invocant, @_ );
}


1;

__END__

=pod

=head1 NAME

mop::syntax - The syntax module for the p5-mop

=head1 SYNOPSIS

  use mop::syntax;

=head1 DESCRIPTION

This module uses Devel::CallParser to provide the desired
syntax for the p5-mop.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
