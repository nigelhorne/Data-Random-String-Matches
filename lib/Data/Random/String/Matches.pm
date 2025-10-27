package Data::Random::String::Matches;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

sub new {
    my ($class, $regex, $length) = @_;
    
    croak "Regex pattern is required" unless defined $regex;
    
    # Convert string to regex if needed
    my $regex_obj = ref($regex) eq 'Regexp' ? $regex : qr/$regex/;
    
    my $self = {
        regex       => $regex_obj,
        regex_str   => "$regex",
        length      => $length || 10,
    };
    
    return bless $self, $class;
}

sub generate {
    my ($self, $max_attempts) = @_;
    $max_attempts //= 1000;
    
    my $regex = $self->{regex};
    my $length = $self->{length};
    
    # First try the smart approach
    my $str = eval { $self->_build_from_pattern($self->{regex_str}) };
    return $str if defined $str && $str =~ /^$regex$/;
    
    # Fall back to brute force with character set matching
    for (1 .. $max_attempts) {
        $str = $self->_random_string_smart($length);
        return $str if $str =~ /^$regex$/;
    }
    
    croak "Failed to generate matching string after $max_attempts attempts";
}

sub _random_string_smart {
    my ($self, $len) = @_;
    
    my $regex_str = $self->{regex_str};
    
    # Detect common patterns and generate appropriate characters
    my @chars;
    
    if ($regex_str =~ /^\[?\\d[\]\+\*\{\}]*$/ || $regex_str =~ /^\[0-9\]/) {
        # Digit patterns
        @chars = ('0'..'9');
    } elsif ($regex_str =~ /^\[?[A-Z][\]\+\*\{\}]*$/) {
        # Uppercase patterns
        @chars = ('A'..'Z');
    } elsif ($regex_str =~ /^\[?[a-z][\]\+\*\{\}]*$/) {
        # Lowercase patterns
        @chars = ('a'..'z');
    } elsif ($regex_str =~ /^\[?\\w[\]\+\*\{\}]*$/) {
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

sub generate_smart {
    my ($self) = @_;
    return $self->_build_from_pattern($self->{regex_str});
}

sub _build_from_pattern {
    my ($self, $pattern) = @_;
    
    # Remove regex delimiters and modifiers
    $pattern =~ s/^\(\?[\^iumsx-]*://;
    $pattern =~ s/^\^//;
    $pattern =~ s/\$$//;
    
    my $result = '';
    my $i = 0;
    my $len = length($pattern);
    
    while ($i < $len) {
        my $char = substr($pattern, $i, 1);
        
        if ($char eq '\\') {
            # Escape sequence
            $i++;
            my $next = substr($pattern, $i, 1);
            if ($next eq 'd') {
                $result .= int(rand(10));
            } elsif ($next eq 'w') {
                my @chars = ('a'..'z', 'A'..'Z', '0'..'9', '_');
                $result .= $chars[int(rand(@chars))];
            } elsif ($next eq 's') {
                $result .= ' ';
            } elsif ($next eq 'D') {
                my @chars = map { chr($_) } grep { chr($_) !~ /\d/ } (33..126);
                $result .= $chars[int(rand(@chars))];
            } elsif ($next eq 'W') {
                my @chars = map { chr($_) } grep { chr($_) !~ /\w/ } (33..126);
                $result .= $chars[int(rand(@chars))];
            } else {
                $result .= $next;
            }
        } elsif ($char eq '[') {
            # Character class
            my $end = index($pattern, ']', $i);
            croak "Unmatched [" if $end == -1;
            my $class = substr($pattern, $i+1, $end-$i-1);
            $result .= $self->_random_from_class($class);
            $i = $end;
        } elsif ($char eq '{') {
            # Quantifier - get the last character and repeat
            my $end = index($pattern, '}', $i);
            my $quant = substr($pattern, $i+1, $end-$i-1);
            my $last_char = chop($result);
            
            if ($quant =~ /^(\d+)$/) {
                # Exact: {n}
                $result .= $last_char x $1;
            } elsif ($quant =~ /^(\d+),(\d+)$/) {
                # Range: {n,m}
                my $count = $1 + int(rand($2 - $1 + 1));
                $result .= $last_char x $count;
            } elsif ($quant =~ /^(\d+),$/) {
                # Minimum: {n,}
                my $count = $1 + int(rand(5));
                $result .= $last_char x $count;
            }
            $i = $end;
        } elsif ($char eq '+') {
            # One or more - repeat last char 1-5 times
            my $last_char = chop($result);
            my $count = 1 + int(rand(5));
            $result .= $last_char x $count;
        } elsif ($char eq '*') {
            # Zero or more - repeat last char 0-5 times
            my $last_char = chop($result);
            my $count = int(rand(6));
            $result .= $last_char x $count;
        } elsif ($char eq '?') {
            # Zero or one - maybe remove last char
            chop($result) if rand() < 0.5;
        } elsif ($char eq '.') {
            # Any character (except newline)
            my @chars = map { chr($_) } (33 .. 126);
            $result .= $chars[int(rand(@chars))];
        } elsif ($char =~ /[a-zA-Z0-9 ]/) {
            # Literal character
            $result .= $char;
        } elsif ($char eq '|') {
            # Alternation - just take what we have
            last;
        }
        
        $i++;
    }
    
    return $result;
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
    
    # Parse character class
    if ($class =~ /^(\w)-(\w)$/) {
        # Simple range like a-z or 0-9
        @chars = ($1 .. $2);
    } elsif ($class =~ /([a-z])-([a-z])/ || $class =~ /([A-Z])-([A-Z])/ || $class =~ /([0-9])-([0-9])/) {
        # Range within larger class
        my $start = $1;
        my $end = $2;
        @chars = ($start .. $end);
        # Add other characters in class
        my $without_range = $class;
        $without_range =~ s/\w-\w//g;
        push @chars, split //, $without_range if $without_range;
    } else {
        # Individual characters
        @chars = split //, $class;
    }
    
    if ($negate) {
        my %excluded = map { $_ => 1 } @chars;
        @chars = grep { !$excluded{$_} } map { chr($_) } (33 .. 126);
    }
    
    return @chars ? $chars[int(rand(@chars))] : 'X';
}

1;

__END__

=head1 NAME

Data::Random::String::Matches - Generate random strings matching a regex

=head1 SYNOPSIS

    use Data::Random::String::Matches;
    
    # Create generator with regex and optional length
    my $gen = Data::Random::String::Matches->new(qr/[A-Z]{3}\d{4}/, 7);
    
    # Generate a matching string
    my $str = $gen->generate();
    print $str;  # e.g., "XYZ1234"
    
    # Use string pattern
    my $gen2 = Data::Random::String::Matches->new('[a-z]+@[a-z]+\.com', 20);
    my $email = $gen2->generate();

=head1 DESCRIPTION

This module generates random strings that match a given regular expression pattern.
It attempts to parse and build strings from the pattern, falling back to brute-force
generation when needed.

=head1 METHODS

=head2 new($regex, $length)

Creates a new generator. C<$regex> can be a compiled regex (qr//) or a string.
C<$length> is optional and defaults to 10.

=head2 generate($max_attempts)

Generates a random string matching the regex. First tries smart parsing, then
falls back to brute force if needed. Tries up to C<$max_attempts> times
(default 1000) before croaking.

=head2 generate_smart()

Alternative method that parses the regex and builds a matching string directly.
Supports common regex features including character classes, quantifiers, and
escape sequences.

=head1 SUPPORTED REGEX FEATURES

=over 4

=item * Character classes: [a-z], [A-Z], [0-9], [abc]

=item * Negated classes: [^a-z]

=item * Escape sequences: \d, \w, \s, \D, \W

=item * Quantifiers: {n}, {n,m}, {n,}, +, *, ?

=item * Dot: . (any character)

=item * Literal characters

=back

=head1 AUTHOR

Created for demonstration purposes.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
