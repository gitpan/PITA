package PITA::Guest::Driver::Image;

# Provides a base class for PITA Guests that are system images.
# For example, Qemu, VMWare, etc

use strict;
use base 'PITA::Guest::Driver';
use Carp         ();
use Params::Util '_POSINT';
use Config::Tiny ();
use PITA::Guest::SupportServer ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Check we got an image
	unless ( $self->image ) {
		Carp::croak("Did not provide the location of the image_file");
	}
	unless ( -f $self->image and -r _ ) {
		Carp::croak($self->image . ": image does not exist, or cannot be read");
	}

	# How much memory to use
	$self->{memory} = 256 unless $self->memory;
	unless ( _POSINT($self->memory) ) {
		Carp::croak("Invalid memory amount (in meg) '" . $self->memory . "'");
	}

	# Snapshot should be a binary value, defaulting to true. (SURE ABOUT THAT?)
	$self->{snapshot} = 1 unless defined $self->snapshot;
	$self->{snapshot} = !! defined $self->{snapshot};

	# Create the support server object
	unless ( $self->support_server ) {
		$self->{support_server} = PITA::Guest::SupportServer->new(
			LocalAddr => $self->support_server_addr,
			LocalPort => $self->support_server_port,
			expected  => $self->request_id,
			directory => $self->support_server_dir,
			);
	}
	unless ( $self->support_server ) {
		Carp::croak("Failed to create PITA::Guest::SupportServer");
	}

	$self;
}

sub image {
	$_[0]->{image};
}

sub memory {
	$_[0]->{memory};
}

sub snapshot {
	$_[0]->{snapshot};
}

sub support_server {
	$_[0]->{support_server};
}

sub support_server_addr {
	$_[0]->support_server
		? $_[0]->support_server->LocalAddr
		: $_[0]->{support_server_addr};
}

sub support_server_port {
	$_[0]->support_server
		? $_[0]->support_server->LocalPort
		: $_[0]->{support_server_port};
}

sub support_server_dir {
	$_[0]->support_server
		? $_[0]->support_server->directory
		: $_[0]->{support_server_dir};
}

sub support_server_uri {
	my $self = shift;
	Carp::croak("Failed to generate result_uri for the scheme.conf");
}





#####################################################################
# PITA::Guest::Driver Methods

sub prepare {
	my $self = shift;
	$self->SUPER::prepare(@_);

	# Generate the scheme.conf into the tempdir
	$self->prepare_scheme_conf;

	# Copy the test package into the tempdir
	$self->prepare_package;

	1;
}

sub execute {
	my $self = shift;

	# Start the Result Server
	$self->support_server->background;

	# Now boot the image
	$self->execute_image;
}





#####################################################################
# PITA::Guest:Driver::Image Methods

sub prepare_scheme_conf {
	my $self = shift;

	# Create the basic Config::Tiny object
	my $scheme_conf = $self->request->__as_Config_Tiny;

	# Save the config file as scheme.conf
	my $scheme_file = File::Spec->catfile( $self->tempdir, 'scheme.conf' );
	unless ( $scheme_conf->write( $scheme_file ) ) {
		Carp::croak("Failed to write config to $scheme_file");
	}

	# Create the image.conf config file
	my $image_conf = Config::Tiny->new;
	$image_conf->{_} = {
		class      => 'PITA::Image::Manager',
		version    => '0.01',
		server_uri => $self->support_server_uri,
		};
	$image_conf->{task} = {
		task   => 'Test',
		job_id => $self->request_id,
		scheme => $self->request->scheme,
		path   => '',
		config => 'scheme.conf',
		};

	# Save the image.conf file
	my $image_file = File::Spec->catfile( $self->tempdir, 'image.conf' );
	unless ( $image_conf->write( $image_file ) ) {
		Carp::croak("Failed to write config to $image_file");
	}

	1;
}

# Copy in the test package from some other location
sub prepare_package {
	my $self = shift;

	# Copy to where?
	my $to = File::Spec->catfile(
		$self->tempdir, $self->request->filename,
		);
	unless ( File::Copy::copy( $self->request_file, $to ) ) {
		Carp::croak("Failed to copy in test package: $!");
	}

	1;
}

# Create the results server
sub prepare_results_server {
	my $self = shift;
	1;
}

sub execute_image {
	my $self = shift;
	die(ref($self) . " does not implement execute_image");
}

1;
