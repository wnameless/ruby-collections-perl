use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 18;
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

my $rh = rh( 1 => 2, 3 => 4 );
$rh->clear;
is_deeply( $rh, {}, 'Testing clear()' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->collect( sub { $_[0] * $_[1] } ),
	[ 2, 12 ],
	'Testing collect()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->collect_concat( sub { [ [ $_[0] * $_[1] ] ] } ),
	[ [2], [12] ],
	'Testing collect_concat()'
);

is( rh( 'a' => 1 )->delete('a'), 1, 'Testing delete()' );

is( rh( 'a' => 1 )->delete('b'), undef, 'Testing delete() with nonexist key' );

is( rh( 'a' => 1 )->delete( 'a', sub { $_[0] * 3 } ),
	3, 'Testing delete() with block' );

is( rh( 'a' => 'b', 'c' => 'd' )->count, 2, 'Testing count()' );

is(
	rh( 1 => 3, 2 => 4, 5 => 6 )->count(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 0 && $val % 2 == 0;
		}
	),
	1,
	'Testing count() with block'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->cycle( 1, sub { print "$_[0], $_[1], " } );
	},
	'1, 2, 3, 4, ',
	'Testing cycle() with limit'
);

dies_ok { rh( 1 => 2, 3 => 4 )->cycle( 1, 2, 3 ) }
'Testing cycle() with wrong number of arguments';

is_deeply(
	rh( 1 => 3, 2 => 4 )->delete_if(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 1;
		}
	),
	{ 2 => 4 },
	'Testing delete_if()'
);
