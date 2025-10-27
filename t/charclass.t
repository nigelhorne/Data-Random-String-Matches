use strict;
use warnings;

use Test::Most;
use Data::Random::String::Matches 'generate_match';

my %cases = (
    qr/^[A-Z\]]{5}$/     => 'contains ] or uppercase letters',
    qr/^[a\-z]{4}$/      => 'may include - or lowercase',
    qr/^[A-F\d]{6}$/     => 'includes digits',
    qr/^[\\]{3}$/        => 'escaped backslash',
);

for my $re (keys %cases) {
	my $s = generate_match($re);
	like($s, qr/$re/, "Generated '$s' matches $re ($cases{$re})");
}

done_testing();
