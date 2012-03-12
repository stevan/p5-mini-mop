package mop::syntax;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

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

sub class {}

sub method { $::CLASS->add_method( @_ ) }

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    $::CLASS->add_attribute( $name, $default );
}

sub BUILD    { $::CLASS->set_constructor( @_ ) }
sub DEMOLISH { $::CLASS->set_destructor( @_ )  }

sub build_class {
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };
    my $class = mop::class->new( $caller eq 'main' ? $name : "${caller}::${name}", \%metadata );
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

sub super {
    die "Cannot call super() outside of a method" unless defined $::SELF;
    my $invocant    = $::SELF;
    my $method_name = (split '::' => ((caller(2))[3]))[-1];
    my $dispatcher  = $::CLASS->get_dispatcher;
    # find the method currently being called
    my $method = mop::WALKMETH( $dispatcher, $method_name );
    while ( $method && $method ne $::CALLER ) {
        $method = mop::WALKMETH( $dispatcher, $method_name );
    }
    # and advance past it by one
    $method = mop::WALKMETH( $dispatcher, $method_name )
              || die "No super method ($method_name) found";
    $invocant->$method( @_ );
}


1;

__END__
