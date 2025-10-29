# NAME

Data::Random::String::Matches - Generate random strings matching a regex

# SYNOPSIS

        use Data::Random::String::Matches;

        # Create a generator with regex and optional length
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

        # Unicode
        $gen = Data::Random::String::Matches->new(qr/\p{L}{5}/);

        # Named captures
        $gen = Data::Random::String::Matches->new(qr/(?<year>\d{4})-\k<year>/);

        # Possessive
        $gen = Data::Random::String::Matches->new(qr/\d++[A-Z]/);

        # Lookaheads
        $gen = Data::Random::String::Matches->new(qr/\d{3}(?=[A-Z])/);

        # Combined
        $gen = Data::Random::String::Matches->new(
                qr/(?<prefix>\p{Lu}{2})\d++\k<prefix>(?=[A-Z])/
        );

        # Consistency with Legacy software
        print Data::Random::String::Matches->create_random_string(length => 3, regex => '\d{3}'), "\n";

# DESCRIPTION

This module generates random strings that match a given regular expression pattern.
It parses the regex pattern and intelligently builds matching strings, supporting
a wide range of regex features.

# SUPPORTED REGEX FEATURES

## Character Classes

- Basic classes: `[a-z]`, `[A-Z]`, `[0-9]`, `[abc]`
- Negated classes: `[^a-z]`
- Ranges: `[a-zA-Z0-9]`
- Escape sequences in classes: `[\d\w]`

## Escape Sequences

- `\d` - digit \[0-9\]
- `\w` - word character \[a-zA-Z0-9\_\]
- `\s` - whitespace
- `\D` - non-digit
- `\W` - non-word character
- `\t`, `\n`, `\r` - tab, newline, carriage return

## Quantifiers

- `{n}` - exactly n times
- `{n,m}` - between n and m times
- `{n,}` - n or more times
- `+` - one or more (1-5 times)
- `*` - zero or more (0-5 times)
- `?` - zero or one

## Grouping and Alternation

- `(...)` - capturing group
- `(?:...)` - non-capturing group
- `|` - alternation (e.g., `cat|dog|bird`)
- `\1`, `\2`, etc. - backreferences

## Other

- `.` - any character (printable ASCII)
- Literal characters
- `^` and `$` anchors (stripped during parsing)

# LIMITATIONS

- Lookaheads and lookbehinds are not supported
- Named groups are not supported
- Possessive quantifiers (`*+`, `++`) are not supported
- Unicode properties (`\p{}`) are not supported
- Some complex nested patterns may not work correctly

# LIMITATIONS

- Lookaheads and lookbehinds ((?=...), (?!...)) are not supported
- Named groups ((?&lt;name>...)) are not supported
- Possessive quantifiers (\*+, ++) are not supported
- Unicode properties (\\p{L}, \\p{N}) are not supported
- Some complex nested patterns may not work correctly with smart parsing

# EXAMPLES

        # Email-like pattern
        my $gen = Data::Random::String::Matches->new(qr/[a-z]+@[a-z]+\.com/);

        # API key pattern
        my $gen = Data::Random::String::Matches->new(qr/^AIza[0-9A-Za-z_-]{35}$/);

        # Phone number
        my $gen = Data::Random::String::Matches->new(qr/\d{3}-\d{3}-\d{4}/);

        # Repeated pattern
        my $gen = Data::Random::String::Matches->new(qr/(\w{4})-\1/);

# METHODS

## new($regex, $length)

Creates a new generator. `$regex` can be a compiled regex (qr//) or a string.
`$length` is optional and defaults to 10 (used for fallback generation).

## generate($max\_attempts)

Generates a random string matching the regex. First tries smart parsing, then
falls back to brute force if needed. Tries up to `$max_attempts` times
(default 1000) before croaking.

## generate\_smart()

Parses the regex and builds a matching string directly. Faster and more reliable
than brute force, but may not handle all edge cases.

## generate\_many($count, $unique)

Generate a number of (possibly) unique strings for the regex

## create\_random\_string

For consistency with [Data::Random::String](https://metacpan.org/pod/Data%3A%3ARandom%3A%3AString).

    print Data::Random::String::Matches->create_random_string(length => 3, regex => '\d{3}'), "\n";

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
