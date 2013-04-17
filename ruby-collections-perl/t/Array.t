use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 4;

use_ok('Ruby::Array');
use_ok('Ruby::Hash');
use_ok('Ruby::Collections');

is_deeply(
	ra( 1, 2, 3 )->add( [ 'a', 'b', 'c' ] ),
	[ 1, 2, 3, 'a', 'b', 'c' ],
	'Testing add()'
);
