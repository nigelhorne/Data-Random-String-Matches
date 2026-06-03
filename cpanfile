# Generated from Makefile.PL using makefilepl2cpanfile

requires 'perl', '5.014';

requires 'Carp';
requires 'ExtUtils::MakeMaker', '6.64';
requires 'Getopt::Long';
requires 'Params::Get', '0.13';
requires 'Pod::Usage';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
	requires 'File::Glob';
	requires 'File::Slurp';
	requires 'File::Temp';
	requires 'File::stat';
	requires 'IPC::Run3';
	requires 'IPC::System::Simple';
	requires 'JSON::MaybeXS';
	requires 'POSIX';
	requires 'Readonly';
	requires 'Test::Compile';
	requires 'Test::DescribeMe';
	requires 'Test::Most';
	requires 'Test::NoWarnings';
	requires 'strict';
	requires 'warnings';
};

on 'develop' => sub {
	requires 'Devel::Cover';
	requires 'Perl::Critic';
	requires 'Test::Pod';
	requires 'Test::Pod::Coverage';
};
