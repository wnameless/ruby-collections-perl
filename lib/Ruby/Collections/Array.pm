package Ruby::Collections::Array;
use Tie::Array;
our @ISA = 'Tie::StdArray';
use strict;
use v5.10;
use Scalar::Util qw(looks_like_number reftype);
use Math::Combinatorics;
use Set::CrossProduct;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Ruby::Collections;
use overload (
	'+'  => \&add,
	'-'  => \&minus,
	'*'  => \&multiply,
	'&'  => \&intersection,
	'|'  => \&union,
	'<<' => \&double_left_arrows,
	'==' => \&eql,
	'eq' => \&eql
);

=item add()
  Append other ARRAY to itself.
=cut

sub add {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @$self;
	push( @new_ary, @{$other_ary} );

	return $new_ary;
}

=item minus()
  Remove all elements which other ARRAY contains from itself.
=cut

sub minus {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};
	for my $item ( @{$other_ary} ) {
		$new_ary->delete($item);
	}

	return $new_ary;
}

=item multiply()
  Duplicate self by a number of times or join all elements by a string.
=cut

sub multiply {
	my ( $self, $sep_or_n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( looks_like_number $sep_or_n ) {
		die 'ArgumentError: negative argument' if ( $sep_or_n < 0 );

		for ( my $i = 0 ; $i < $sep_or_n ; $i++ ) {
			push( @new_ary, @{$self} );
		}
		return $new_ary;
	}
	else {
		return join( $sep_or_n, @{$self} );
	}
}

=item intersection()
  Generate an intersection set between self and other ARRAY.
=cut

sub intersection {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	foreach my $item ( @{$self} ) {
		if (   ( not $new_ary->include($item) )
			&& $self->include($item)
			&& ra($other)->include($item) )
		{
			$new_ary->push($item);
		}
	}

	return $new_ary;
}

=item has_all()
  Check if all elements are defined.
  When block given, check if all results returned by block are true.
=cut

sub has_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( defined $block ) {
			return 0 if ( not $block->($item) );
		}
		else {
			return 0 if ( not defined $item );
		}
	}

	return 1;
}

=item has_any()
  Check if any element is defined.
  When block given, check if any result returned by block are true.
=cut

sub has_any {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( defined $block ) {
			return 1 if ( $block->($item) );
		}
		else {
			return 1 if ( defined $item );
		}
	}

	return 0;
}

=item assoc()
  Find the first sub array which contains target object as the first element.
=cut

sub assoc {
	my ( $self, $target ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			my @sub_array = @{$item};
			if ( p_obj( $sub_array[0] ) eq p_obj($target) ) {
				my $ret = tie my @ret, 'Ruby::Collections::Array';
				@ret = @sub_array;
				return $ret;
			}
		}
	}

	return undef;
}

=item at()
  Return the element of certain position.
  Return undef if element is not found.
=cut

sub at {
	my ( $self, $index ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return @{$self}[$index];
}

=item bsearch()
  Find the element by certain condition.
  Return undef if element is not found.
  Note: The real binary search is not implemented yet.
=cut

sub bsearch {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			return $item;
		}
	}

	return undef;
}

=item chunk()
  Chunk consecutive elements which is under certain condition
  into [ condition, [ elements... ] ] array.
=cut

sub chunk {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $prev    = undef;
	my $chunk   = tie my @chunk, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		my $key = $block->( @{$self}[$i] );
		if ( p_obj($key) eq p_obj($prev) ) {
			$chunk->push( @{$self}[$i] );
		}
		else {
			if ( $i != 0 ) {
				my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
				$sub_ary->push( $prev, $chunk );
				$new_ary->push($sub_ary);
			}
			$prev = $key;
			$chunk = tie my @chunk, 'Ruby::Collections::Array';
			$chunk->push( @{$self}[$i] );
		}
	}
	if ( $chunk->has_any ) {
		my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
		$sub_ary->push( $prev, $chunk );
		$new_ary->push($sub_ary);
	}

	return $new_ary;
}

=item clear()
  Clear all elements.
=cut

sub clear {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = ();

	return $self;
}

sub combination {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;
	my $combinat =
	  Math::Combinatorics->new( count => $n, data => [ @{$self} ] );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	while ( my @combo = $combinat->next_combination ) {
		my $c = tie my @c, 'Ruby::Collections::Array';
		@c = @combo;
		if ( defined $block ) {
			$block->($c);
		}
		else {
			push( @new_ary, $c );
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub compact {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $item ) {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

sub compactEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my @new_ary;
	for my $item ( @{$self} ) {
		if ( defined $item ) {
			push( @new_ary, $item );
		}
	}
	@{$self} = @new_ary;

	return $self;
}

sub concat {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, @{$other_ary} );

	return $self;
}

sub count {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $obj_or_block ) {
		if ( ref($obj_or_block) eq 'CODE' ) {
			my $count = 0;
			for my $item ( @{$self} ) {
				if ( $obj_or_block->($item) ) {
					$count++;
				}
			}
			return $count;
		}
		else {
			my $count = 0;
			for my $item ( @{$self} ) {
				if ( p_obj($obj_or_block) eq p_obj($item) ) {
					$count++;
				}
			}
			return $count;
		}
	}

	return scalar( @{$self} );
}

sub cycle {
	my ( $self, $n_or_block, $block_or_n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n_or_block && not $block_or_n ) {
		if ( ref($n_or_block) eq 'CODE' ) {
			while (1) {
				for my $item ( @{$self} ) {
					$n_or_block->($item);
				}
			}
		}
	}
	else {
		for ( my $i = 0 ; $i < $n_or_block ; $i++ ) {
			for my $item ( @{$self} ) {
				$block_or_n->($item);
			}
		}
	}
}

sub delete {
	my ( $self, $target, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { p_obj($_) ne p_obj($target) } @{$self};

	if ( $before_len == scalar( @{$self} ) ) {
		if ( defined $block ) {
			return $block->();
		}
		return undef;
	}
	else {
		return $target;
	}
}

sub delete_at {
	my ( $self, $index ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $target = @{$self}[$index];

	if ( scalar( @{$self} ) == 0 ) {
		return undef;
	}
	elsif ( $index >= 0 && $index < scalar( @{$self} ) ) {
		splice( @{$self}, $index, 1 );
		return $target;
	}
	elsif ( $index <= -1 && $index >= -scalar( @{$self} ) ) {
		splice( @{$self}, $index, 1 );
		return $target;
	}
	else {
		return undef;
	}
}

sub delete_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = grep { !$block->($_) } @{$self};

	return $self;
}

sub drop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $n < 0 ) {
		die 'attempt to drop negative size';
	}

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $i ( 0 .. scalar( @{$self} ) - 1 ) {
		if ( $i >= $n ) {
			push( @new_ary, @{$self}[$i] );
		}
	}

	return $new_ary;
}

sub drop_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $cut_point = undef;
	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( $block->($item) || $cut_point ) {
			$cut_point = 1;
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

sub each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		$block->($item);
	}

	return $self;
}

sub each_cons {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: invalid size' if ( $n <= 0 );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		if ( $i + $n <= scalar( @{$self} ) ) {
			my $cons = tie my @cons, 'Ruby::Collections::Array';
			for ( my $j = $i ; $j < $i + $n ; $j++ ) {
				$cons->push( $self->at($j) );
			}
			if ( defined $block ) {
				$block->($cons);
			}
			else {
				push( @new_ary, $cons );
			}
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

sub each_entry {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			$block->($item);
		}
	}

	return $self;
}

sub each_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		$block->($i);
	}

	return $self;
}

sub each_slice {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: invalid slice size'
	  if ( ( not defined $n ) || $n <= 0 );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $blocks =
	  scalar( @{$self} ) % $n == 0
	  ? int( scalar( @{$self} ) / $n )
	  : int( scalar( @{$self} ) / $n ) + 1;
	for ( my $i = 0 ; $i < $blocks ; $i++ ) {
		my $cons = tie my @cons, 'Ruby::Collections::Array';
		for (
			my $j = $i * $n ;
			$j < scalar( @{$self} ) ? $j < $i * $n + $n : undef ;
			$j++
		  )
		{
			$cons->push( $self->at($j) );
		}
		if ( defined $block ) {
			$block->($cons);
		}
		else {
			push( @new_ary, $cons );
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

sub each_with_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			$block->( @{$self}[$i], $i );
		}
	}

	return $self;
}

sub each_with_object {
	my ( $self, $object, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			$block->( $item, $object );
		}
	}

	return $object;
}

sub is_empty {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( scalar( @{$self} ) == 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other) ne 'ARRAY' ) {
		return 0;
	}

	if ( scalar( @{$self} ) != scalar( @{$other} ) ) {
		return 0;
	}

	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		if ( p_obj( @{$self}[$i] ) ne p_obj( @{$other}[$i] ) ) {
			return 0;
		}
	}

	return 1;
}

sub fetch {
	my ( $self, $index, $default_value_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $index >= scalar( @{$self} ) || $index < -scalar( @{$self} ) ) {
		if ( defined $default_value_or_block ) {
			if ( ref($default_value_or_block) eq 'CODE' ) {
				return $default_value_or_block->($index);
			}
			else {
				return $default_value_or_block;
			}
		}
		else {
			die(    "index "
				  . $index
				  . " outside of array bounds: "
				  . -scalar( @{$self} ) . "..."
				  . scalar( @{$self} ) );
		}
	}
	return $self->at($index);
}

sub fill {
	if ( @_ == 2 ) {
		if ( ref( $_[1] ) eq 'CODE' ) {
			my ( $self, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}

			return $self;
		}
		else {
			my ( $self, $item ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
	elsif ( @_ == 3 ) {
		if ( ref( $_[2] ) eq 'CODE' ) {
			my ( $self, $start, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}

			return $self;
		}
		else {
			my ( $self, $item, $start ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
	elsif ( @_ == 4 ) {
		if ( ref( $_[3] ) eq 'CODE' ) {
			my ( $self, $start, $length, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < $start + $length ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}
			return $self;
		}
		else {
			my ( $self, $item, $start, $length ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < $start + $length ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
}

sub find {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			return $item;
		}
	}

	return undef;
}

*detect = \&find;

sub find_index {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			return $i if ( $obj_or_block->( @{$self}[$i] ) );
		}
	}
	else {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			return $i
			  if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) );
		}
	}

	return undef;
}

sub index {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			if ( $obj_or_block->( @{$self}[$i] ) ) {
				return $i;
			}
		}
	}
	else {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) ) {
				return $i;
			}
		}
	}

	return undef;
}

sub inject {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my $block = shift @_;

		my $out = @{$self}[0];
		for ( my $i = 1 ; $i < scalar( @{$self} ) ; $i++ ) {
			$out = $block->( $out, @{$self}[$i] );
		}

		return $out;
	}
	elsif ( @_ == 2 ) {
		my ( $init, $block ) = @_;

		my $out = $init;
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			$out = $block->( $out, @{$self}[$i] );
		}

		return $out;
	}
	else {
		die 'ArgumentError: wrong number of arguments (' . @_ . ' for 0..2)';
	}
}

sub reduce {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my $block = shift @_;

		return $self->inject($block);
	}
	elsif ( @_ == 2 ) {
		my ( $init, $block ) = @_;

		return $self->inject( $init, $block );
	}
	else {
		die 'ArgumentError: wrong number of arguments (' . @_ . ' for 0..2)';
	}
}

sub first {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && $i < scalar( @{$self} ) ; $i++ ) {
			push( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		return @{$self}[0];
	}
}

sub flat_map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	$self->map($block)->each(
		sub {
			if ( reftype( $_[0] ) eq 'ARRAY' ) {
				if ( $_[0]->has_any( sub { reftype( $_[0] ) eq 'ARRAY' } ) ) {
					$new_ary->push( $_[0]->flatten(1) );
				}
				else {
					$new_ary->concat( $_[0] );
				}
			}
			else {
				$new_ary->push( $_[0] );
			}
		}
	);

	return $new_ary;
}

*collect_concat = \&flat_map;

sub flatten {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

sub recursive_flatten {
	caller eq __PACKAGE__ or die;
	my ( $ary, $n ) = @_;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$ary} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

sub flattenEx {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}
	@{$self} = @new_ary;

	return $self;
}

sub grep {
	my ( $self, $pattern, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( p_obj($item) =~ $pattern ) {
			if ( defined $block ) {
				push( @new_ary, $block->($item) );
			}
			else {
				push( @new_ary, $item );
			}
		}
	}

	return $new_ary;
}

sub group_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = tie my %new_hash, 'Ruby::Collections::Hash';
	for my $item ( @{$self} ) {
		my $key = $block->($item);
		if ( $new_hash->{$key} ) {
			$new_hash->{$key}->push($item);
		}
		else {
			$new_hash->{$key} = tie my @group, 'Ruby::Collections::Array';
			$new_hash->{$key}->push($item);
		}
	}

	return $new_hash;
}

sub include {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( p_obj($item) eq p_obj($obj) ) {
			return 1;
		}
	}

	return 0;
}

*has_member = \&include;

sub replace {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other_ary) eq 'ARRAY' ) {
		@{$self} = @{$other_ary};
	}
	else {
		die 'TypeError: no implicit conversion of '
		  . reftype($other_ary)
		  . ' into Array';
	}

	return $self;
}

sub insert {
	my $self  = shift(@_);
	my $index = shift(@_);

	if ( $index < -scalar( @{$self} ) ) {
		die(    "IndexError: index "
			  . $index
			  . " too small for array; minimum: "
			  . -scalar( @{$self} ) );
	}
	elsif ( $index > scalar( @{$self} ) ) {
		for ( my $i = scalar( @{$self} ) ; $i < $index ; $i++ ) {
			push( @{$self}, undef );
		}
		splice( @{$self}, $index, 0, @_ );
	}
	else {
		splice( @{$self}, $index, 0, @_ );
	}

	return $self;
}

sub inspect {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return p_array $self;
}

sub to_s {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->inspect;
}

sub join {
	my ( $self, $separator ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $separator ) {
		return join( $separator, @{$self} );
	}
	else {
		return join( '', @{$self} );
	}
}

sub keep_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = grep { $block->($_) } @{$self};

	return $self;
}

sub last {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for (
			my $i = scalar( @{$self} ) - 1 ;
			$i >= 0 && $i > scalar( @{$self} ) - 1 - $n ;
			$i--
		  )
		{
			unshift( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		return @{$self}[-1];
	}
}

sub length {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( @{$self} );
}

*size = \&length;

=item map()
  Transform each element and store them into a new Ruby::Collections::Array.
  Alias: collect()
=cut

sub map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @new_ary, $block->($item) );
	}

	return $new_ary;
}

*collect = \&map;

=item mapEx()
  Transform each element and store them in self.
  Alias: collectEx()
=cut

sub mapEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my @new_ary;
	for my $item ( @{$self} ) {
		push( @new_ary, $block->($item) );
	}
	@{$self} = @new_ary;

	return $self;
}

*collectEx = \&mapEx;

sub max {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $self->sort($block)->last;
	}
	else {
		return $self->sort->last;
	}
}

sub max_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->sort_by($block)->last;
}

sub min {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $self->sort($block)->first;
	}
	else {
		return $self->sort->first;
	}
}

sub min_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->sort_by($block)->first;
}

sub minmax {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		my $sorted_ary = $self->sort($block);
		$new_ary->push( $sorted_ary->first );
		$new_ary->push( $sorted_ary->last );
		return $new_ary;
	}
	else {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		my $sorted_ary = $self->sort();
		$new_ary->push( $sorted_ary->first );
		$new_ary->push( $sorted_ary->last );
		return $new_ary;
	}
}

sub minmax_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $sorted_ary = $self->sort_by($block);
	$new_ary->push( $sorted_ary->first );
	$new_ary->push( $sorted_ary->last );
	return $new_ary;
}

sub has_none {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			return 0 if ( $block->($item) );
		}
	}
	else {
		for my $item ( @{$self} ) {
			return 0 if ($item);
		}
	}

	return 1;
}

sub has_one {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $block ) {
		for my $item ( @{$self} ) {
			if ( $block->($item) ) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}
	else {
		for my $item ( @{$self} ) {
			if ($item) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}

	return $count == 1 ? 1 : 0;
}

sub partition {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = tie my @new_ary,   'Ruby::Collections::Array';
	my $true_ary  = tie my @true_ary,  'Ruby::Collections::Array';
	my $false_ary = tie my @false_ary, 'Ruby::Collections::Array';

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			push( @true_ary, $item );
		}
		else {
			push( @false_ary, $item );
		}
	}
	push( @new_ary, $true_ary, $false_ary );

	return $new_ary;
}

sub permutation {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $combinat =
	  Math::Combinatorics->new( count => $n, data => [ @{$self} ] );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	my $combos = $self->combination($n);
	for my $combo ( @{$combos} ) {
		my $combinat =
		  Math::Combinatorics->new( count => $n, data => [ @{$combo} ] );
		while ( my @permu = $combinat->next_permutation ) {
			my $p = tie my @p, 'Ruby::Collections::Array';
			@p = @permu;
			if ( defined $block ) {
				$block->($p);
			}
			else {
				push( @new_ary, $p );
			}
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub pop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && scalar( @{$self} ) != 0 ; $i++ ) {
			unshift( @new_ary, pop( @{$self} ) );
		}
		return $new_ary;
	}
	else {
		return pop( @{$self} );
	}
}

sub product {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $block = undef;
	if ( ref( $_[-1] ) eq 'CODE' ) {
		$block = pop @_;
	}

	my $array_of_arrays = [];
	for my $item (@_) {
		my @array = @{$item};
		push( @{$array_of_arrays}, \@array );
	}

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $iterator = Set::CrossProduct->new($array_of_arrays);
	while ( $iterator->next ) {
		my $tuple = tie my @tuple, 'Ruby::Collections::Array';
		@tuple = @{ $iterator->get };
		if ( defined $block ) {
			$block->($tuple);
		}
		else {
			push( @new_ary, $tuple );
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub push {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, @_ );

	return $self;
}

sub double_left_arrows {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, $_[0] );

	return $self;
}

sub rassoc {
	my ( $self, $target ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			my @sub_array = @{$item};
			if ( p_obj( $sub_array[-1] ) eq p_obj($target) ) {
				my $ret = tie my @ret, 'Ruby::Collections::Array';
				@ret = @sub_array;
				return $ret;
			}
		}
	}

	return undef;
}

sub reject {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = grep { !$block->($_) } @{$self};

	return $new_ary;
}

sub rejectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { !$block->($_) } @{$self};

	if ( scalar( @{$self} ) == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

sub repeated_combination {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	repeated_combination_loop(
		$n, 0,
		scalar( @{$self} ) - 1,
		sub {
			my $comb = tie my @comb, 'Ruby::Collections::Array';
			for ( my $i = 0 ; $i < scalar( @{ $_[0] } ) ; $i++ ) {
				push( @comb, @{$self}[ @{ $_[0] }[$i] ] );
			}
			if ( defined $block ) {
				$block->($comb);
			}
			else {
				push( @new_ary, $comb );
			}
		}
	);

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub repeated_combination_loop {
	caller eq __PACKAGE__ or die;

	my ( $layer, $start, $end, $block ) = @_;
	my @counter      = ($start) x $layer;
	my $loop_counter = \@counter;

	my @end_status = ($end) x scalar(@$loop_counter);
	do {
		$block->($loop_counter);
		increase_repeated_combination_loop_counter( $loop_counter, $start,
			$end );
	} until ( "@$loop_counter" eq "@end_status" );
	$block->($loop_counter);
}

sub increase_repeated_combination_loop_counter {
	caller eq __PACKAGE__ or die;

	my ( $loop_counter, $start, $end ) = @_;

	for my $i ( reverse( 0 .. scalar(@$loop_counter) - 1 ) ) {
		if ( $loop_counter->[$i] < $end ) {
			$loop_counter->[$i]++;
			last;
		}
		elsif ( $i != 0
			and $loop_counter->[ $i - 1 ] != $end )
		{
			$loop_counter->[ $i - 1 ]++;
			for my $j ( $i .. scalar(@$loop_counter) - 1 ) {
				$loop_counter->[$j] = $loop_counter->[ $i - 1 ];
			}
			last;
		}
	}
}

sub repeated_permutation {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	repeated_permutation_loop(
		$n, 0,
		scalar( @{$self} ) - 1,
		sub {
			my $comb = tie my @comb, 'Ruby::Collections::Array';
			for ( my $i = 0 ; $i < scalar( @{ $_[0] } ) ; $i++ ) {
				push( @comb, @{$self}[ @{ $_[0] }[$i] ] );
			}
			if ( defined $block ) {
				$block->($comb);
			}
			else {
				push( @new_ary, $comb );
			}
		}
	);

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub repeated_permutation_loop {
	caller eq __PACKAGE__ or die;

	my ( $layer, $start, $end, $block ) = @_;
	my @counter      = ($start) x $layer;
	my $loop_counter = \@counter;

	my @end_status = ($end) x scalar(@$loop_counter);
	do {
		$block->($loop_counter);
		increase_repeated_permutation_loop_counter( $loop_counter, $start,
			$end );
	} until ( "@$loop_counter" eq "@end_status" );
	$block->($loop_counter);
}

sub increase_repeated_permutation_loop_counter {
	caller eq __PACKAGE__ or die;

	my ( $loop_counter, $start, $end ) = @_;

	for my $i ( reverse( 0 .. scalar(@$loop_counter) - 1 ) ) {
		if ( $loop_counter->[$i] < $end ) {
			$loop_counter->[$i]++;
			last;
		}
		elsif ( $i != 0
			and $loop_counter->[ $i - 1 ] != $end )
		{
			$loop_counter->[ $i - 1 ]++;
			for my $j ( $i .. scalar(@$loop_counter) - 1 ) {
				$loop_counter->[$j] = $start;
			}
			last;
		}
	}
}

sub reverse {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = reverse( @{$self} );

	return $new_ary;
}

sub reverseEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@{$self} = reverse( @{$self} );

	return $self;
}

sub reverse_each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = $self->reverse;
	if ( defined $block ) {
		for my $item ($new_ary) {
			$block->($item);
		}
	}

	return $new_ary;
}

sub rindex {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = scalar( @{$self} ) - 1 ; $i >= 0 ; $i-- ) {
			if ( $obj_or_block->( @{$self}[$i] ) ) {
				return $i;
			}
		}
	}
	else {
		for ( my $i = scalar( @{$self} ) - 1 ; $i >= 0 ; $i-- ) {
			if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) ) {
				return $i;
			}
		}
	}

	return undef;
}

sub rotate {
	my ( $self, $count ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$count = 1 if ( not defined $count );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};
	if ( scalar( @{$self} ) > 0 ) {
		while ( $count != 0 ) {
			if ( $count > 0 ) {
				$new_ary->push( $new_ary->shift );
				$count--;
			}
			elsif ( $count < 0 ) {
				$new_ary->unshift( $new_ary->pop );
				$count++;
			}
		}
	}

	return $new_ary;
}

sub rotateEx {
	my ( $self, $count ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$count = 1 if ( not defined $count );

	if ( scalar( @{$self} ) > 0 ) {
		while ( $count != 0 ) {
			if ( $count > 0 ) {
				$self->push( $self->shift );
				$count--;
			}
			elsif ( $count < 0 ) {
				$self->unshift( $self->pop );
				$count++;
			}
		}
	}

	return $self;
}

sub sample {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $index_ary = tie my @index_ary, 'Ruby::Collections::Array';
		my $new_ary   = tie my @new_ary,   'Ruby::Collections::Array';

		$self->each_index( sub { $index_ary->push( $_[0] ); } );
		for ( my $i = 0 ; $i < $n && scalar(@index_ary) != 0 ; $i++ ) {
			$new_ary->push(
				@{$self}[
				  $index_ary->delete_at(
					  int( rand( scalar( @{$index_ary} ) ) )
				  )
				]
			);
		}

		return $new_ary;
	}
	else {
		return @{$self}[ int( rand( scalar( @{$self} ) ) ) ];
	}
}

sub select {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = grep { $block->($_) } @{$self};

	return $new_ary;
}

*find_all = \&select;

sub selectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { $block->($_) } @{$self};

	if ( scalar( @{$self} ) == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

sub shift {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && scalar( @{$self} ) != 0 ; $i++ ) {
			push( @new_ary, shift( @{$self} ) );
		}
		return $new_ary;
	}
	else {
		return shift( @{$self} );
	}
}

sub unshift {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	unshift( @{$self}, @_ );

	return $self;
}

sub shuffle {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $index_ary   = tie my @index_ary,   'Ruby::Collections::Array';
	my $shuffle_ary = tie my @shuffle_ary, 'Ruby::Collections::Array';
	my $new_ary     = tie my @new_ary,     'Ruby::Collections::Array';

	$self->each_index( sub { $index_ary->push( $_[0] ); } );
	while ( scalar(@index_ary) != 0 ) {
		$shuffle_ary->push(
			$index_ary->delete_at( int( rand( scalar(@index_ary) ) ) ) );
	}
	for my $i (@shuffle_ary) {
		$new_ary->push( @{$self}[$i] );
	}

	return $new_ary;
}

sub shuffleEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $index_ary   = tie my @index_ary,   'Ruby::Collections::Array';
	my $shuffle_ary = tie my @shuffle_ary, 'Ruby::Collections::Array';
	my $new_ary     = tie my @new_ary,     'Ruby::Collections::Array';

	$self->each_index( sub { $index_ary->push( $_[0] ); } );
	while ( scalar(@index_ary) != 0 ) {
		$shuffle_ary->push(
			$index_ary->delete_at( int( rand( scalar(@index_ary) ) ) ) );
	}
	for my $i (@shuffle_ary) {
		$new_ary->push( @{$self}[$i] );
	}
	@{$self} = @new_ary;

	return $self;
}

sub slice {
	my ( $self, $index, $length ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $length ) {
		if ( $index < -scalar( @{$self} ) || $index >= scalar( @{$self} ) ) {
			return undef;
		}
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		@new_ary = splice( @{$self}, $index, $length );
		return $new_ary;
	}
	else {
		return $self->at($index);
	}
}

sub sliceEx {
	my ( $self, $index, $length ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $length ) {
		if ( $index < -scalar( @{$self} ) || $index >= scalar( @{$self} ) ) {
			return undef;
		}
		$index += scalar( @{$self} ) if ( $index < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i = $index ; $i < scalar( @{$self} ) && $length > 0 ; ) {
			$new_ary->push( $self->delete_at($i) );
			$length--;
		}

		return $new_ary;
	}
	else {
		return $self->delete_at($index);
	}
}

sub slice_before {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $group = undef;
	if ( ref( @_[0] ) eq 'CODE' ) {
		my $block = shift @_;

		for my $item ( @{$self} ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			elsif ( $block->($item) ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			else {
				push( @{$group}, $item );
			}
		}
	}
	else {
		my $pattern = shift @_;

		for my $item ( @{$self} ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			elsif ( p_obj($item) =~ $pattern ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			else {
				push( @{$group}, $item );
			}
		}
	}
	if ( defined $group && $group->has_any ) {
		push( @new_ary, $group );
	}

	return $new_ary;
}

sub sort {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( defined $block ) {
		@new_ary = sort { $block->( $a, $b ) } @{$self};
	}
	else {
		@new_ary = sort {
			if (   looks_like_number( p_obj($a) )
				&& looks_like_number( p_obj($b) ) )
			{
				p_obj($a) <=> p_obj($b);
			}
			else {
				p_obj($a) cmp p_obj($b);
			}
		} @{$self};
	}

	return $new_ary;
}

sub sortEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		@{$self} = sort { $block->( $a, $b ) } @{$self};
	}
	else {
		@{$self} = sort {
			if (   looks_like_number( p_obj($a) )
				&& looks_like_number( p_obj($b) ) )
			{
				p_obj($a) <=> p_obj($b);
			}
			else {
				p_obj($a) cmp p_obj($b);
			}
		} @{$self};
	}

	return $self;
}

sub sort_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $trans_ary = tie my @trans_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @trans_ary, [ $block->($item), $item ] );
	}
	@trans_ary = sort {
		if (   looks_like_number( p_obj( @{$a}[0] ) )
			&& looks_like_number( p_obj( @{$b}[0] ) ) )
		{
			p_obj( @{$a}[0] ) <=> p_obj( @{$b}[0] );
		}
		else {
			p_obj( @{$a}[0] ) cmp p_obj( @{$b}[0] );
		}
	} @trans_ary;
	$trans_ary->mapEx( sub { return @{ $_[0] }[1]; } );

	return $trans_ary;
}

sub sort_byEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $trans_ary = tie my @trans_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @trans_ary, [ $block->($item), $item ] );
	}
	@trans_ary = sort {
		if (   looks_like_number( p_obj( @{$a}[0] ) )
			&& looks_like_number( p_obj( @{$b}[0] ) ) )
		{
			p_obj( @{$a}[0] ) <=> p_obj( @{$b}[0] );
		}
		else {
			p_obj( @{$a}[0] ) cmp p_obj( @{$b}[0] );
		}
	} @trans_ary;
	$trans_ary->mapEx( sub { return @{ $_[0] }[1]; } );
	@{$self} = @trans_ary;

	return $self;
}

sub take {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && $i < scalar( @{$self} ) ; $i++ ) {
			push( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		die 'ArgumentError: wrong number of arguments (0 for 1)';
	}
}

sub take_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			push( @new_ary, $item );
		}
		else {
			return $new_ary;
		}
	}

	return $new_ary;
}

sub to_a {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self;
}

sub entries {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};

	return @new_ary;
}

sub zip {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;
	my $block = undef;
	$block = pop @_ if ( ref( $_[-1] ) eq 'CODE' );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		my $zip = tie my @zip, 'Ruby::Collections::Array';
		for my $ary (@_) {
			push( @zip, @{$ary}[$i] );
		}
		if ( defined $block ) {
			$block->($zip);
		}
		else {
			push( @new_ary, $zip );
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

sub union {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $union = tie my @union, 'Ruby::Collections::Array';
	foreach my $item ( @{$self} ) {
		if ( not $union->include($item) ) {
			push( @union, $item );
		}
	}
	foreach my $item ( @{$other} ) {
		if ( not $union->include($item) ) {
			push( @union, $item );
		}
	}

	return $union;
}

if ( __FILE__ eq $0 ) {
	p ra( 1, 3, 2, 4, 5, [ 1, 2 ] ) & [ 1, 3, 2, 4, 5, [ 1, 2 ] ];
}

1;
__END__;
