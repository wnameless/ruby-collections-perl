use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 86;
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

is( ra( 1, 2, 3 )->count,    3, 'Testing count()' );
is( ra( 1, 2, 2 )->count(2), 2, 'Testing count()' );
is( ra( 1, 2, 3 )->count( sub { $_[0] > 0 } ), 3, 'Testing count()' );

my $ra = ra;
ra( 1, 2, 3 )->cycle( 2, sub { $ra << $_[0] + 1 } );
is_deeply( $ra, ra( 2, 3, 4, 2, 3, 4 ), 'Testing cycle()' );

is( ra( 1, 3, 5 )->delete(3), 3, 'Testing delete()' );

is( ra( 1, 2, 3 )->delete_at(2), 3, 'Testing delete_at()' );

my $ra = ra( 1, 2, 3 );
$ra->delete_if( sub { $_[0] > 2 } );
is_deeply( $ra, ra( 1, 2 ), 'Testing delete_if()' );

my $newra = ra( 1, 3, 5, 7, 9 )->drop(3);
is_deeply( $newra, ra( 7, 9 ), 'Testing drop()' );

my $newra = ra( 1, 2, 3, 4, 5, 1, 4 )->drop_while( sub { $_[0] < 2 } );
is_deeply( $newra, ra( 2, 3, 4, 5, 1, 4 ), 'Testing drop_while()' );

stdout_is(
	sub {
		ra( 1, 2, 3 )->each( sub { print $_[0] } );
	},
	'123',
	'Testing each()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->each_cons(2),
	ra( ra( 1, 2 ), ra( 2, 3 ), ra( 3, 4 ) ),
	'Testing each_cons'
);

is_deeply(
	ra( 1, 2, 3 )->each_entry( sub { print $_[0] } ),
	ra( 1, 2, 3 ),
	'Testing each_entry()'
);

is_deeply(
	ra( 1, 2, 3, 4, 5 )->each_slice(3),
	ra( ra( 1, 2, 3 ), ra( 4, 5 ) ),
	'Testing each_slice'
);

my $newra = ra;
ra( 1, 3, 5, 7 )->each_index( sub { $newra << $_[0] } );
is_deeply( $newra, ra( 0, 1, 2, 3 ), 'Testing each_index' );

my $newra = ra;
ra( 1, 2, 3 )->each_with_index( sub { $newra << $_[1] } );
is_deeply( $newra, ra( 0, 1, 2 ), 'Testing each_with_index' );

is_deeply(
	ra( 1, 2, 3 )->each_with_object( ra, sub { $_[1] << $_[0]**2 } ),
	ra( 1, 4, 9 ),
	'Testing each_with_object'
);

is( ra( 1, 2, 3 )->is_empty(), 0, 'Testing is_empty()' );

is( ra( 1, 2, 3 )->eql( ra( 4, 5, 6 ) ), 0, 'Testing equal' );

is( ra( 1, 2, 3 )->not_eql( ra( 4, 5, 6 ) ), 1, 'Testing not_equal' );

is( ra( 1, 2, 3 )->fetch(2), 3, 'Testing fetch()' );
is( ra( 1, 2, 3 )->fetch( 5, 6 ), 6, 'Testing fetch()' );
is( ra( 1, 2, 3 )->fetch(-1), 3, 'Testing fetch()' );
dies_ok { ra( 1, 2, 3 )->fetch(5) } 'Testing fetch()';

is_deeply( ra( 1, 2, 3 )->fill(4), ra( 4, 4, 4 ), 'Testing fill' );
is_deeply(
	ra( 1, 2, 3, 4, 5 )->fill( 8, 2, 3 ),
	ra( 1, 2, 8, 8, 8 ),
	'Testing fill'
);

is_deeply(
	ra( 1, 2, 3, 4 )->fill( sub { $_[0] } ),
	ra( 0, 1, 2, 3 ),
	'Testing fill'
);

is_deeply(
	ra( 1, 2, 3, 4 )->fill( -2, sub { $_[0] + 1 } ),
	ra( 1, 2, 3, 4 ),
	'Testing fill'
);
is_deeply(
	ra( 1, 2, 3, 4 )->fill( 1, 2, sub { $_[0] + 2 } ),
	ra( 1, 3, 4, 4 ),
	'Testing fill'
);
is_deeply(
	ra( 1, 2,    3,    4 )->fill( 'ab', 1 ),
	ra( 1, 'ab', 'ab', 'ab' ),
	'Testing fill'
);

is( ra( 'a', 'b', 'c', 'b' )->find( sub { $_[0] eq 'b' } ),
	'b', 'Testing find' );

is( ra( 'a', 'b', 'c', 'b' )->find_index('b'), 1, 'Testing find_index' );

is( ra( 'a', 'b', 'c', 'b' )->find_index( sub { $_[0] eq 'b' } ),
	1, 'Testing find_index' );

is( ra( 'a', 'b', 'c', 'c' )->index('c'), 2, 'Testing index' );

is( ra( 1, 2, 3, 4 )->inject( sub { $_[0] + $_[1] } ), 10, 'Testing inject' );

is( ra( 1, 2, 3, 4 )->first, 1, 'Testing first' );

is( ra( 1, 2, 3, 4 )->first(2), ra( 1, 2 ), 'Testing first' );

is_deeply(
	ra( ra( 'a', 'b', 'c' ), ra( 'd', 'e' ) )
	  ->flat_map( sub { $_[0] + ra('f') } ),
	ra( 'a', 'b', 'c', 'f', 'd', 'e', 'f' ),
	'Testing flat_map'
);

is_deeply(
	ra( ra( 'a', 'b' ), ra( 'd', 'e' ) )->flatten,
	ra( 'a', 'b', 'd', 'e' ),
	'Testing fltten'
);

=cut
is_deeply(
	ra( ra( 'a', 'b' ), ra( 'd', 'e', ra( 'f', 'g' ) ) )->recursive_flatten(1),
	ra(
		 ra( 'a', 'b' ), ra( 'd', 'e', 'f', 'g' )), 'Testing recursive_flatten '
	);
=cut

is_deeply(
	ra( 'abbc', 'qubbn', 'accd' )->grep('bb'),
	ra( 'abbc', 'qubbn' ),
	'Testing grep()'
);

=cut
is_deeply(
	ra( 'abbc',  'qubbn', 'accd' )->grep( 'bb', sub { $_[0] + 'l' } ),
	ra( 'abbcl', 'qubbnl' ),
	'Testing grep()'
);
=cut

is_deeply(
	ra( 1, 2, 3, 4 )->group_by( sub { $_[0] % 3 } ),
	rh( 1 => [ 1, 4 ], 2 => [2], 0 => [3] ),
	'Testing group_by()'
);

=cut
is( ra( 1, 3, 5, 7, 9 )->include(9), true, 'Testing include()' );
=cut

is_deeply(
	ra( 1, 4, 6 )->replace( ra( 2, 5 ) ),
	ra( 2, 5 ),
	'Testing replace()'
);

is_deeply(
	ra( 1, 2, 3, 4 )->insert( 2, 5 ),
	ra( 1, 2, 5, 3,              4 ),
	'Testing insert()'
);

=cut
is_deeply(
	ra( 1, 2, 3, 4 )->insert( -2, 5 ),
	ra( 1, 2, 3, 5, 4 ),
	'Testing insert()'
);
=cut

=cut
is( ra( 1, 2, 3 )->inspect(), '[1, 2, 3]', 'Testing inspect()' );
=cut

is( ra( 1, 2, 3 )->to_s(), '[1, 2, 3]', 'Testing to_s()' );

is( ra( 'a', 'b', 'c' )->join("/"), 'a/b/c', 'Testing join()' );

is_deeply( ra( 1, 2, 3 )->keep_if( sub { $_[0] > 2 } ), ra(3), 'Testing keep_if()' );

is(ra(1, 2, 3)->last, 3, 'Testing last()');
is_deeply(ra(1, 2, 3)->last(2), ra(2, 3), 'Testing last()');

is(ra(1, 2, 3)->length(), 3, 'Testing length()');
is(ra()->length(), 0, 'Testing length()');

is(ra(1, 2, 3)->max(), 3, 'Testing max()');
is(ra(1, 2, 3)->max(sub {$_[0] <=> $_[1]}), 3, 'Testing max()');#

is(ra('avv', 'aldivj', 'kgml')->max_by(sub {length($_[0])}), 'aldivj', 'Testing max_by');

is(ra(1, 2, 3)->min(), 1, 'Testing max()');
is(ra(1, 2, 3)->min(sub {$_[0] <=> $_[1]}), 1, 'Testing max()');#

is(ra('kv', 'aldivj', 'kgml')->min_by(sub {length($_[0])}), 'kv', 'Testing min_by()');

is_deeply(ra(1, 2, 3)->minmax, ra(1, 3), 'Testing minmax()');
is_deeply(ra('bbb', 'foekvv', 'rd')->minmax(sub{length($_[0]) <=> length($_[1])}), ra('rd', 'foekvv'), 'Testing minmax()');

is_deeply(ra('heard', 'see', 'thinking')->minmax_by(sub {length($_[0])}), ra('see', 'thinking'), 'Testing minmax_by()');

is(ra(99, 43, 65)->has_none(sub {$_[0] < 50}), 0, 'Testing has_none()');# not turn false
is(ra()->has_none, 1, 'Testing has_none()');# not return true

is(ra(99, 43, 65)->has_one(sub {$_[0] < 50}), 1, 'Testing has_one()');# not turn true
is(ra(100)->has_one, 1, 'Testing has_one()');# not return true

is_deeply(ra(1, 2, 3, 4, 5, 6, 7)->partition(sub {$_[0] % 2 == 0}), ra(ra(2, 4, 6), ra(1, 3, 5, 7)), 'Testing partition()');

=cut
is_deeply(ra(1, 2)->permutation, ra(ra(1, 2), ra(2, 1)), 'Testing permutation()');
=cut