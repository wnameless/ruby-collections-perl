use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 32;
use Ruby::Collections;

is_deeply(
	ra( 1, 2, 3 )->add( [ 'a', 'b', 'c' ] ),
	ra( 1, 2, 3, 'a', 'b', 'c' ),
	'Testing add()'
);

is_deeply( ra( 'a', '1' )->minus( [ 'a', 'b', 'c', 1, 2 ] ),
	ra, 'Testing minus()' );

dies_ok { ra( 1, 2, '3', 'a' )->multiply(-1) }
'Testing mutiply() with negtive argument';

is_deeply(
	ra( 1, 2, '3', 'a' )->multiply(2),
	ra( 1, 2, 3, 'a', 1, 2, 3, 'a' ),
	'Testing mutiply() with positive argument'
);

is( ra( 1, 2, '3', 'a' )->multiply(', '),
	'1, 2, 3, a', 'Testing mutiply() with string' );

is_deeply(
	ra( 'a', 'b', 'c', 1, [ 2, 3 ] )
	  ->intersection( [ '2', 'a', 'd', [ 2, 3 ] ] ),
	ra( 'a', [ 2, 3 ] ),
	'Testing intersection()'
);

is( ra()->has_all, 1, 'Testing has_all() with empty array' );

is( ra(undef)->has_all, 0, 'Testing has_all() with undef element' );

is( ra( 2, 4, 6 )->has_all( sub { $_[0] % 2 == 0 } ),
	1, 'Testing has_all() with block#1' );

is( ra( 2, 4, 7 )->has_all( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_all() with block#2' );

is( ra()->has_any, 0, 'Testing has_any() with empty array' );

is( ra(undef)->has_any, 0, 'Testing has_any() with undef element' );

is( ra( 2, 5, 7 )->has_any( sub { $_[0] % 2 == 0 } ),
	1, 'Testing has_any() with block#1' );

is( ra( 2, 4, 6 )->has_any( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_all() with block#2' );

is_deeply( ra( 1, 2, ra( 3, 4 ) )->assoc(3), ra( 3, 4 ), 'Testing assoc()' );

is( ra( 1, 2, 3, 4 )->assoc(2), undef, 'Testing assoc() with no sub arrays' );

is( ra( 1, 2, 3, 4 )->at(-2), 3, 'Testing at()' );

is( ra( 1, 2, 3, 4 )->at(4), undef, 'Testing at() with nonexist index' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 4 } ), 4, 'Testing bsearch()' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 5 } ),
	undef, 'Testing bsearch() with false condition' );

is_deeply(
	ra( 1, 3, 2, 4, 5, 6 )->chunk( sub { $_[0] % 2 } ),
	ra( [ 1, [ 1, 3 ] ], [ 0, [ 2, 4 ] ], [ 1, [5] ], [ 0, [6] ] ),
	'Testing chunk()'
);

my $ra = ra( 1, 2, 3 );
$ra->clear;
is_deeply( $ra, ra, 'Testing clear()' );

is_deeply(
	ra( 'a', 'bc', 'def' )->collect( sub { length( $_[0] ) } ),
	ra( 1,   2,    3 ),
	'Testing collect()'
);

my $ra = ra( 'a', 'bc', 'def' );
$ra->collectEx( sub { length( $_[0] ) } );
is_deeply( $ra, ra( 1, 2, 3 ), 'Testing collectEx()' );

is_deeply(
	ra( 'a',  'b',  'c' )->map( sub { $_[0] . 'd' } ),
	ra( 'ad', 'bd', 'cd' ),
	'Testing map()'
);

my $ra = ra( 'W', 'H', 'H' );
$ra->collectEx( sub { $_[0] . 'a' } );
is_deeply( $ra, ra( 'Wa', 'Ha', 'Ha' ), 'Testing mapEx()' );

is_deeply(
	ra( 1, 2, 3, 4 )->combination(2)->map( sub { $_[0]->sort } )->sort,
	ra( [ 2, 3 ], [ 2, 1 ], [ 2, 4 ], [ 3, 1 ], [ 3, 4 ], [ 1, 4 ] )
	  ->map( sub { ra( $_[0] )->sort } )->sort,
	'Testing combination()'
);

is( p_obj( ra( 1, 2, 3 )->combination( 3, sub { } ) ),
	'[1, 2, 3]', 'Testing combination() with block' );

is_deeply(
	ra( 1, undef, 3, undef, 5 )->compact,
	ra( 1, 3,     5 ),
	'Testing compact()'
);

my $ra = ra( 1, undef, 3, undef, 5 );
$ra->compactEx;
is_deeply( $ra, ra( 1, 3, 5 ), 'Testing compactEx()' );

is_deeply(
	ra( 1, 2, 3 )->concat( [ 4, [ 5, 6 ] ] ),
	ra( 1, 2, 3, 4, [ 5, 6 ] ),
	'Testing concat()'
);

my $ra = ra( 1, 2, 3 );
is_deeply( $ra->count(), 3, 'Testing count()' );
