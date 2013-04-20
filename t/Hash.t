use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 3;

use_ok('Ruby::Collections');

is( rh( undef => 1 )->has_all, 1, 'Testing has_all()' );

is( rh( 'a' => 1, '2' => 'b' )->has_all( sub { looks_like_number $_[0] } ),
	0, 'Testing has_all() with block' );
