package Data::Random::String::Matches;

use strict;
use warnings;

use Carp qw(croak);
use Params::Get;

our $VERSION = '0.01';

=head1 NAME

Data::Random::String::Matches - Generate random strings matching a regex

=head1 SYNOPSIS

    use Data::Random::String::Matches;

    # Create generator with regex and optional length
    my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/, 7);

    # Generate a matching string
    my $str = $gen->generate();
    print $str;  # e.g., "XYZ1234"

    # Alternation
    my $gen2 = Data::Random::String::Matches->new(qr/(cat|dog|bird)/);
    my $animal = $gen2->generate_smart();  # "cat", "dog", or "bird"

    # Backreferences
    my $gen3 = Data::Random::String::Matches->new(qr/(\w{3})-\1/);
    my $str3 = $gen3->generate_smart();  # e.g., "abc-abc"

    # Groups and quantifiers
    my $gen4 = Data::Random::String::Matches->new(qr/(ha){2,4}/);
    my $laugh = $gen4->generate_smart();  # "haha", "hahaha", or "hahahaha"

=head1 DESCRIPTION

This module generates random strings that match a given regular expression pattern.
It parses the regex pattern and intelligently builds matching strings, supporting
a wide range of regex features.

=head1 SUPPORTED REGEX FEATURES

=head2 Character Classes

=over 4

=item * Basic classes: C<[a-z]>, C<[A-Z]>, C<[0-9]>, C<[abc]>

=item * Negated classes: C<[^a-z]>

=item * Ranges: C<[a-zA-Z0-9]>

=item * Escape sequences in classes: C<[\d\w]>

=back

=head2 Escape Sequences

=over 4

=item * C<\d> - digit [0-9]

=item * C<\w> - word character [a-zA-Z0-9_]

=item * C<\s> - whitespace

=item * C<\D> - non-digit

=item * C<\W> - non-word character

=item * C<\t>, C<\n>, C<\r> - tab, newline, carriage return

=back

=head2 Quantifiers

=over 4

=item * C<{n}> - exactly n times

=item * C<{n,m}> - between n and m times

=item * C<{n,}> - n or more times

=item * C<+> - one or more (1-5 times)

=item * C<*> - zero or more (0-5 times)

=item * C<?> - zero or one

=back

=head2 Grouping and Alternation

=over 4

=item * C<(...)> - capturing group

=item * C<(?:...)> - non-capturing group

=item * C<|> - alternation (e.g., C<cat|dog|bird>)

=item * C<\1>, C<\2>, etc. - backreferences

=back

=head2 Other

=over 4

=item * C<.> - any character (printable ASCII)

=item * Literal characters

=item * C<^> and C<$> anchors (stripped during parsing)

=back

=head1 LIMITATIONS

=over 4

=item * Lookaheads and lookbehinds are not supported

=item * Named groups are not supported

=item * Possessive quantifiers (C<*+>, C<++>) are not supported

=item * Unicode properties (C<\p{}>) are not supported

=item * Some complex nested patterns may not work correctly

=back

=head1 EXAMPLES

    # Email-like pattern
    my $gen = Data::Random::String::Matches->new(qr/[a-z]+@[a-z]+\.com/);

    # API key pattern
    my $gen = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);

    # Phone number
    my $gen = Data::Random::String::Matches->new(qr/\d{3}-\d{3}-\d{4}/);

    # Repeated pattern
    my $gen = Data::Random::String::Matches->new(qr/(\w{4})-\1/);

=head1 METHODS

=head2 new($regex, $length)

Creates a new generator. C<$regex> can be a compiled regex (qr//) or a string.
C<$length> is optional and defaults to 10 (used for fallback generation).

=cut

sub new {
	my ($class, $regex, $length) = @_;

	croak "Regex pattern is required" unless defined $regex;

	# Convert string to regex if needed
	my $regex_obj = ref($regex) eq 'Regexp' ? $regex : qr/$regex/;

	my $self = {
		regex	 => $regex_obj,
		regex_str => "$regex",
		length	=> $length || 10,
		backrefs	=> {},  # Store backreferences
	};

	return bless $self, $class;
}

=head2 generate($max_attempts)

Generates a random string matching the regex. First tries smart parsing, then
falls back to brute force if needed. Tries up to C<$max_attempts> times
(default 1000) before croaking.

=cut

sub generate {
	my ($self, $max_attempts) = @_;
	$max_attempts //= 1000;

	my $regex = $self->{regex};
	my $length = $self->{length};

	# First try the smart approach
	my $str = eval { $self->_build_from_pattern($self->{regex_str}) };
	if (defined $str && $str =~ /^$regex$/) {
		return $str;
	}

	# If smart approach failed, show warning in debug mode
	if ($ENV{DEBUG_REGEX_GEN} && $@) {
		warn "Smart generation failed: $@\n";
	}

	# Fall back to brute force with character set matching
	for (1 .. $max_attempts) {
		$str = $self->_random_string_smart($length);
		return $str if $str =~ /^$regex$/;
	}

	croak "Failed to generate matching string after $max_attempts attempts. Pattern: $self->{regex_str}";
}

sub _random_string_smart {
	my ($self, $len) = @_;

	my $regex_str = $self->{regex_str};

	# Detect common patterns and generate appropriate characters
	my @chars;

	if ($regex_str =~ /\\d/ || $regex_str =~ /\[0-9\]/ || $regex_str =~ /\[\^[^\]]*[A-Za-z]/) {
		# Digit patterns
		@chars = ('0'..'9');
	} elsif ($regex_str =~ /\[A-Z\]/ || $regex_str =~ /\[A-Z[^\]]*\]/) {
		# Uppercase patterns
		@chars = ('A'..'Z');
	} elsif ($regex_str =~ /\[a-z\]/ || $regex_str =~ /\[a-z[^\]]*\]/) {
		# Lowercase patterns
		@chars = ('a'..'z');
	} elsif ($regex_str =~ /\\w/ || $regex_str =~ /\[a-zA-Z0-9_\]/) {
		# Word characters
		@chars = ('a'..'z', 'A'..'Z', '0'..'9', '_');
	} else {
		# Default to printable ASCII
		@chars = map { chr($_) } (33 .. 126);
	}

	my $str = '';
	$str .= $chars[int(rand(@chars))] for (1 .. $len);

	return $str;
}

=head2 generate_smart()

Parses the regex and builds a matching string directly. Faster and more reliable
than brute force, but may not handle all edge cases.

=cut

sub generate_smart {
	my $self = $_[0];
	return $self->_build_from_pattern($self->{regex_str});
}

sub _build_from_pattern {
	my ($self, $pattern) = @_;

	# Reset backreferences for each generation
	$self->{backrefs} = {};
	$self->{group_counter} = 0;

	# Remove regex delimiters and modifiers
	# Handle (?^:...), (?i:...), (?-i:...) etc
	$pattern =~ s/^\(\?\^?[iumsx-]*:(.*)\)$/$1/;
	$pattern =~ s/^\^//;
	$pattern =~ s/\$//;

	return $self->_parse_sequence($pattern);
}

sub _parse_sequence {
	my ($self, $pattern) = @_;

	my $result = '';
	my $i = 0;
	my $len = length($pattern);

	while ($i < $len) {
		my $char = substr($pattern, $i, 1);

		if ($char eq '\\') {
			# Escape sequence
			$i++;
			my $next = substr($pattern, $i, 1);

			if ($next =~ /[1-9]/) {
				# Backreference
				my $ref_num = $next;
				if (exists $self->{backrefs}{$ref_num}) {
					$result .= $self->{backrefs}{$ref_num};
				} else {
					croak "Backreference \\$ref_num used before group defined";
				}
			} elsif ($next eq 'd') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { int(rand(10)) });
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'w') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = ('a'..'z', 'A'..'Z', '0'..'9', '_');
					$chars[int(rand(@chars))];
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 's') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { ' ' });
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'D') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = map { chr($_) } grep { chr($_) !~ /\d/ } (33..126);
					$chars[int(rand(@chars))];
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 'W') {
				my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
					my @chars = map { chr($_) } grep { chr($_) !~ /\w/ } (33..126);
					$chars[int(rand(@chars))];
				});
				$result .= $generated;
				$i = $new_i;
			} elsif ($next eq 't') {
				$result .= "\t";
			} elsif ($next eq 'n') {
				$result .= "\n";
			} elsif ($next eq 'r') {
				$result .= "\r";
			} else {
				$result .= $next;
			}
			$i++;
		} elsif ($char eq '[') {
			# Character class
			my $end = $self->_find_matching_bracket($pattern, $i);
			croak "Unmatched [" if $end == -1;

			my $class = substr($pattern, $i+1, $end-$i-1);
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $end, sub {
				$self->_random_from_class($class);
			});
			$result .= $generated;
			$i = $new_i + 1;
		} elsif ($char eq '(') {
			# Group
			my $end = $self->_find_matching_paren($pattern, $i);
			croak "Unmatched (" if $end == -1;

			my $group_content = substr($pattern, $i+1, $end-$i-1);

			# Check for non-capturing group
			my $is_capturing = 1;
			if ($group_content =~ /^\?:/) {
				$is_capturing = 0;
				$group_content = substr($group_content, 2);
			}

			# Check for alternation
			my $generated;
			if ($group_content =~ /\|/) {
				$generated = $self->_handle_alternation($group_content);
			} else {
				$generated = $self->_parse_sequence($group_content);
			}

			# Store backreference if capturing
			if ($is_capturing) {
				$self->{group_counter}++;
				$self->{backrefs}{$self->{group_counter}} = $generated;
			}

			# Handle quantifier after group
			my ($final_generated, $new_i) = $self->_handle_quantifier($pattern, $end, sub { $generated });
			$result .= $final_generated;
			$i = $new_i + 1;
		} elsif ($char eq '.') {
			# Any character (except newline)
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub {
				my @chars = map { chr($_) } (33 .. 126);
				$chars[int(rand(@chars))];
			});
			$result .= $generated;
			$i = $new_i + 1;
		} elsif ($char eq '|') {
			# Alternation at top level - just return what we have
			# (This is handled by _handle_alternation for groups)
			last;
		} elsif ($char =~ /[+*?]/ || $char eq '{') {
			# Quantifier without preceding element - shouldn't happen in valid regex
			croak "Quantifier $char without preceding element";
		} elsif ($char =~ /[\w ]/) {
			# Literal character
			my ($generated, $new_i) = $self->_handle_quantifier($pattern, $i, sub { $char });
			$result .= $generated;
			$i = $new_i + 1;
		} else {
			# Other literal characters
			$result .= $char;
			$i++;
		}
	}

	return $result;
}

sub _handle_quantifier {
	my ($self, $pattern, $pos, $generator) = @_;

	my $next = substr($pattern, $pos + 1, 1);

	if ($next eq '{') {
		my $end = index($pattern, '}', $pos);
		my $quant = substr($pattern, $pos + 2, $end - $pos - 2);

		my $result = '';
		if ($quant =~ /^(\d+)$/) {
			# Exact: {n}
			$result .= $generator->() for (1 .. $1);
		} elsif ($quant =~ /^(\d+),(\d+)$/) {
			# Range: {n,m}
			my $count = $1 + int(rand($2 - $1 + 1));
			$result .= $generator->() for (1 .. $count);
		} elsif ($quant =~ /^(\d+),$/) {
			# Minimum: {n,}
			my $count = $1 + int(rand(5));
			$result .= $generator->() for (1 .. $count);
		}
		return ($result, $end);
	} elsif ($next eq '+') {
		# One or more
		my $count = 1 + int(rand(5));
		my $result = '';
		$result .= $generator->() for (1 .. $count);
		return ($result, $pos + 1);
	} elsif ($next eq '*') {
		# Zero or more
		my $count = int(rand(6));
		my $result = '';
		$result .= $generator->() for (1 .. $count);
		return ($result, $pos + 1);
	} elsif ($next eq '?') {
		# Zero or one
		my $result = rand() < 0.5 ? $generator->() : '';
		return ($result, $pos + 1);
	} else {
		# No quantifier
		return ($generator->(), $pos);
	}
}

sub _handle_alternation {
	my ($self, $pattern) = @_;

	# Split on | but respect groups
	my @alternatives;
	my $current = '';
	my $depth = 0;

	for my $char (split //, $pattern) {
		if ($char eq '(') {
			$depth++;
			$current .= $char;
		} elsif ($char eq ')') {
			$depth--;
			$current .= $char;
		} elsif ($char eq '|' && $depth == 0) {
			push @alternatives, $current;
			$current = '';
		} else {
			$current .= $char;
		}
	}
	push @alternatives, $current if length($current);

	# Choose one alternative randomly
	my $chosen = $alternatives[int(rand(@alternatives))];
	return $self->_parse_sequence($chosen);
}

sub _find_matching_bracket {
	my ($self, $pattern, $start) = @_;

	my $depth = 0;
	for (my $i = $start; $i < length($pattern); $i++) {
		my $char = substr($pattern, $i, 1);
		if ($char eq '[' && ($i == $start || substr($pattern, $i-1, 1) ne '\\')) {
			$depth++;
		} elsif ($char eq ']' && substr($pattern, $i-1, 1) ne '\\') {
			$depth--;
			return $i if $depth == 0;
		}
	}
	return -1;
}

sub _find_matching_paren {
	my ($self, $pattern, $start) = @_;

	my $depth = 0;
	for (my $i = $start; $i < length($pattern); $i++) {
		my $char = substr($pattern, $i, 1);
		my $prev = $i > 0 ? substr($pattern, $i-1, 1) : '';

		if ($char eq '(' && $prev ne '\\') {
			$depth++;
		} elsif ($char eq ')' && $prev ne '\\') {
			$depth--;
			return $i if $depth == 0;
		}
	}
	return -1;
}

sub _random_from_class {
	my ($self, $class) = @_;

	my @chars;

	# Handle negation
	my $negate = 0;
	if (substr($class, 0, 1) eq '^') {
		$negate = 1;
		$class = substr($class, 1);
	}

	# Parse character class with escape sequences
	my $i = 0;
	while ($i < length($class)) {
		my $char = substr($class, $i, 1);

		if ($char eq '\\') {
			$i++;
			my $next = substr($class, $i, 1);
			if ($next eq 'd') {
				push @chars, ('0'..'9');
			} elsif ($next eq 'w') {
				push @chars, ('a'..'z', 'A'..'Z', '0'..'9', '_');
			} elsif ($next eq 's') {
				push @chars, (' ', "\t", "\n");
			} else {
				push @chars, $next;
			}
		} elsif ($i + 2 < length($class) && substr($class, $i+1, 1) eq '-') {
			# Range
			my $end = substr($class, $i+2, 1);
			push @chars, ($char .. $end);
			$i += 2;
		} else {
			push @chars, $char;
		}
		$i++;
	}

	if ($negate) {
		my %excluded = map { $_ => 1 } @chars;
		@chars = grep { !$excluded{$_} } map { chr($_) } (33 .. 126);
	}

	return @chars ? $chars[int(rand(@chars))] : 'X';
}

=head1 create_random_string

For consistency with L<Data::Random::String>.

=cut

sub create_random_string
{
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_);
	my $regex = $params->{'regex'};
	my $length = $params->{'length'};

	return $class->new($regex, $length)->generate();
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
