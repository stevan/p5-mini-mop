#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

Sometimes you might not want to
actually declare the enclosing
package. And you shouldn't have
to. But just as with other things
it should create the namespace
for you automagically.

=cut

class Foo::Bar {}

my $foo = Foo::Bar->new;
ok( $foo->isa( Foo::Bar ), '... the object is from class Foo' );
is( Foo::Bar->get_name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');
like( "$foo", qr/^Foo::Bar/, '... object stringification includes fully qualified class name' );

done_testing;
