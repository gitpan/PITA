#!/usr/bin/perl -w

# Auto-generated testing for PITA

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

use PITA ();

use Test::More tests => 29;

# =begin testing SETUP 3
use_ok( 'Data::GUID'           );
use_ok( 'Params::Util', ':ALL' );
use_ok( 'PITA::Guest::Storage' );



# =begin testing _UUID 27
{
# Check good values
my @good_uuids = (
	'4162F712-1DD2-11B2-B17E-C09EFE1DC403',
	Data::GUID->new->as_string,
	Data::GUID->new->as_string,
	Data::GUID->new,
	);
foreach my $good ( @good_uuids ) {
	my $rv = eval { Data::GUID->from_string($good) };
	is( $@, '', "->from_string($good) does not throw an error" );
	isa_ok( $rv, 'Data::GUID' );
}

# Check again against the _UUID function
foreach my $good ( @good_uuids ) {
	isa_ok( PITA::Guest::Storage::_GUID($good), 'Data::GUID' );
}

# Check bad values
my @bad_uuids = (
	undef, '', ' ', 1, 'a', 'abcd', \"",
	\"foo", [], {}, (sub { 1 }), *foo, *foo,
	'4162F712-1DD2-11B2-B17E-C09EFE1D',
	);
foreach my $bad ( @bad_uuids ) {
	is( PITA::Guest::Storage::_GUID($bad), undef, "_UUID(bad) returns undef" );
}
}


1;
