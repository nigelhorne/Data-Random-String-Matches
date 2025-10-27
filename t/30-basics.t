use strict;
use warnings;
use Test::Most;
use Data::Random::String::Matches 'generate_match';

my @cases = (
	qr/^[A-Z]{2}\d{2,4}[a-z]*$/,
	qr/^(foo|bar|baz)\d+$/,
	qr/^ab*c$/,
);

for my $re (@cases) {
	my $s = generate_match($re, 10);
	diag($s);
	like($s, $re, "Generated string '$s' matches $re");
}

done_testing();
