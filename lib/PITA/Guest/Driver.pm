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
use PITA::XML    ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Were we passed the guest object
	unless ( _INSTANCE($self->guest, 'PITA::XML::Guest') ) {
		Carp::croak('Missing or invalid guest');
	}

	# Get ourselves a fresh tmp directory
	unless ( $self->tempdir ) {
		$self->{tempdir} = File::Temp::tempdir();
	}
	unless ( -d $self->tempdir and -w _ ) {
		die("Temporary directory " . $self->tempdir . " is not writable");
	}

	$self;
}

sub guest {
	$_[0]->{guest};
}

sub tempdir {
	$_[0]->{tempdir};
}




#####################################################################
# PITA::Guest::Driver Main Methods

sub ping {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'ping'");
}

sub discover {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'discover'");
}

sub test {
	my $self = shift;
	Carp::croak(ref($self) . " failed to implement 'test'");
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
