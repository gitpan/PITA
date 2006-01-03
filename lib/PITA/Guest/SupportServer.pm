package PITA::Guest::SupportServer;

=pod

=head1 NAME

PITA::Guest::SupportServer - Provides support services via HTTP for Guest images.

=head1 DESCRIPTION

Because each testing image is a black box with potentially different and
unusual properties, a consistent method is needed to pull in any additional
files needed by the image (such as CPAN distributions) and get the result
reports out of the image and return them to the PITA Host.

One common capability all testing images have is the ability to connect
out to the Host machine over the network. Because of this, we can provide
whatever services are necesary for the installation by creating a custom
HTTP server that accepts and proxies GET requests for CPAN files, and
accepts results via specially-formed PUT requests.

This class implements such a web server.

I<Note: At the present time, only the PUT half of the functionality has
actually been completed>

=head1 METHODS

=cut

use strict;
use Carp          ();
use File::Spec    ();
use File::Flock   ();
use Params::Util  '_POSINT';
use URI           ();
use HTTP::Daemon  ();
use HTTP::Status  ();
use HTTP::Request ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the params
	unless ( $self->{LocalAddr} ) {
		Carp::croak("SupportServer 'LocalAddr' was not provided");
	}
	if ( $self->{LocalPort} and ! _POSINT($self->{LocalPort}) ) {
		Carp::croak("SupportServer 'LocalPort' was invalid");
	}
	unless ( _POSINT($self->{expected}) ) {
		Carp::croak("SupportServer 'expected' Report id not provided");
	}
	unless ( $self->{directory} ) {
		Carp::croak("SupportServer 'directory' for saving not provided");
	}
	unless ( -d $self->{directory} and -w _ ) {
		Carp::croak("SupportServer 'directory' is not a writable directory");
	}

	# Internally, make the expected a list
	$self->{expected} = [ $self->{expected} ];

	# Create the daemon
	$self->{daemon} = HTTP::Daemon->new(
		LocalAddr => $self->LocalAddr,
		$self->LocalPort
			? ( LocalPort => $self->LocalPort )
			: (),
		);

	# If we didn't supply a LocalPort, we should know it now
	$self->{LocalPort} ||= $self->{daemon}->sockport;

	# Set the base access url
	$self->{uri} = URI->new($self->{daemon}->url);

	$self;
}

sub LocalAddr {
	$_[0]->{LocalAddr};
}

sub LocalPort {
	$_[0]->{LocalPort};
}

sub expected {
	@{$_[0]->{expected}};
}

sub directory {
	$_[0]->{directory};
}

sub daemon {
	$_[0]->{daemon};
}

sub uri {
	$_[0]->{uri};
}





#####################################################################
# Main Methods

# Launches the server
sub start {
	my $self = shift;

	# Fork to launch the server
	$self->{child} = fork();
	unless ( defined $self->{child} ) {
		delete $self->{child};
		Carp::croak("Failed to fork RequestServer");
	}

	$self->{child}
		? $self->_parent_start
		: $self->_child_start;
}

sub stop {
	my $self = shift;
	return 1 unless exists $self->{child};

	# There's a big difference between stopping at the parent
	# and child levels.
	$self->{child}
		? $self->_parent_stop
		: $self->_child_stop;
}




#####################################################################
# Parent-Specific Methods

sub _parent_start {
	my $self = shift;

	# Kill off our daemon immediately to prevent
	# shared handles
	delete $self->{daemon};

	1;
}

sub _parent_stop {
	my $self = shift;

	
}

sub _parent_pidfile {
	my $self = shift;
	unless ( $self->{child} ) {
		die("No child PID. _parent_pidfile called in bad context");
	}
	File::Spec->catfile( $self->directory, "$self->{child}.pid" );
}





#####################################################################
# Child-Specific Methods

sub _child_start {
	my $self = shift;

	# Create the PID file
	$self->{pidlock} = File::Flock->new(
		$self->_child_pidfile, undef, 'nonblocking',
		) or Carp::croak("Failed to create lockfile");

	# Continue to the main run sequence
	$self->_child_run;
}

# Main run-loop
sub _child_run {
	my $self   = shift;
	my $daemon = $self->{daemon}
		or die "->_child_run called without daemon object";

	# Wait for connections
	while ( my $c = $daemon->accept ) {
		my $r = $c->get_request;
		if ( $r ) {
			$self->_child_request( $r, $c );
		} else {
			$c->send_error(
				HTTP::Status::RC_INTERNAL_SERVER_ERROR()
				);
		}
		$c->close;
		undef($c);

		# If we run out of things to expect, shut down
		last unless $self->expected;
	}

	# Failed timeout...?
	$self->_child_stop;
}

# Handle a single request
sub _child_request {
	my ($self, $r, $c) = @_;

	$DB::single = 1;

	# The path should be /$expected
	my $uri  = $r->uri;
	my $path = $uri->path;
	$path =~ s{^/}{}; # Remove leading slash
	unless ( _POSINT($path) ) {
		return $c->send_error(
			HTTP::Status::RC_NOT_FOUND(),
			'Request path is not a PITA request identifier',
			);
	}

	# Are we expecting this
	my $expected = $self->{expected};
	unless ( grep { $path eq $_ } @$expected ) {
		return $c->send_error(
			HTTP::Status::RC_NOT_FOUND(),
			'Not expecting that PITA request identifier',
			);
	}

	# It must be a POST
	unless ( $r->method eq 'PUT' ) {
		return $c->send_error(
			HTTP::Status::RC_METHOD_NOT_ALLOWED(),
			'Only PUT is supported',
			);
	}

	# The mime-type should be application/xml
	unless ( $r->header('content_type') eq 'application/xml' ) {
		return $c->send_error(
			HTTP::Status::RC_UNSUPPORTED_MEDIA_TYPE(),
			'Content-Type must be application/xml',
			);
	}

	# Get the XML data and save
	my $file = File::Spec->catfile(
		$self->directory, "$path.pita"
		);
	unless (
	open( XML, '>', $file) and
	print XML $r->content   and
	close( XML )
	) {
		return $c->send_error(
			HTTP::Status::RC_INTERNAL_SERVER_ERROR,
			'Failed to write PITA Report to disk',
			);
	}

	# Thank them for the upload
	$c->send_status_line( 200, 'Report recieved and saved ok' );

	# Clear the entry from the expected array
	@$expected = grep { $_ ne $path } @$expected;

	1;
}

# Shut down
sub _child_stop {
	my $self = shift;

	# Clean up our resources
	delete $self->{pidlock};
	delete $self->{daemon};

	# Shut down
	exit(0);
}

sub _child_pidfile {
	my $self = shift;
	File::Spec->catfile( $self->directory, "$$.pid" );
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
