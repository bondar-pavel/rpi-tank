#!/usr/bin/perl

# This program allows you to control GPIO pins over network.
# TCP-IP socket is used, by default port is 11700
# Developed for Raspberry Pi GPIO(BCM2835)
# author: Pavel Bondar, 2013
# license: MIT

use Device::BCM2835;
use Getopt::Long;
use IO::Socket;
use strict;

my ($debug, $show_usage);
GetOptions (
	'debug' =>\$debug, 
	'help' => \$show_usage,
);

usage() if $show_usage;


# hardware pin that can be used for reading/writing
my %pins = (
	12 => &Device::BCM2835::RPI_GPIO_P1_12,
	16 => &Device::BCM2835::RPI_GPIO_P1_16,
	18 => &Device::BCM2835::RPI_GPIO_P1_18,
	19 => &Device::BCM2835::RPI_GPIO_P1_19,
	21 => &Device::BCM2835::RPI_GPIO_P1_21,
	22 => &Device::BCM2835::RPI_GPIO_P1_22,
	23 => &Device::BCM2835::RPI_GPIO_P1_23,
	24 => &Device::BCM2835::RPI_GPIO_P1_24,
	26 => &Device::BCM2835::RPI_GPIO_P1_26,
);

init_hardware();

my $sock = init_network();

# For now just accept connection
while (1)
{
	my $new_sock = $sock->accept();
	while(<$new_sock>) {
		print $_;
	}
	close($sock);
}

sub init_hardware {
	Device::BCM2835::init() || die "Could not init library";

	Device::BCM2835::set_debug(1) if $debug;

	# set all controls as outputs
	foreach my $pin (keys %controls){
        	Device::BCM2835::gpio_fsel($controls{$pin}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
	}
}

sub init_network {
	my $sock = new IO::Socket::INET (
				#LocalHost => 'localhost',
				LocalPort => '11700',
				Proto => 'tcp',
				Listen => 1,
				Reuse => 1,
	                      );
	die "Could not create socket: $!\n" unless $sock;
	return $sock;
}

sub set_pinouts {
	my %pins = map {$_ => 0} sort keys %controls;
	#print join(',', keys %pins)."\n";
	# set controls from the input to active state
	map {$pins{$_} = 1 if exists $pins{$_}} @_;

	foreach my $pin (sort keys %pins) {
		Device::BCM2835::gpio_write($controls{$pin}, $pins{$pin});
	}
}

# service routines

sub debug {
	print shift."\n" if $debug;
}

sub usage {
	print <<EOF;
This Daemon listens tcp socket and give remote access over TCP/IP to GPIO pins of Raspberry PI.
EOF
exit(0);
}

