package Ruby::Hash;
use Tie::Hash;
our @ISA = 'Tie::StdHash';
use strict;
use v5.10;
use Scalar::Util qw(reftype);
use FindBin;
use lib "$FindBin::Bin/../../lib";
use Ruby::OrderedHash;
use Ruby::Collections;

sub TIEHASH {
    my $class = shift;

    my $hash = tie my %hash, 'Ruby::OrderedHash';

    bless \%hash, $class;
}

=item has_all()
  Return 1.
  If block is given, return 1 if all results are true,
  otherwise 0.
=cut

sub has_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 0 if ( not $block->( $key, $val ) );
		}
	}

	return 1;
}

sub has_any {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 1 if ( $block->( $key, $val ) );
		}
	}

	return $self->size > 0 ? 1 : 0;
}

sub assoc {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $self->{$obj} ) {
		return ra( $obj, $self->{$obj} );
	}
	else {
		return undef;
	}
}

sub chunk {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $chunk_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		my $chunk_by = $block->( $key, $val );
		if ( $chunk_hash->{$chunk_by} ) {
			$chunk_hash->{$chunk_by}->push( ra( $key, $val ) );
		}
		else {
			$chunk_hash->{$chunk_by} = ra;
			$chunk_hash->{$chunk_by}->push( ra( $key, $val ) );
		}
	}

	return $chunk_hash->to_a;
}

sub clear {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	%$self = ();

	return $self;
}

sub collect {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		$new_ary->push( $block->( $key, $val ) );
	}

	return $new_ary;
}

sub collect_concat {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = $self->collect($block);
	$new_ary->flattenEx(1);

	return $new_ary;
}

sub delete {
	my ( $self, $key, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $block->( delete $self->{$key} );
	}
	else {
		return delete $self->{$key};
	}
}

sub count {
	my ( $self, $ary_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $ary_or_block ) {
		if ( ref($ary_or_block) eq 'CODE' ) {
			while ( my ( $key, $val ) = each %$self ) {
				if ( $ary_or_block->( $key, $val ) ) {
					$count++;
				}
			}
		}
		elsif ( reftype($ary_or_block) eq 'ARRAY' ) {
			while ( my ( $key, $val ) = each %$self ) {
				if (   p_obj( @{$ary_or_block}[0] ) eq p_obj($key)
					&& p_obj( @{$ary_or_block}[1] ) eq p_obj($val) )
				{
					$count++;
				}
			}
		}
	}
	else {
		return $self->length;
	}

	return $count;
}

sub cycle {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my ($block) = @_;
		while (1) {
			while ( my ( $key, $val ) = each %$self ) {
				$block->( $key, $val );
			}
		}
	}
	elsif ( @_ == 2 ) {
		my ( $n, $block ) = @_;
		for ( my $i = 0 ; $i < $n ; $i++ ) {
			while ( my ( $key, $val ) = each %$self ) {
				$block->( $key, $val );
			}
		}
	}
	else {
		die 'ArgumentError: wrong number of arguments ('
		  . scalar(@_)
		  . ' for 0..1)';
	}
}

sub delete_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			delete $self->{$key};
		}
	}

	return $self;
}

sub detect {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my ($block) = @_;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				return ra( $key, $val );
			}
		}
	}
	elsif ( @_ == 2 ) {
		my ( $default, $block ) = @_;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				return ra( $key, $val );
			}
		}
		return $default->();
	}
	else {
		die 'ArgumentError: wrong number of arguments ('
		  . scalar(@_)
		  . ' for 0..1)';
	}

	return undef;
}

sub drop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: attempt to drop negative size' if ( $n < 0 );

	my $new_ary = ra;
	my $index   = 0;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $n <= $index ) {
			$new_ary->push( ra( $key, $val ) );
		}
		$index++;
	}

	return $new_ary;
}

sub drop_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = ra;
	my $cut_point = 0;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) || $cut_point ) {
			$cut_point = 1;
			$new_ary->push( ra( $key, $val ) );
		}
	}

	return $new_ary;
}

sub each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		$block->( $key, $val );
	}

	return $self;
}

sub each_cons {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->each_cons( $n, $block );
}

sub each_entry {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->each->($block);
}

sub each_pair {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->each($block);
}

sub each_slice {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->each_slice( $n, $block );
}

sub each_key {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $key ( keys %$self ) {
		$block->($key);
	}

	return $self;
}

sub each_value {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $val ( values %$self ) {
		$block->($val);
	}

	return $self;
}

sub each_with_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			$block->( $key, $val, $index );
			$index++;
		}
	}

	return $self;
}

sub each_with_object {
	my ( $self, $object, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			$block->( $key, $val, $object );
		}
	}

	return $object;
}

sub entris {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a;
}

sub is_empty {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( keys %$self ) == 0 ? 1 : 0;
}

sub eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other) eq 'HASH' ) {
		while ( my ( $key, $val ) = each %$self ) {
			if ( $val ne $other->{$key} ) {
				return 0;
			}
		}
	}
	else {
		return 0;
	}

	return 1;
}

sub fetch {
	my ( $self, $key, $default_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $val = $self->{$key};
	if ( defined $val ) {
		return $val;
	}
	else {
		if ( defined $default_or_block ) {
			if ( ref($default_or_block) eq 'CODE' ) {
				return $default_or_block->($key);
			}
			else {
				return $default_or_block;
			}
		}
		else {
			die 'KeyError: key not found: ' . $key;
		}
	}
}

sub find {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->detect(@_);
}

sub find_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->select($block);
}

sub find_index {
	my ( $self, $ary_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($ary_or_block) eq 'ARRAY' ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			if (   p_obj( @{$ary_or_block}[0] ) eq p_obj($key)
				&& p_obj( @{$ary_or_block}[0] ) eq p_obj($val) )
			{
				return $index;
			}
			$index++;
		}
	}
	elsif ( ref($ary_or_block) eq 'CODE' ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $ary_or_block->( $key, $val ) ) {
				return $index;
			}
			$index++;
		}
	}
	else {
		return undef;
	}

	return undef;
}

sub first {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = ra;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $n <= 0 ) {
				return $new_ary;
			}
			$new_ary->push( ra( $key, $val ) );
			$n--;
		}
		return $new_ary;
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			return ra( $key, $val );
		}
		return undef;
	}
}

sub flat_map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->collect_concat($block);
}

sub flatten {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra();
	while ( my ( $key, $val ) = each %$self ) {
		$new_ary->push( $key, $val );
	}

	if ( defined $n && $n >= 2 ) {
		$new_ary->flattenEx( $n - 1 );
	}

	return $new_ary;
}

sub grep {
	my ( $self, $pattern, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->grep( $pattern, $block );
}

sub group_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		my $group = $block->( $key, $val );
		if ( $new_hash->{$group} ) {
			$new_hash->{$group}->push( ra( $key, $val ) );
		}
		else {
			$new_hash->{$group} = ra;
			$new_hash->{$group}->push( ra( $key, $val ) );
		}
	}

	return $new_hash;
}

sub has_key {
	my ( $self, $key ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( keys %$self )->include($key);
}

sub include {
	my ( $self, $key ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->has_key($key);
}

sub inject {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->inject(@_);
}

sub has_member {
	my ( $self, $key ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->has_key($key);
}

sub has_value {
	my ( $self, $val ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( values %$self )->include($val);
}

sub inspect {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return p_hash $self;
}

sub to_s {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->inspect;
}

sub invert {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		$new_hash->{$val} = $key;
	}

	return $new_hash;
}

sub keep_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( not $block->( $key, $val ) ) {
			delete $self->{$key};
		}
	}

	return $self;
}

sub key {
	my ( $self, $value ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( p_obj($value) eq p_obj($val) ) {
			return $key;
		}
	}

	return undef;
}

sub keys {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( keys %$self );
}

sub length {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( keys %$self );
}

sub size {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->length;
}

sub map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->collect($block);
}

sub max {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->max($block);
}

sub max_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->max_by($block);
}

sub merge {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh($self);
	while ( my ( $key, $val ) = each %$other_hash ) {
		if ( defined $block && $self->{$key} && $other_hash->{$key} ) {
			$new_hash->{$key} =
			  $block->( $key, $self->{$key}, $other_hash->{$key} );
		}
		else {
			$new_hash->{$key} = $val;
		}
	}

	return $new_hash;
}

sub mergeEx {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$other_hash ) {
		if ( defined $block && $self->{$key} && $other_hash->{$key} ) {
			$self->{$key} =
			  $block->( $key, $self->{$key}, $other_hash->{$key} );
		}
		else {
			$self->{$key} = $val;
		}
	}

	return $self;
}

sub min {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->min($block);
}

sub min_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->min_by($block);
}

sub minmax {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->minmax($block);
}

sub minmax_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->minmax_by($block);
}

sub has_none {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 0 if ( $block->( $key, $val ) );
		}
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			return 0;
		}
	}

	return 1;
}

sub has_one {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			$count++;
			return 0 if ( $count > 1 );
		}
	}

	return $count == 1 ? 1 : 0;
}

sub partition {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = ra;
	my $true_ary  = ra;
	my $false_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$true_ary->push( ra( $key, $val ) );
		}
		else {
			$false_ary->push( ra( $key, $val ) );
		}
	}
	$new_ary->push( $true_ary, $false_ary );

	return $new_ary;
}

sub update {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->merge( $other_hash, $block );
}

sub updateEx {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->mergeEx( $other_hash, $block );
}

sub rassoc {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( $obj eq $val ) {
			return ra( $key, $val );
		}
	}

	return undef;
}

sub reduce {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->inject(@_);
}

sub reject {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh($self);
	while ( my ( $key, $val ) = each %$new_hash ) {
		if ( $block->( $key, $val ) ) {
			delete $new_hash->{$key};
		}
	}

	return $new_hash;
}

sub rejectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = $self->size;
	$self->delete_if($block);

	if ( $self->size == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

sub reverse_each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->reverse_each($block);
}

sub replace {
	my ( $self, $other_hash ) = @_;
	ref($self) eq __PACKAGE__ or die;

	%$self = %$other_hash;

	return $self;
}

sub select {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_ary->push( ra( $key, $val ) );
		}
	}

	return $new_ary;
}

sub selectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_hash->{$key} = $val;
		}
	}

	if ( $new_hash->size == $self->size ) {
		return undef;
	}
	else {
		%$self = %$new_hash;
		return $new_hash;
	}
}

sub shift {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		my $new_ary = ra( $key, $val );
		delete $self->{$key};
		return $new_ary;
	}

	return undef;
}

sub slice_before {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->slice_before(@_);
}

sub store {
	my ( $self, $key, $val ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$self->{$key} = $val;

	return $val;
}

sub take {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = ra;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $n <= 0 ) {
				return $new_ary;
			}
			$new_ary->push( ra( $key, $val ) );
			$n--;
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

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_ary->push( ra( $key, $val ) );
		}
		else {
			return $new_ary;
		}
	}

	return $new_ary;
}

sub to_a {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_array = ra();
	while ( my ( $key, $val ) = each %$self ) {
		my $pair = ra();
		$pair->push( $key, $val );
		$new_array->push($pair);
	}

	return $new_array;
}

sub to_h {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self;
}

sub to_hash {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self;
}

sub values_at {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_array = ra();
	for my $key (@_) {
		$new_array->push( $self->{$key} );
	}

	return $new_array;
}

sub zip {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->zip(@_);
}

if ( __FILE__ eq $0 ) {
	p rh( 1 => 2, 3 => 4 )->eql( { 1 => 2, 3 => 4 } );
}

1;
__END__;
