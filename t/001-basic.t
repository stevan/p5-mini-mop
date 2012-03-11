#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

use mop;

my $Foo = mop::class->new('Foo');

$Foo->add_attribute('$bar', sub { 10 });

$Foo->add_method('bar' => sub { $::SELF->{'$bar'} });

{
    my $foo = $Foo->new;
    warn Dumper $foo;
    warn Dumper $foo->bar;
}

{
    my $foo = $Foo->new( bar => 20 );
    warn Dumper $foo;
    warn Dumper $foo->bar;
}

done_testing;