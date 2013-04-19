use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 28;

use_ok('Ruby::Array');
use_ok('Ruby::Hash');
use_ok('Ruby::Collections');

is_deeply(
	ra( 1, 2, 3 )->add( [ 'a', 'b', 'c' ] ),
	[ 1, 2, 3, 'a', 'b', 'c' ],
	'Testing add()'
);

is_deeply( ra( 'a', '1' )->minus( [ 'a', 'b', 'c', 1, 2 ] ),
	[], 'Testing minus()' );

dies_ok { ra( 1, 2, '3', 'a' )->multiply(-1) }
'Testing mutiply() with negtive argument';

is_deeply(
	ra( 1, 2, '3', 'a' )->multiply(2),
	[ 1, 2, 3, 'a', 1, 2, 3, 'a' ],
	'Testing mutiply() with positive argument'
);

is( ra( 1, 2, '3', 'a' )->multiply(', '),
	'1, 2, 3, a', 'Testing mutiply() with string' );

is_deeply(
	ra( 'a', 'b', 'c', 1, 2 )->intersect( [ '2', 'a', 'd' ] ),
	[ 'a', 2 ],
	'Testing intersect()'
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

is_deeply( ra( 1, 2, ra( 3, 4 ) )->assoc(3), [ 3, 4 ], 'Testing assoc()' );

is( ra( 1, 2, 3, 4 )->assoc(2), undef, 'Testing assoc() with no sub arrays' );

is( ra( 1, 2, 3, 4 )->at(-2), 3, 'Testing at()' );

is( ra( 1, 2, 3, 4 )->at(4), undef, 'Testing at() with nonexist index' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 4 } ), 4, 'Testing bsearch()' );

is( ra( 1, 2, 3, 4 )->bsearch( sub { $_[0] == 5 } ),
	undef, 'Testing bsearch() with false condition' );

is_deeply(
	ra( 1, 3, 2, 4, 5, 6 )->chunk( sub { [ $_[0] % 2 ] } ),
	[ [ [1], [ 1, 3 ] ], [ [0], [ 2, 4 ] ], [ [1], [5] ], [ [0], [6] ] ],
	'Testing chunk()'
);

is_deeply( ra( 1, 2, 3 )->clear, [], 'Testing clear()' );

is_deeply(
	ra( 'a', 'bc', 'def' )->collect( sub { length( $_[0] ) } ),
	[ 1, 2, 3 ],
	'Testing collect()'
);

my $ra = ra( 'a', 'bc', 'def' );
$ra->collectEx( sub { length( $_[0] ) } );
is_deeply( $ra, [ 1, 2, 3 ], 'Testing collectEx()' );

is_deeply(
	ra( 'a', 'b', 'c' )->map( sub { $_[0] . 'd' } ),
	[ 'ad', 'bd', 'cd' ],
	'Testing map()'
);
