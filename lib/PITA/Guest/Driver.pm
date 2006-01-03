package PITA::Guest::Driver;

=pod

=head1 NAME

PITA::Guest::Driver - Abstract base for all PITA Guest driver classes

=head1 DESCRIPTION

This class provides a small amount of functionality, and is primarily
used to by drivers is a superclass so that all driver classes can be
reliably identified correctly.

=cut

use strict;
use Carp         ();
use File::Temp   ();
use Params::Util '_INSTANCE',
                 '_POSINT',
                 '_HASH';
use PITA::Report ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check the request object
	unless ( _INSTANCE($self->request, 'PITA::Report::Request') ) {
		unless ( _HASH($self->{request}) ) {
			Carp::croak("Did not provide PITA::Report::Request 'request'");
		}

		# Handle auto-boxing of request param HASH into an object
		$self->{request} = PITA::Report::Request->new( %{$self->{request}} );
	}

	# Check the request identifier
	unless ( _POSINT($self->request_id) ) {
		Carp::croak("Did not provide a request_id");
	}

	# Check the file to be tested
	unless ( $self->request_file ) {
		Carp::croak("Did not provide the path to the request_file");
	}
	unless ( -f $self->request_file and -r _ ) {
		Carp::croak("The request_file does not exist, or could not be read");
	}

	# Get ourselves a fresh tmp directory
	unless ( $self->tempdir ) {
		$self->{tempdir} = File::Temp::tempdir();
	}
	unless ( -d $self->tempdir and -w _ ) {
		die("Temporary working direction " . $self->tempdir . " is not writable");
	}

	$self;
}

sub request {
	$_[0]->{request};
}

sub request_id {
	$_[0]->{request_id};
}

sub request_file {
	$_[0]->{request_file};
}

sub tempdir {
	$_[0]->{tempdir};
}




#####################################################################
# PITA::Guest::Driver Methods

sub prepare {
	my $self = shift;
	1;
}

sub execute {
	my $self = shift;
	1;
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
