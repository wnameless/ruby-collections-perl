use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::Exception;
use Test::Output;
use Test::More tests => 3;

use_ok('Ruby::Array');
use_ok('Ruby::Hash');
use_ok('Ruby::Collections');

