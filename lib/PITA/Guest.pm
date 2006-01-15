package PITA::Guest;

# A complete abstraction of a Guest

use 5.005;
use strict;
use base qw{Process}; # Process::YAML
use File::Spec     ();
use File::Basename ();
use PITA::XML      ();
use Params::Util   '_INSTANCE',
                   '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;

	# Get the Guest XML file name
	my $file  = shift;
	unless ( _STRING($file) and -f $file ) {
		Carp::croak('Did not provide a valid filename');
	}

	# Create the object
	my $self = bless {
		file     => $file,
		guestxml => PITA::XML::Guest->read($file),
		driver   => undef,
		}, $class;

	# Create the driver
	my $driver = 'PITA::Guest::Driver::' . $self->guestxml->driver;
	eval "require $driver"; die $@ if $@;
	$self->{driver} = $driver->new(
		guest => $self->guestxml,
		);

	$self;
}

sub file {
	$_[0]->{file};
}

sub guestxml {
	$_[0]->{guestxml};
}

sub discovered {
	$_[0]->guestxml->discovered;	
}

sub driver {
	$_[0]->{driver};
}





#####################################################################
# Main Methods

# Ping the Guest to see if it response
sub ping {
	$_[0]->driver->ping;
}

# Discover the platforms
sub discover {
	$_[0]->driver->discover;
}

# Execute a test and return a report object
sub test {
	my $self     = shift;
	my $filename = _STRING(shift);
	unless ( $filename and -f $filename and -r _ ) {
		Carp::croak('Did not provide a request file');
	}

	# Load the request object
	my $request = PITA::XML::Request->read($filename)
		or Carp::croak('Failed to load request file');

	# Locate the archive file
	### FIXME: If the <filename> tag can contain anything
	###        other than a raw filename, this code is not
	###        portable, and needs improving to split the
	###        <filename> first before appending.
	my $archive = File::Basename::dirname($filename);
	$archive = File::Spec->catfile( $archive, $request->filename );
	unless ( $archive and -f $archive and -r _ ) {
		Carp::croak('Failed to find archive, or insufficient permissions');
	}

	# Since we only have one platform in each Guest, use that
	# for now until we get a better selection method.
	my $platform = ($self->guestxml->platforms)[0];
	unless ( _INSTANCE($platform, 'PITA::XML::Platform') ) {
		Carp::croak('Could not autoselect a platform');
	}

	# Hand off the testing request to the driver
	$self->driver->test(
		request  => $request,
		platform => $platform,
		archive  => $archive,
		);
}

# Update the PITA::XML::Guest file
sub save {
	$_[0]->guestxml->write( $_[0]->file );
}

1;
