#!/usr/bin/perl

# Seeing as no proper image manager exists yet, fill in temporarily
# with a manual launch script.

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	require FindBin;
	$FindBin::Bin = $FindBin::Bin; # Avoid a warning
	chdir catdir( $FindBin::Bin, updir(), updir() );
	lib->import(
		catdir('blib', 'lib'),
		catdir('blib', 'arch'),
		'lib',
		);
}





#####################################################################
# Configuration

use File::HomeDir ();
use PITA::Guest::Driver::Qemu ();

# The package to test
my $filename = 'PITA-Test-Dummy-Perl5-Make-1.01.tar.gz';

# Test using a Qemu image in snapshot mode
my $driver   = 'PITA::Guest::Driver::Qemu';
my $snapshot = 1;
my $image    = catfile(
	File::HomeDir->my_home, 'images', 'debian-sarge.img'
	);

# Only 256 meg total on my test box
my $memory = 128;

# Where to copy in the package from
my $request_file = catfile(
	File::HomeDir->my_home, 'pita', 'releases', $filename,
	);
unless ( -f $request_file ) {
	die "Failed to find test package $request_file";
}

# Running directory for the results server
my $resultsdir = catfile( curdir(), 'resultserver' );
unless ( -d $resultsdir ) {
	mkdir $resultsdir or die "Failed to create $resultsdir";
}





#####################################################################
# The Main Process

use Params::Util ':ALL';
use PITA::Report ();

# Create the driver object
my $qemu = $driver->new(
	# PITA::Guest::Driver Params
	request_id         => 1234,
	request_file       => $request_file,
	request            => {
		scheme    => 'perl5.make',
		distname  => 'PITA-Test-Dummy-Perl5-Make',
		filename  => $filename,
		md5sum    => 'd7aa6a943cd762ac9c18d57653653e31',
		authority => 'cpan',
		authpath  => '/authors/id/A/AD/ADAMK/PITA-Test-Dummy-Perl5-Make-1.01.tar.gz',
		},

	# PITA::Guest::Driver::Image Params
	image              => $image,
	snapshot           => $snapshot,
	memory             => $memory,
	support_server_dir => $resultsdir,

	# PITA::Guest::Driver::Qemu Params
	### qemu_bin => let the driver locate the binary itself
	);

# Prepare for the testing run
$qemu->prepare;

$qemu->execute;

1;
