package mop::class;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Hash::Util::FieldHash qw[ fieldhashes ];
use Sub::Name             qw[ subname ];

use parent 'Package::Anon';

fieldhashes \ my (%superclass, %attributes, %local_methods);

sub new {
    if ( ref $_[0] ) {
        my $class = shift;
        my %args  = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
        my $instance = {};
        if ( my $attrs = $attributes{ $class } ) {
            foreach my $attr ( keys %$attrs ) {
                my ($plain_attr) = ($attr =~ /^\$(.*)/);
                $instance->{ $attr } = \(exists $args{ $plain_attr } ? $args{ $plain_attr } : $attrs->{ $attr }->());
            }
        }
        $class->bless( $instance );
    }
    else {
        (shift)->SUPER::new( @_ );
    }
}

sub get_superclass    { $superclass{ $_[0] } }
sub get_attributes    { $attributes{ $_[0] } }
sub get_local_methods { $local_methods{ $_[0] } }

sub set_superclass {
    my ($class, $super) = @_;
    $superclass{ $class } = $super;
}

sub get_mro {
    my $class = shift;
    my $super = $class->get_superclass;
    return [ $class, $super ? @{ $super->get_mro } : () ];
}

sub get_dispatcher {
    my ($class, $type) = @_;
    return sub { state $mro = $class->get_mro; shift @$mro } unless $type;
    return sub { state $mro = $class->get_mro; pop   @$mro } if $type eq 'reverse';
}

sub add_attribute {
    my ($class, $name, $constructor) = @_;
    $attributes{ $class } = {} unless exists $attributes{ $class };
    $attributes{ $class }->{ $name } = $constructor;
}

sub add_method {
    my ($class, $name, $body) = @_;

    my $method = subname(
        $name => sub {
            my $invocant = shift;

            local $::SELF   = $invocant;
            local $::CLASS  = $class;

            $body->( @_ );
        }
    );

    $local_methods{ $class } = {} unless exists $local_methods{ $class };
    $local_methods{ $class }->{ $name } = $method;
}

sub finalize {
    my $class  = shift;

    my %vtable;

    mop::WALKCLASS(
        $class->get_dispatcher('reverse'),
        sub {
            my $c = shift;
            %vtable = (
                %vtable,
                %{ $c->get_local_methods },
            );
        }
    );

    foreach my $name ( keys %vtable ) {
        my $method = $vtable{ $name };
        $class->SUPER::add_method(
            $name,
            $method
        ) unless exists $class->{ $name };
    }

}

1;

__END__