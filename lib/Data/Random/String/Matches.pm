package Data::Random::String::Matches;

use strict;
use warnings;

our $VERSION = '0.02';
use Exporter 'import';
our @EXPORT_OK = qw(random_match);

=head1 NAME

Data::Random::String::Matches - Generate random strings that match a Perl regex

=head1 SYNOPSIS

  use Data::Random::String::Matches qw(random_match);

  my $regex = qr/^(foo|bar)[A-Z]{2,3}\d+[a-z]?$/;
  my $str   = random_match($regex, 10);

  print "$str\n";  # e.g. "barXZ42a"

  # Or use the OO interface:
  my $gen = Data::Random::String::Matches->new(qr/^[A-Z]{3}\d{2}$/);
  print $gen->next, "\n";

=head1 DESCRIPTION

C<Data::Random::String::Matches> generates random strings that match a given
Perl-compatible regular expression. It supports basic regex features including
character classes, escapes, quantifiers, alternation, and grouping.

This can be useful for testing, fuzzing, or generating synthetic datasets.

=head1 FUNCTIONS

=head2 random_match( $regex [, $target_length ] )

Returns a random string that matches the given regex. Optionally aims for the
given length.

=cut

# -------------------------------------------------------------------------
# Functional interface
# -------------------------------------------------------------------------

sub random_match {
    my ($regex, $target_length) = @_;
    my $self = __PACKAGE__->new($regex);
    return $self->generate($target_length);
}

# -------------------------------------------------------------------------
# Object-oriented interface
# -------------------------------------------------------------------------

sub new {
    my ($class, $regex) = @_;
    die "Regex required" unless defined $regex;

    my $self = bless {}, $class;
    $regex =~ s/^\^//;  # ignore anchors
    $regex =~ s/\$$//;
    $self->{regex}   = $regex;
    $self->{pattern} = _parse_regex($regex);
    return $self;
}

sub regex { shift->{regex} }

sub next    { shift->generate(@_) }
sub generate {
    my ($self, $target_length) = @_;
    my $regex   = $self->{regex};
    my $pattern = $self->{pattern};

    my $str = _generate_from_ast($pattern, $target_length);

    if (defined $target_length) {
        $str = substr($str, 0, $target_length);
        for (1..1000) {
            return $str if $str =~ /^$regex$/;
            $str = _generate_from_ast($pattern, $target_length);
            $str = substr($str, 0, $target_length);
        }
        die "Could not generate a valid string of length $target_length for $regex\n";
    }

    return $str;
}

# -------------------------------------------------------------------------
# Internal: parser builds a simple AST
# -------------------------------------------------------------------------

sub _parse_regex {
    my ($regex) = @_;
    my @stack = [[]];
    my $group = $stack[-1];

    while (length $regex) {
        if ($regex =~ s/^\((?!\?)(.*?)\)//s) {
            push @$group, _parse_regex($1);
        }
        elsif ($regex =~ s/^\|//) {
            push @stack, [];
            $group = $stack[-1];
        }
        elsif ($regex =~ s/^(\[.*?\]|\\?.|\.)//s) {
            my $atom = $1;
            if ($regex =~ s/^(\{[0-9]+(?:,[0-9]+)?\}|[+*?])//) {
                push @$group, [$atom, $1];
            } else {
                push @$group, [$atom, ''];
            }
        }
        else {
            last;
        }
    }

    return @stack > 1 ? { alt => [ @stack ] } : { seq => $stack[0] };
}

# -------------------------------------------------------------------------
# Internal: generator walks AST recursively
# -------------------------------------------------------------------------

sub _generate_from_ast {
    my ($node, $target_length) = @_;

    if (exists $node->{alt}) {
        my $choice = $node->{alt}[ rand @{ $node->{alt} } ];
        return join '', map { _generate_from_atom(@$_) } @$choice;
    }
    elsif (exists $node->{seq}) {
        my $str = '';
        for my $part (@{ $node->{seq} }) {
            if (ref($part->[0]) eq 'HASH') {
                $str .= _generate_from_ast($part->[0], $target_length);
            } else {
                $str .= _generate_from_atom(@$part);
            }
        }
        return $str;
    }
    return '';
}

# -------------------------------------------------------------------------
# Internal: quantifier expansion
# -------------------------------------------------------------------------

sub _quant_to_count {
    my ($quant) = @_;
    return 1 unless $quant;
    return int(rand(2)) if $quant eq '?';
    return int(rand(5)) if $quant eq '*';
    return 1 + int(rand(4)) if $quant eq '+';
    if ($quant =~ /^\{(\d+)(?:,(\d+))?\}$/) {
        my ($min, $max) = ($1, defined $2 ? $2 : $1);
        $max = $min + 4 if $max < $min;
        return $min + int(rand($max - $min + 1));
    }
    return 1;
}

# -------------------------------------------------------------------------
# Internal: atom expansion
# -------------------------------------------------------------------------

sub _generate_from_atom {
    my ($atom, $quant) = @_;
    my $repeat = _quant_to_count($quant);
    my $out = '';

    for (1 .. $repeat) {
        if ($atom =~ /^\[([^\]]+)\]$/) {
            my @set;
            my $inside = $1;
            while ($inside =~ /(.)(?:-(.))?/g) {
                if (defined $2) { push @set, ($1 .. $2) }
                else { push @set, $1 }
            }
            $out .= $set[rand @set];
        }
        elsif ($atom eq '\\d') { $out .= int(rand(10)) }
        elsif ($atom eq '\\w') { $out .= (('a'..'z','A'..'Z',0..9,'_')[rand 63]) }
        elsif ($atom eq '\\s') { $out .= (' ', "\t")[rand 2] }
        elsif ($atom eq '.')   { $out .= ('a'..'z')[rand 26] }
        else {
            $atom =~ s/^\\//;
            $out .= $atom;
        }
    }
    return $out;
}

1;

__END__

=head1 OO INTERFACE

=head2 new( $regex )

Creates a new generator object.

=head2 next

Alias for C<generate>.

=head2 generate( [ $target_length ] )

Generates a random string that matches the stored regex.

=head2 regex

Returns the regex used for generation.

=head1 LIMITATIONS

This module supports a practical subset of Perl regex syntax:
basic literals, character classes, escapes, quantifiers, groups,
and alternation. It does not yet support lookahead, backreferences,
or nested alternation.

=head1 AUTHOR

Nigel Horne, C<< <nhorne at cpan.org> >>

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

