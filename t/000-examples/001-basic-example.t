#!perl

use strict;
use warnings;

use Test::More;

use mop;

class Point {
    has $x = 0;
    has $y = 0;

    method x { $x }
    method y { $y }

    method set_x ($new_x) {
        $x = $new_x;
    }

    method clear {
        ($x, $y) = (0, 0);
    }

    method dump {
        +{ x => $self->x, y => $self->y }
    }
}

# ... subclass it ...

class Point3D (extends => Point) {
    has $z = 0;

    method z { $z }

    method dump {
        my $orig = super;
        $orig->{'z'} = $z;
        $orig;
    }
}

## Test an instance

my $p = Point->new( x => 100, y => 320 );

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

my $p2 = Point->new( x => 1, y => 30 );

isnt $p, $p2, '... not the same instances';

is $p2->x, 1, '... got the right value for x';
is $p2->y, 30, '... got the right value for y';
is_deeply $p2->dump, { x => 1, y => 30 }, '... got the right value from dump';

$p2->set_x(500);
is $p2->x, 500, '... got the right value for x';
is_deeply $p2->dump, { x => 500, y => 30 }, '... got the right value from dump';

is $p->x, 10, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

$p->clear;
is $p->x, 0, '... got the right value for x';
is $p->y, 0, '... got the right value for y';
is_deeply $p->dump, { x => 0, y => 0 }, '... got the right value from dump';

## Test the subclass

my $p3d = Point3D->new( x => 1, y => 2, z => 3 );

is $p3d->x, 1, '... got the right value for x';
is $p3d->y, 2, '... got the right value for y';
is $p3d->z, 3, '... got the right value for z';

is_deeply $p3d->dump, { x => 1, y => 2, z => 3 }, '... go the right value from dump';

## test the default values

{
    my $p = Point->new;
    is_deeply $p->dump, { x => 0, y => 0 }, '... go the right value from dump';

    my $p3d = Point3D->new;
    is_deeply $p3d->dump, { x => 0, y => 0, z => 0 }, '... go the right value from dump';
}

done_testing;



