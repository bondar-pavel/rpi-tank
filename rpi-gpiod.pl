#!/usr/bin/perl

# This program allows you to control GPIO pins over network.
# TCP-IP socket is used, by default port is 11700
# Developed for Raspberry Pi GPIO(BCM2835)
# author: Pavel Bondar, 2013
# license: MIT

use Getopt::Long;
use IO::Socket;
use strict;

my ($debug, $debug_network, $show_usage);
GetOptions (
	'debug' =>\$debug,
	'debug-network' =>\$debug_network,
	'help' => \$show_usage,
);

usage() if $show_usage;

my %pins;
my %commands = (
	'get_version' => '1',
	'get_versions' => '1',
	#'set_version' =>,
	#'set_use_sequence' =>,
	#'set_as_output' =>,
	'set_output' =>,
	# fallback output: if fallback timeout is exceeded, 
	'set_fallback_output' =>{
		help =>	'If fallback timeout is exceeded, server set fallback values as output in case of connection problems',
	},
	'set_fallback_timeout' =>{
		help => 'After timeout have passed fallback_output are set by server as outputs automatically' .
			"\nHave no effect if unset or 0",
	},
	'get_input' =>,
	'help' => \&autogenerate_help,
	'exit' => sub{ exit 0; },
	'quit' => sub{ exit 0; },
);

# Hardware(BMC2835) is specific for raspbery pi platform
# so debuging on other platforms can be done using --debug-network flag
init_hardware() unless $debug_network;

my $sock = init_network();

# Allows only one client for now, no forking
while (1)
{
	my $new_sock = $sock->accept();
	while(<$new_sock>) {
		debug($_);
		select_command($new_sock, $_);
	}
	close($sock);
}

sub init_hardware {
	require Device::BCM2835;
	Device::BCM2835::init() || die "Could not init library";

	Device::BCM2835::set_debug(1) if $debug;

	# hardware pin that can be used for reading/writing
	%pins = (
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
	# set all controls as outputs
	foreach my $pin (keys %pins){
        	Device::BCM2835::gpio_fsel($pins{$pin}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
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

sub select_command {
	my ($sock, $command) = @_;
	if($command =~ /^(\S+)(.+)/){
		my $cmd = lc($1);
		if (exists $commands{$cmd}){
			process_command($sock, $commands{$cmd}, $2);
		} else { 
			$sock->send("Command $cmd is not a valid command, try help to see command list\n");
		}
	}
}

sub process_command {
	my ($sock, $cmd, $opts) = @_;

	debug(ref($cmd));
	$sock->send($cmd."\n");
	if (ref($cmd) eq 'CODE') {
		$sock->send("Calling bla-bla\n");
		#&$cmd($sock);
		$sock->$cmd;
	}
}

sub autogenerate_help {
	my $sock = shift;
	$sock->send("Startint autogenerate\n");

	foreach my $cmd (keys %commands) {
		$sock->send($cmd ."\n");
		if (ref($commands{$cmd}) eq 'HASH' and exists $commands{$cmd}->{help}){
			$sock->send($cmd . " -\n");
			# don't be afraid of next string it just adds TAB before each line of help message
			$sock->send(join("\n", map{"\t" . $_} split("\n", $commands{$cmd}->{help})));
		}
	}
}

sub set_pinouts {
	my %values = map {$_ => 0} sort keys %pins;
	#print join(',', keys %pins)."\n";
	# set controls from the input to active state
	map {$values{$_} = 1 if exists $values{$_}} @_;

	foreach my $pin (sort keys %values) {
		Device::BCM2835::gpio_write($pins{$pin}, $values{$pin});
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

