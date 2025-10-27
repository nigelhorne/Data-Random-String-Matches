package Data::Random::String::Matches;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = ('generate_match');

our $VERSION = '0.04';

=head1 NAME

Data::Random::String::Matches - Generate random strings that match a regex

=head1 SYNOPSIS

  use Data::Random::String::Matches 'generate_match';

  my $str = generate_match(qr/^[A-Z]{2}\d{3}[a-z]+$/);
  print "$str\n";  # e.g. "XZ483bcz"

=head1 DESCRIPTION

This module generates random strings that match a given Perl regular expression.
It supports literals, character classes (including escaped chars), quantifiers,
grouping, alternation, and common escapes like C<\d>, C<\w>, C<\s>, and C<.>.

=cut

sub generate_match {
    my ($regex, $target_length) = @_;

    my $re_str = "$regex";
    $re_str =~ s/^\(\?\^[^:]*://;   # remove (?^: prefix from qr// stringification
    $re_str =~ s/\)$//;             # remove closing )

    # Strip anchors (^, $)
    $re_str =~ s/^\^//;
    $re_str =~ s/\$$//;

    my $ast = _parse_regex($re_str);
    my $result = _generate_from_ast($ast, $target_length);

    # Safely compile the regex
    my $compiled = eval { qr/$re_str/ };
    die "Invalid regex: $re_str ($@)" if $@ || !$compiled;

    for (1..500) {
        return $result if $result =~ $compiled;
        $result = _generate_from_ast($ast, $target_length);
    }
    die "Could not generate valid string for regex: $re_str\n";
}

# --- Recursive descent parser ---
sub _parse_regex {
    my ($regex) = @_;
    my @tokens = _tokenize($regex);
    return _parse_alternation(\@tokens);
}

sub _parse_alternation {
    my ($tokens) = @_;
    my @branches;

    push @branches, _parse_sequence($tokens);
    while (@$tokens && $tokens->[0] eq '|') {
        shift @$tokens;
        push @branches, _parse_sequence($tokens);
    }

    return @branches > 1 ? { type => 'alt', branches => \@branches } : $branches[0];
}

sub _parse_sequence {
    my ($tokens) = @_;
    my @group;

    while (@$tokens && $tokens->[0] ne ')' && $tokens->[0] ne '|') {
        my $atom = _parse_atom($tokens);
        my $quant = '';
        if (@$tokens && $tokens->[0] =~ /^(?:[*+?]|\{\d+(?:,\d+)?\})$/) {
            $quant = shift @$tokens;
        }
        push @group, [$atom, $quant];
    }

    return { type => 'seq', items => \@group };
}

sub _parse_atom {
    my ($tokens) = @_;
    my $t = shift @$tokens // '';
    return _parse_group($tokens) if $t eq '(';
    return { type => 'charclass', chars => _parse_charclass($1) } if $t =~ /^\[(.*?)\]$/;
    return { type => 'escape', value => $t } if $t =~ /^\\/;
    return { type => 'dot' } if $t eq '.';
    return { type => 'lit', value => $t };
}

sub _parse_group {
    my ($tokens) = @_;
    my $node = _parse_alternation($tokens);
    shift @$tokens if @$tokens && $tokens->[0] eq ')';
    return { type => 'group', inner => $node };
}

# --- Tokenizer ---
sub _tokenize {
    my ($regex) = @_;
    my @tokens;

    while ($regex =~ /
        (\\[dws])            | # common escapes
        (\\.)                | # any escaped char
        (\[[^\]]+\])         | # character class
        (\{[0-9]+(?:,[0-9]+)?\}) | # quantifier
        ([*+?()|.])          | # operators
        ([^\[\]\\*+?()|{}]+)   # literal run
    /xg) {
        push @tokens, grep { defined && length } ($1, $2, $3, $4, $5, $6);
    }

    return @tokens;
}

# --- Character class parser (with escaped chars and ranges) ---
sub _parse_charclass {
    my ($inside) = @_;
    my @chars;
    my @tokens;

    my $negated = ($inside =~ s/^\^//);

    while ($inside =~ /(\\.|-|(?!\\).)/g) {
        push @tokens, $1;
    }

    for (my $i = 0; $i < @tokens; $i++) {
        my $c = $tokens[$i];

        if ($c eq '-' && @chars) {
            my $start = $chars[-1];
            my $end   = $tokens[$i+1];
            next unless defined $end;
            $end =~ s/^\\// if $end =~ /^\\/;
            pop @chars;
            push @chars, ($start .. $end);
            $i++;
            next;
        }

        $c =~ s/^\\// if $c =~ /^\\/;
        push @chars, $c;
    }

    if ($negated) {
        my @all = ('a'..'z', 'A'..'Z', 0..9, '_', '-', ' ');
        my %set = map { $_ => 1 } @chars;
        @chars = grep { !$set{$_} } @all;
    }

    return \@chars;
}

# --- Generation phase ---
sub _generate_from_ast {
    my ($node, $target_length) = @_;

    if ($node->{type} eq 'seq') {
	        my $out = '';
        for my $pair (@{ $node->{items} }) {
            my ($atom, $quant) = @$pair;

            # How many times to repeat this atom
            my $count = _quant_to_count($quant);

            # Repeat atom exactly count times
            for (1 .. $count) {
                if ($atom->{type} eq 'lit') {
                    $out .= $atom->{value};
                }
                else {
                    $out .= _generate_from_ast($atom, $target_length);
                last if defined $target_length && length($out) >= $target_length;
                }
            }
        }
        return $out;
    }

    if ($node->{type} eq 'alt') {
        my $branch = $node->{branches}[ rand @{ $node->{branches} } ];
        return _generate_from_ast($branch, $target_length);
    }

    if ($node->{type} eq 'group') {
        return _generate_from_ast($node->{inner}, $target_length);
    }

    if ($node->{type} eq 'lit') {
        return $node->{value};
    }

    if ($node->{type} eq 'dot') {
        return ('a'..'z', 'A'..'Z', 0..9, '_')[rand 63];
    }

    if ($node->{type} eq 'escape') {
        return _generate_escape($node->{value});
    }

    if ($node->{type} eq 'charclass') {
        return $node->{chars}[ rand @{ $node->{chars} } ];
    }

    return '';
}

# --- Quantifier interpretation ---
sub _quant_to_count {
    my ($quant) = @_;
    return 1 unless defined $quant && length $quant;

    if ($quant eq '?') {
        return int(rand(2));           # 0 or 1
    }
    if ($quant eq '*') {
        return int(rand(11));          # 0..10
    }
    if ($quant eq '+') {
        return 1 + int(rand(10));     # 1..10
    }

    if ($quant =~ /^\{(\d+)(?:,(\d+))?\}$/) {
        my ($min, $max) = ($1, $2 // $1);
        $max = $min if $max < $min;
        return $min + int(rand($max - $min + 1));
    }

    return 1;
}


sub _generate_escape {
    my ($esc) = @_;
    return int(rand(10)) if $esc eq '\\d';
    return ('a'..'z', 'A'..'Z', 0..9, '_')[rand 63] if $esc eq '\\w';
    return (' ', "\t")[rand 2] if $esc eq '\\s';
    $esc =~ s/^\\//;
    return $esc;
}

1;

__END__

=head1 AUTHOR

Nigel Horne

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

