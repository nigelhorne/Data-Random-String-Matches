#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

use_ok('Data::Random::String::Matches');

like(Data::Random::String::Matches->create_random_string(length => 10, regex => '^\d{2}$'), qr/^\d{2}$/, 'generated string is 2 digits');

done_testing();
