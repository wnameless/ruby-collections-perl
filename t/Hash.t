use strict;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 4;
use Ruby::Collections;

is( rh( undef => 1 )->has_all, 1, 'Testing has_all()' );

is( rh( 'a' => 1, '2' => 'b' )->has_all( sub { looks_like_number $_[0] } ),
	0, 'Testing has_all() with block' );

is( rh( 1 => 2 )->has_any, 1, 'Testing has_any()' );

is( rh->has_any, 0, 'Testing has_any() with empty hash' );
