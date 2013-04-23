use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 62;
use Ruby::Collections;

is( rh( undef => 2 )->has_all, 1, 'Testing has_all()' );

is( rh( 'a' => 1, '2' => 'b' )->has_all( sub { looks_like_number $_[0] } ),
	0, 'Testing has_all() with block' );

is( rh( 1 => 2 )->has_any, 1, 'Testing has_any()' );

is( rh->has_any, 0, 'Testing has_any() with empty hash' );

is( rh( 2 => 4, 6 => 8 )->has_any( sub { $_[0] % 2 == 1 } ),
	0, 'Testing has_any() with block' );

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
	rh( [ 1, 5 ] => 3, 2 => 4 )->delete_if(
		sub {
			my ( $key, $val ) = @_;
			$key eq p_obj( [ 1, 5 ] );
		}
	),
	{ 2 => 4 },
	'Testing delete_if()'
);

is_deeply(
	rh( 'a' => 1, 'b' => 2 )->detect(
		sub {
			my ( $key, $val ) = @_;
			$val % 2 == 0;
		}
	),
	[ 'b', 2 ],
	'Testing detect()'
);

is(
	rh( 'a' => 1, 'b' => 2 )->detect(
		sub { 'Not Found!' },
		sub {
			my ( $key, $val ) = @_;
			$val % 2 == 3;
		}
	),
	'Not Found!',
	'Testing detect() with default value'
);

dies_ok { rh( 'a' => 1, 'b' => 2 )->detect( 1, 2, 3 ) }
'Testing detect() with wrong number of arguments';

is_deeply(
	rh( 1 => 'a', undef => 0, 'b' => 2 )->drop(1),
	[ [ 'undef', 0 ], [ 'b', 2 ] ],
	'Testing drop()'
);

dies_ok { rh( 1 => 'a', undef => 0, 'b' => 2 )->drop(-2) }
'Test drop() with negative aize';

is_deeply(
	rh( 0 => 2, 1 => 3, 2 => 4, 5 => 7 )->drop_while(
		sub {
			my ( $key, $val ) = @_;
			$key % 2 == 1;
		}
	),
	[ [ 1, 3 ], [ 2, 4 ], [ 5, 7 ] ],
	'Testing drop_while()'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	{ 1 => 2, 3 => 4 },
	'Testing each() return value'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4, 5 => 6 )->each_cons(
			2,
			sub {
				my ($sub_ary) = @_;
				p $sub_ary->[0]->zip( $sub_ary->[1] );
			}
		);
	},
	"[[1, 3], [2, 4]]\n[[3, 5], [4, 6]]\n",
	'Testing each_cons()'
);

dies_ok { rh( 1 => 2, 3 => 4, 5 => 6 )->each_cons(0) }
'Testing each_cons() with invalid size';

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each_entry()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	{ 1 => 2, 3 => 4 },
	'Testing each_entry() return value'
);

stdout_is(
	sub {
		rh( 1 => 2, 3 => 4 )->each(
			sub {
				my ( $key, $val ) = @_;
				print "$key, $val, ";
			}
		);
	},
	'1, 2, 3, 4, ',
	'Testing each_pair()'
);

is_deeply(
	rh( 1 => 2, 3 => 4 )->each(
		sub {
			my ( $key, $val ) = @_;
			$key + $val;
		}
	),
	{ 1 => 2, 3 => 4 },
	'Testing each_pair() return value'
);

is_deeply(
	rh( 1 => 2, 3 => 4, 5 => 6 )->each_slice(2),
	[ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ] ] ],
	'Testing each_slice()'
);

dies_ok { rh( 1 => 2, 3 => 4, 5 => 6 )->each_slice(0) }
'Testing each_slice() with invalid slice siz';

stdout_is(
	sub {
		rh( 1 => 2, 'a' => 'b', [ 3, { 'c' => 'd' } ] => 4 )->each_key(
			sub {
				print "$_[0], ";
			}
		);
	},
	'1, a, [3, {c=>d}], ',
	'Testing each_key()'
);

stdout_is(
	sub {
		rh( 1 => 2, 'a' => undef, '3' => rh( [2] => [3] ) )->each_value(
			sub {
				print p_obj( $_[0] ) . ', ';
			}
		);
	},
	'2, undef, {[2]=>[3]}, ',
	'Testing each_value()'
);

stdout_is(
	sub {
		rh( 'a' => 'b', 'c' => 'd' )->each_with_index(
			sub {
				my ( $key, $val, $index ) = @_;
				print "$key, $val, $index, ";
			}
		);
	},
	'a, b, 0, c, d, 1, ',
	'Testing each_with_index()'
);

stdout_is(
	sub {
		my $ra = ra;
		rh( 1 => 2, 3 => 4 )->each_with_object(
			$ra,
			sub {
				my ( $key, $val, $obj ) = @_;
				$obj->push( $key, $val );
			}
		);
		p $ra;
	},
	"[1, 2, 3, 4]\n",
	'Testing each_with_object()'
);

is( rh->is_empty, 1, 'Testing is_empty()' );

is( rh( 1 => undef )->is_empty, 0, 'Testing is_empty() with undef value' );

is( rh( undef => 1 )->is_empty, 0, 'Testing is_empty() with undef key' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->entries,
	[ [ 1, 2 ], [ 3, 4 ] ],
	'Testing entries()'
);

is( rh( 1 => 2, 3 => 4, 5 => 6 )->eql( { 5 => 6, 3 => 4, 1 => 2 } ),
	1, 'Testing eql()' );

is(
	rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] )
	  ->eql( rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] ) ),
	1,
	'Testing eql() with Ruby::Hash'
);

is(
	rh( [ 1, 2 ] => 3, [4] => [ 5, 6 ] )
	  ->eql( { [ 1, 2 ] => 3, [4] => [ 5, 6 ] } ),
	0,
	'Testing eql() with Perl hash'
);

is( rh( 1 => 2, 3 => 4 )->fetch(1), 2, 'Testing fetch()' );

dies_ok { rh( 1 => 2, 3 => 4 )->fetch(5) } 'Testing fetch with nonexist key';

is( rh( 1 => 2, 3 => 4 )->fetch( 5, 10 ),
	10, 'Testing fetch() with default value' );

is( rh( 1 => 2, 3 => 4 )->fetch( 5, sub { $_[0] * $_[0] } ),
	25, 'Testing fetch() with block' );

is_deeply(
	rh( 'a' => 1, [ 'b', 'c' ] => 2 )->detect(
		sub {
			my ( $key, $val ) = @_;
			$key eq p_obj( [ 'b', 'c' ] );
		}
	),
	[ p_obj( [ 'b', 'c' ] ), 2 ],
	'Testing find()'
);

is(
	rh( 'a' => 1, 'b' => 2 )->detect(
		sub { 'Not Found!' },
		sub {
			my ( $key, $val ) = @_;
			$val % 2 == 3;
		}
	),
	'Not Found!',
	'Testing find() with default value'
);

is_deeply(
	rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4' )->find_all(
		sub {
			my ( $key, $val ) = @_;
			looks_like_number($key) && looks_like_number($val);
		}
	),
	[ [ 1, 2 ], [ 3, 4 ] ],
	'Testing find_all()'
);

is( rh( 1 => 2, 3 => 4 )->find_index( [ 3, 4 ] ), 1, 'Testing find_index()' );

is( rh( 1 => 2, 3 => 4 )->find_index( [ 5, 6 ] ),
	undef, 'Testing find_index() with nonexist pair' );

is( rh( 1 => 2, 3 => 4 )->find_index( sub { $_[0] == 3 } ),
	1, 'Testing find_index() with block' );

is_deeply( rh( 1 => 2, 3 => 4 )->first, [ 1, 2 ], 'Testing first()' );

is_deeply(
	rh( 1 => 2, 3 => 4 )->first(5),
	[ [ 1, 2 ], [ 3, 4 ] ],
	'Testing first() with n'
);

dies_ok { rh( 1 => 2, 3 => 4 )->first(-1) }
'Testing first() with negative array size';

is_deeply(
	rh( 1 => 2, 3 => 4 )->flat_map( sub { [ $_[0] * $_[1] * 10 ] } ),
	[ 20, 120 ],
	'Testing flat_map()'
);

is_deeply(
	rh( 1 => [ 2, 3 ], 4 => 5 )->flatten,
	[ 1, [ 2, 3 ], 4, 5 ],
	'Testing flatten()'
);

is_deeply(
	rh( 1 => [ 2, 3 ], 4 => 5 )->flatten(2),
	[ 1, 2, 3, 4, 5 ],
	'Testing flatten() with n'
);
