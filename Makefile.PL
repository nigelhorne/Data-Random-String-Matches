use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME		=> 'Data::Random::String::Matches',
	AUTHOR		=> q{Nigel Horne <njh@nigelhorne.com>},
	VERSION_FROM	=> 'lib/Data/Random/String/Matches.pm',
	ABSTRACT_FROM	=> 'lib/Data/Random/String/Matches.pm',
	((defined($ExtUtils::MakeMaker::VERSION) && ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	'LIBS' => [''],	# e.g., '-lm'
	'DEFINE' => '',	# e.g., '-DHAVE_SOMETHING'
	'INC' => '',	# e.g., '-I/usr/include/other'
	PL_FILES	=> {},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
	},
	EXE_FILES => ['bin/random-string'],
	TEST_REQUIRES => {
		'Test::Compile' => 0,
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		'strict' => 0,
		'warnings' => 0,
	}, PREREQ_PM => {
		'Carp' => 0,
		'ExtUtils::MakeMaker' => 6.64,	# Minimum version for TEST_REQUIRES
		'Params::Get' => 0.13,
	}, dist => $dist,
	clean		=> { FILES => 'Data-Random-String-Matches-*' },
	# META_ADD => {
		# provides => {}
	# },
	META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Data::Random::String::Matches',
			repository => {
				repository => 'https://github.com/nigelhorne/Data-Random-String-Matches',
				type => 'git',
				url => 'git://github.com/nigelhorne/Data-Random-String-Matches.git',
				web => 'https://github.com/nigelhorne/Data-Random-String-Matches',
				# license    => 'http://dev.perl.org/licenses/',
			}, bugtracker => {
				mailto => 'bug-Data-Random-String-Matches@rt.cpan.org',
				url => 'https://github.com/nigelhorne/Data-Random-String-Matches/issues',
				# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Random-String-Matches',
				web => 'https://github.com/nigelhorne/Data-Random-String-Matches/issues'
			}
		},
	},
	MIN_PERL_VERSION	=> '5.008'
);
