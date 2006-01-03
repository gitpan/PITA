package PITA::Guest::Driver::Qemu;

=pod

=head1 NAME

PITA::Guest::Driver::Qemu - PITA Guest Driver for Qemu images

=head1 DESCRIPTION

The author is an idiot

=cut

use strict;
use base 'PITA::Guest::Driver::Image';
use version      ();
use Carp         ();
use URI          ();
use File::Spec   ();
use File::Copy   ();
use File::Which  ();
use Config::Tiny ();
use PITA::Report ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_01';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Locate the qemu binary
	$self->{qemu_bin} = File::Which::which('qemu') unless $self->qemu_bin;
	unless ( $self->qemu_bin ) {
		Carp::croak("Cannot locate qemu, requires explicit param");
	}
	unless ( -x $self->qemu_bin ) {
		Carp::croak("Insufficient permissions to run qemu");
	}

	# Find the install qemu version
	my $qemu_bin = $self->qemu_bin;
	my @lines = `$qemu_bin`;
	unless ( $lines[0] =~ /version ([\d\.]+),/ ) {
		Carp::croak("Failed to locate Qemu version");
	}
	$self->{qemu_version} = version->new("$1");

	# Check the qemu version
	unless ( $self->qemu_version >= version->new('0.7.1') ) {
		Carp::croak("Currently only supports qemu 0.7.1 or newer");
	}

	$self;
}

sub qemu_bin {
	$_[0]->{qemu_bin};	
}

sub qemu_version {
	$_[0]->{qemu_version};
}





#####################################################################
# PITA::Guest::Driver::Image Methods

# Qemu uses a standard networking setup
sub support_server_addr {
	$_[0]->support_server
		? shift->SUPER::support_server_addr
		: '127.0.0.1';
}

sub support_server_uri {
	URI->new( "http://10.0.2.2/" );
}





#####################################################################
# PITA::Guest::Driver::Qemu Methods

sub execute_image {
	my $self = shift;
	my $cmd  = join ' ',
		$self->qemu_bin,
		'-m', $self->memory,
		'-hda',
		$self->snapshot ? ( '-snapshot' ) : (),
		'-nographic',
		$self->image,
		'-hdb fat:' . $self->tempdir;

	# Execute the command
	system( $cmd );

}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Host-Driver-Qemu>

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
