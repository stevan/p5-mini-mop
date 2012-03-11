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
}


1;

__END__
