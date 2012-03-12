package mop::class;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Hash::Util::FieldHash qw[ fieldhashes ];
use Sub::Name             qw[ subname ];
use PadWalker             qw[ set_closed_over ];
use Scope::Guard          qw[ guard ];

use parent 'Package::Anon';

fieldhashes \ my (
    %name,
    %superclass,
    %constructor,
    %destructor,
    %attributes,
    %local_methods
);

sub new {
    if ( ref $_[0] ) {
        my $class = shift;
        my %args  = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

        my $instance = {};
        if ( my $attrs = $class->get_all_attributes ) {
            foreach my $attr ( keys %$attrs ) {
                my ($plain_attr) = ($attr =~ /^\$(.*)/);
                if ( exists $args{ $plain_attr } ) {
                    $instance->{ $attr } = \($args{ $plain_attr });
                }
                else {
                    $instance->{ $attr } = \(ref $attrs->{ $attr } ? $attrs->{ $attr }->() : $attrs->{ $attr });
                }
            }
        }

        my $self = $class->bless( $instance );
        mop::WALKCLASS(
            $class->get_dispatcher('reverse'),
            sub { ( $_[0]->get_constructor || return )->( $self, \%args ); return }
        );
        $self;
    }
    else {
        my ($pkg, $name) = @_;
        my $class = $pkg->_new_anon_stash( $name );
        $class->set_name( $name );
        $class;
    }
}

sub get_name          { $name{ $_[0] }          }
sub get_superclass    { $superclass{ $_[0] }    }
sub get_attributes    { $attributes{ $_[0] }    }
sub get_local_methods { $local_methods{ $_[0] } }
sub get_constructor   { $constructor{ $_[0] }   }
sub get_destructor    { $destructor{ $_[0] }    }

sub set_name        { $name{ $_[0] } = $_[1]        }
sub set_superclass  { $superclass{ $_[0] } = $_[1]  }

sub set_constructor {
    my ($class, $body) = @_;
    $constructor{ $class } = $class->_create_method( 'BUILD' => $body )
}

sub set_destructor {
    my ($class, $body) = @_;
    $destructor{ $class } = $class->_create_method( 'DEMOLISH' => $body )
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

sub get_all_methods {
    my $class = shift;
    my %methods;
    mop::WALKCLASS(
        $class->get_dispatcher('reverse'),
        sub {
            my $c = shift;
            %methods = (
                %methods,
                %{ $c->get_local_methods || {} },
            );
        }
    );
    \%methods;
}

sub get_all_attributes {
    my $class = shift;
    my %attrs;
    mop::WALKCLASS(
        $class->get_dispatcher('reverse'),
        sub {
            my $c = shift;
            %attrs = (
                %attrs,
                %{ $c->get_attributes || {} },
            );
        }
    );
    \%attrs;
}

sub add_attribute {
    my ($class, $name, $constructor) = @_;
    $attributes{ $class } = {} unless exists $attributes{ $class };
    $attributes{ $class }->{ $name } = $constructor;
}

sub add_method {
    my ($class, $name, $body) = @_;
    $local_methods{ $class } = {} unless exists $local_methods{ $class };
    $local_methods{ $class }->{ $name } = $class->_create_method( $name, $body );
}

sub finalize {
    my $class  = shift;

    my $methods = $class->get_all_methods;

    foreach my $name ( keys %$methods ) {
        my $method = $methods->{ $name };
        $class->SUPER::add_method(
            $name,
            $method
        ) unless exists $class->{ $name };
    }

    $class->SUPER::add_method('DESTROY' => sub {
        my $self = shift;
        return unless $class; # likely in global destruction ...
        mop::WALKCLASS(
            $class->get_dispatcher,
            sub { ( $_[0]->get_destructor || return )->( $self ); return }
        );
    });
}

sub _create_method {
    my ($class, $name, $body) = @_;

    my $method_name = join '::' => ($class->get_name || ()), $name;

    my $method;
    $method = subname(
        $method_name => sub {
            state $STACK = [];

            my $invocant = shift;
            my $env      = {
                %$invocant,
                '$self'  => \$invocant,
                '$class' => \$class
            };

            push @$STACK => $env;
            set_closed_over( $body, $env );

            my $g = guard {
                pop @$STACK;
                if ( my $env = $STACK->[-1] ) {
                    PadWalker::set_closed_over( $body, $env );
                }
                else {
                    PadWalker::set_closed_over( $body, {
                        (map { $_ => \undef } keys %$invocant),
                        '$self'  => \undef,
                        '$class' => \undef,
                    });
                }
            };

            local $::SELF   = $invocant;
            local $::CLASS  = $class;
            local $::CALLER = $method;

            $body->( @_ );
        }
    );
}

1;

__END__