package Ruby::Collections;
@ISA       = qw(Exporter);
@EXPORT    = qw(ra rh p p_array p_hash);
@EXPORT_OK = qw(ra rh p p_array p_hash);
our $VERSION = '0.01';
use strict;
use v5.10;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Ruby::Hash;
use Ruby::Array;
use Scalar::Util qw(reftype);

sub ra {
	my $new_ary = tie my @new_ary, 'Ruby::Array';
	if (   @_ == 1
		&& reftype( $_[0] ) eq 'ARRAY'
		&& ref( $_[0] ) ne 'Ruby::Array' )
	{
		@new_ary = @{ $_[0] };
	}
	else {
		@new_ary = @_;
	}

	return $new_ary;
}

sub rh {
	my $new_hash = tie my %new_hash, 'Ruby::Hash';

	if ( @_ == 0 ) {
		return $new_hash;
	}
	elsif ( @_ == 1 ) {
		if ( reftype( $_[0] ) eq 'HASH' ) {
			%new_hash = %{ $_[0] };
		}
		else {
			die 'Input is not a HASH.';
		}
	}
	else {
		if ( @_ % 2 == 0 ) {
			for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
				$new_hash->{ $_[$i] } = $_[ $i + 1 ];
			}
		}
		else {
			die 'Number of keys and values is not even.';
		}
	}

	return $new_hash;
}

sub p {
	for my $item (@_) {
		if ( reftype($item) eq 'ARRAY' ) {
			say p_array($item);
		}
		elsif ( reftype($item) eq 'HASH' ) {
			say p_hash($item);
		}
		else {
			say defined $item ? "$item" : 'undef';
		}
	}
}

sub p_array {
	my $ary     = shift @_;
	my @str_ary = ();

	for my $item ( @{$ary} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			push( @str_ary, p_array($item) );
		}
		elsif ( reftype($item) eq 'HASH' ) {
			push( @str_ary, p_hash($item) );
		}
		else {
			push( @str_ary, defined $item ? "$item" : 'undef' );
		}
	}

	return '[' . join( ', ', @str_ary ) . ']';
}

sub p_hash {
	my $hash        = shift @_;
	my @str_ary     = ();
	my @key_str_ary = ();
	my @val_str_ary = ();

	while ( my ( $key, $val ) = each %$hash ) {
		if ( reftype($key) eq 'ARRAY' ) {
			push( @key_str_ary, p_array($key) );
		}
		elsif ( reftype($key) eq 'HASH' ) {
			push( @key_str_ary, p_hash($key) );
		}
		else {
			push( @key_str_ary, defined $key ? "$key" : 'undef' );
		}

		if ( reftype($val) eq 'ARRAY' ) {
			push( @val_str_ary, p_array($val) );
		}
		elsif ( reftype($val) eq 'HASH' ) {
			push( @val_str_ary, p_hash($val) );
		}
		else {
			push( @val_str_ary, defined $val ? "$val" : 'undef' );
		}
	}

	for ( my $i = 0 ; $i < scalar(@key_str_ary) ; $i++ ) {
		@str_ary[$i] = @key_str_ary[$i] . ' => ' . @val_str_ary[$i];
	}

	return '{' . join( ', ', @str_ary ) . '}';
}

if ( __FILE__ eq $0 ) {
	my $ra = ra( 7, 0.111, 2, 9, 4, 5, 8, 12 );
	p [ 1, 2, 3 ];
}

1;
__END__;
