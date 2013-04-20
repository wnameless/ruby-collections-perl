use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 7;
use Ruby::Collections;

is( rh( undef => 2 )->has_all, 1, 'Testing has_all()' );

is( rh( 'a' => 1, '2' => 'b' )->has_all( sub { looks_like_number $_[0] } ),
	0, 'Testing has_all() with block' );

is( rh( 1 => 2 )->has_any, 1, 'Testing has_any()' );

is( rh->has_any, 0, 'Testing has_any() with empty hash' );

is_deeply(
	rh( 'a' => 123, 'b' => 456 )->assoc('b'),
	[ 'b', 456 ],
	'Testing assoc()'
);

is( rh( 'a' => 123, 'b' => 456 )->assoc('c'),
	undef, 'Testing assoc() with nonexist key' );

is_deeply(
	rh( 1 => 1, 2 => 2, 3 => 3, 5 => 5, 4 => 4 )->chunk( sub { $_[0] % 2 } ),
	[
		[ 1, [ [ 1, 1 ] ] ],
		[ 0, [ [ 2, 2 ] ] ],
		[ 1, [ [ 3, 3 ], [ 5, 5 ] ] ],
		[ 0, [ [ 4, 4 ] ] ]
	],
	'Testing chunk()'
);

