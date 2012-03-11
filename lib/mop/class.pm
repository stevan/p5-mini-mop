package mop::class;

use 5.014;
use strict;
use warnings;

use Hash::Util::FieldHash qw[ fieldhashes ];

use parent 'Package::Anon';

fieldhashes \ my (%superclass, %attributes);

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

sub superclass { $superclass{ $_[0] } }
sub attributes { $attributes{ $_[0] } }

sub set_superclass {
    my ($class, $super) = @_;
    $superclass{ $class } = $super;
}

sub add_attribute {
    my ($class, $name, $constructor) = @_;
    $attributes{ $class } = {} unless exists $attributes{ $class };
    $attributes{ $class }->{ $name } = $constructor;
}

sub add_method {
    my ($class, $name, $body) = @_;
    $class->SUPER::add_method(
        $name => sub {
            my $invocant = shift;

            local $::SELF   = $invocant;
            local $::CLASS  = $class;

            $body->( @_ );
        }
    );
}

1;

__END__