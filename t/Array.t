use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 13;

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
