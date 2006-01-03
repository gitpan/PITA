#!/usr/bin/perl -w

# Compile-testing for PITA

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'lib'),
			catdir('blib', 'arch'),
			'lib',
			);
	}
}

use Test::More tests => 10;

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );

	# Only three use statements should be enough
	# to load all of the classes (for now).
	use_ok( 'PITA' );
	use_ok( 'PITA::Guest::Driver' );
	use_ok( 'PITA::Guest::Driver::Qemu' );
}

ok( $PITA::VERSION,         'PITA was loaded' );
ok( $PITA::Report::VERSION, 'PITA::Report was loaded' );

foreach my $c ( qw{
	PITA::Guest::Driver
	PITA::Guest::Driver::Image
	PITA::Guest::Driver::Qemu
	PITA::Guest::SupportServer
} ) {
	eval "is( \$PITA::VERSION, \$${c}::VERSION, '$c was loaded and versions match' );";
}

exit(0);
