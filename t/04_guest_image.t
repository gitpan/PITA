#!/usr/bin/perl -w

# Testing PITA::Guest

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

# Until prove fixes it
local $ENV{PERL5LIB} = join ':', catdir('blib', 'lib'), catdir('blib', 'arch'), 'lib';

use Test::More tests => 97;

use PITA ();
use File::Remove 'remove';

sub compare_guests {
	my ($left, $right, $message) = @_;
	delete $left->driver->{injector_dir};
	delete $left->driver->{workarea};
	delete $right->driver->{injector_dir};
	delete $right->driver->{workarea};
	is_deeply( $left, $right, $message );		
}

# Find the test guest file
my $image_test = catfile( 't', 'guests', 'image_test.pita' );
ok( -f $image_test, 'Found image_test.pita test file' );

# Set up the write test guest file
my $image_write = rel2abs(catfile( 't', 'guests', 'image_write.pita' ));
      if ( -f $image_write ) { remove( $image_write ) }
END { if ( -f $image_write ) { remove( $image_write ) } }
ok( ! -f $image_write, 'local_write.pita does not exist' );

# Find the test request file
my $simple_request = catfile( 't', 'requests', 'simple_request.pita' );
ok( -f $simple_request, 'Found simple request file' );
my $simple_module = catfile( 't', 'requests', 'PITA-Test-Dummy-Perl5-Make-1.01.tar.gz' );
ok( -f $simple_module, 'Found simple dist file' );





#####################################################################
# Prepare a common Request object

# Load a request object
my $request = PITA::XML::Request->read( $simple_request );
isa_ok( $request, 'PITA::XML::Request' );
my $tarball = $request->find_file( $simple_request );
ok( $tarball, 'Found tarball for request' );
ok( -f $tarball, 'Confirm that tarball exists' );
unless ( File::Spec->file_name_is_absolute( $tarball ) ) {
	$tarball = File::Spec->rel2abs( $tarball );
}
ok( -f $tarball, 'Confirm that tarball exists (absolute)' );
$request->file->{filename} = $tarball;

# Override the request id
$request->{id} = 1234;
is( $request->id, 1234, 'Request id is 1234' );





#####################################################################
# Working with a PITA::XML::Guest

# Load the raw PITA::XML::Guest directly
SCOPE: {
	my $xml = PITA::XML::Guest->read( $image_test );
	isa_ok( $xml, 'PITA::XML::Guest' );
	is( $xml->driver, 'Image::Test', '->driver is Local' );
	is( scalar($xml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $xml->platforms ], [], '->platforms(list) return ()'   );

	# Write the file for the write test
	ok( $xml->write( $image_write ), '->write returns true' );
	my $xml2 = PITA::XML::Guest->read( $image_write );
	isa_ok( $xml2, 'PITA::XML::Guest' );
	is_deeply( $xml2, $xml, 'local_empty matches local_write' );
}





#####################################################################
# Preparation

# Load a PITA::Guest for the image_test case and test the various prepares
my @working_dirs = ();
SCOPE: {
	my $guest = PITA::Guest->new( $image_test );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->file, $image_test, '->file returns the original filename' );
	isa_ok( $guest->guestxml,  'PITA::XML::Guest'              );
	is( $guest->discovered, '', '->discovered returns false'   );
	isa_ok( $guest->driver, 'PITA::Guest::Driver'              );
	isa_ok( $guest->driver, 'PITA::Guest::Driver::Image'       );
	isa_ok( $guest->driver, 'PITA::Guest::Driver::Image::Test' );
	isa_ok( $guest->driver->support_server, 'PITA::Guest::SupportServer' );
	is( scalar($guest->guestxml->platforms),    0,  '->platforms(scalar) returns 0' );
	is_deeply( [ $guest->guestxml->platforms ], [], '->platforms(list) return ()'   ); 

	# Check various working directories are created
	ok( -d $guest->driver->injector_dir, 'Driver injector directory is created' );
	ok( -d $guest->driver->support_server->directory,
		'Support Server directory exists' );

	# Save a copy for later
	@working_dirs = (
		$guest->driver->injector_dir,
		$guest->driver->support_server->directory,
		);

	# Check that we can prepare for a ping
	ok( $guest->driver->ping_prepare, '->driver->ping_prepare returns true' );
	my $injector = $guest->driver->injector_dir;
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( ! -d catfile( $injector, 'perl5lib' ), 'perl5lib dir not created' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Check that we can prepare for discovery
	ok( $guest->driver->discover_prepare, '->driver->discover_prepare returns true' );
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( -d catfile( $injector, 'perl5lib' ),   'perl5lib dir not created' );
	ok( -f catfile( $injector, 'perl5lib', 'PITA', 'Scheme.pm' ), 'PITA::Scheme found in perl5lib' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Check that we can prepare for a test
	ok( $guest->driver->test_prepare($request), '->driver->test_prepare returns true' );
	ok( -d $injector, 'Injector exists' );
	ok( -f catfile( $injector, 'image.conf' ), 'image.conf file created' );
	ok( -d catfile( $injector, 'perl5lib' ),   'perl5lib dir created' );
	ok( -f catfile( $injector, 'perl5lib', 'PITA', 'Scheme.pm' ), 'PITA::Scheme found in perl5lib' );
	ok( -f catfile( $injector, 'request-1234.pita' ), 'request-1234.pita file created' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	ok( scalar(no_upwards(readdir(INJECTOR))), 'Injector contains files' );
	ok( closedir( INJECTOR ), 'Closed injector' );

	# Flush the injector
	ok( $guest->driver->clean_injector, 'Cleaned injector' );
	ok( opendir( INJECTOR, $injector ), 'Opened injector for reading' );
	is( scalar(no_upwards(readdir(INJECTOR))), 0, 'Cleaned injector ok' );
	ok( closedir( INJECTOR ), 'Closed injector' );
}

sleep 1;

# Check all the various work directories are removed
ok( ! -d $working_dirs[0], 'Driver injector removed' );
ok( ! -d $working_dirs[1], 'Support Server directory exists' );





#####################################################################
# Test the ping method

SCOPE: {
	my $guest = PITA::Guest->new( $image_test );
	isa_ok( $guest, 'PITA::Guest' );

	# Ping the guest
	ok( $guest->ping, '->ping returns ok' );

	# Did everything happen as we expected?
	ok( $guest->driver->{_test}->{ss_pidfile}, 
		'Got the pidfile for the support server' );
	ok( $guest->driver->{_test}->{ss_started},
		'Support server started at the right time' );
	ok( $guest->driver->{_test}->{im_run},
		'Image Manager ran ok' );
	ok( $guest->driver->{_test}->{ss_stopped},
		'Support server stopped at the right time' );
}





#####################################################################
# Test the discover method

SCOPE: {
	my $guest = PITA::Guest->new( $image_test );
	isa_ok( $guest, 'PITA::Guest' );
	ok( $guest->driver->snapshot, 'Guest running in snapshot mode' );
	is( $guest->discovered, '', '->discovered is false' );

	# Discover the platforms
	ok( $guest->discover, '->discover returns ok' );

	# Did everything happen as we expected?
	ok( $guest->driver->{_test}->{ss_pidfile}, 
		'Got the pidfile for the support server' );
	ok( $guest->driver->{_test}->{ss_started},
		'Support server started at the right time' );
	ok( $guest->driver->{_test}->{im_run},
		'Image Manager ran ok' );
	ok( $guest->driver->{_test}->{im_report},
		'Image Manager reported ok' );
	ok( $guest->driver->{_test}->{ss_stopped},
		'Support server stopped at the right time' );

	# Is the guest now discovered?
	is( $guest->discovered, 1, '->discovered returns true' );
}

# Again, but with write-back
SCOPE: {
	# Load it
	my $guest = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );

	# Discover it
	is( $guest->discovered, '', '->discovered is false' );
	ok( $guest->discover, '->discover returns ok' );
	is( $guest->discovered, 1, '->discovered returns true' );

	# Save it
	ok( $guest->save, '->save returns true' );

	# Load it again
	my $guest2 = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->discovered, 1, 'Saved and reloaded guest remains discovered' );
}





#####################################################################
# Test the test method

SCOPE: {
	# Load the pre-discovered config
	my $guest = PITA::Guest->new( $image_write );
	isa_ok( $guest, 'PITA::Guest' );
	is( $guest->discovered, 1, '->discovered is true' );

	# Run the test
	my $rv = $guest->test( $simple_request );
	isa_ok( $rv, 'PITA::XML::Report' );

	# Did everything happen as we expected?
	ok( $guest->driver->{_test}->{ss_pidfile}, 
		'Got the pidfile for the support server' );
	ok( $guest->driver->{_test}->{ss_started},
		'Support server started at the right time' );
	ok( $guest->driver->{_test}->{im_run},
		'Image manager ran ok' );
	ok( $guest->driver->{_test}->{im_report},
		'Image manager reported' );
	ok( $guest->driver->{_test}->{ss_stopped},
		'Support server stopped at the right time' );

}

exit(0);
