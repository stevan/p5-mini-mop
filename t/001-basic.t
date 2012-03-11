#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

use mop;

class Foo {
    has $bar = 10;
    method bar { ${ $::SELF->{'$bar'} } }
}

{
    my $foo = Foo->new;
    #isa_ok($foo, 'Foo');
    is( $foo->bar, 10, '... got the right value' );
}

{
    my $foo = Foo->new( bar => 20 );
    #isa_ok($foo, 'Foo');
    is( $foo->bar, 20, '... got the right value' );
}

done_testing;