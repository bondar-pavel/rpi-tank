#!/usr/bin/perl

# This program allows you to control GPIO pins over network.
# TCP-IP socket is used, by default port is 11700
# Developed for Raspberry Pi GPIO(BCM2835)
# author: Pavel Bondar, 2013
# license: MIT
#
# How to deal with it:
# - open connection to port 11700
# - send 'set_output 1 3 12' - pins 1 3 12 will be set as 1
#    all other pins will be set as 0.
# - once you are done send 'exit', or 'quit'
# - for debug purpose you can connect via 'telnet localhost 11700',
#   than you can check how daemon reacts on your commands
# - when debugging it is usefull to run daemon with flags 
#   --debug --debug-network --debug-hardware
# --debug-network is needed when you dont want to initialize hardware
#   so specific hardware modules(BMC2835) will not be loaded
# --debug-hardware initialize hardware in debug mode,
#   so gpio pins actually will not be set,
#   just printing what values are gonna be set.


use Getopt::Long;
use IO::Socket;
use strict;

my ($debug, $verbose, $debug_network, $debug_hardware, $show_usage);
GetOptions (
	'debug' =>\$debug,
	'verbose' =>\$verbose,
	'debug-network' =>\$debug_network,
	'debug-hardware' =>\$debug_hardware,
	'help' => \$show_usage,
);

usage() if $show_usage;

my $fallback_output;
my $fallback_timeout = 1;
my %pins;
my %commands = (
	'get_version' => '1',
	'get_versions' => '1',
	#'set_version' =>,
	#'set_use_sequence' =>,
	#'set_as_output' =>,
	'set_output' =>\&set_output,
	# fallback output: if fallback timeout is exceeded, 
	# server set fallback values as output in case of connection problems
	#'set_fallback_output' =>,
	#'set_fallback_timeout' =>,
	#'get_input' =>,
	'help' => 'Help, I need somebody, HELP!',
	'exit' => \&close_connection,
	'quit' => \&close_connection,
);

# Hardware(BMC2835) is specific for raspbery pi platform
# so debuging on other platforms can be done using --debug-network flag
init_hardware() unless $debug_network;

my $sock = init_network();

# Allows only one client for now, no forking
while (1)
{
	my $new_sock = $sock->accept();

	# Reset outputs to default state in case of exceeding $fallback_timeout 
	$SIG{ALRM} = \&reset_output;
	alarm $fallback_timeout;
	while(<$new_sock>) {
		alarm 0;

		info($_);
		select_command($new_sock, $_);

		alarm $fallback_timeout;
	}
	close($new_sock);
}

sub init_hardware {
	require Device::BCM2835;
	Device::BCM2835::init() || die "Could not init library";

	Device::BCM2835::set_debug(1) if $debug_hardware;

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
	# set all outputs as 0
	set_pinouts();
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
	if($command =~ /^(\S+)(.+)$/){
		my $cmd = lc($1);
		my @params = split(/\s+/, $2);
		shift @params;	#remove space between command and arguments
		print $sock "Params are ". join(" ", @params)."\n";
		if (exists $commands{$cmd}){
			process_command($sock, $commands{$cmd}, @params);
		} else { 
			$sock->send("Command $cmd is not a valid command, try help to see command list\n");
		}
	}
}

sub process_command {
	my $sock = shift; 
	my $cmd = shift;
	my @args = @_;

	if(ref($cmd) eq 'CODE') {
		&{$cmd}($sock, @args);
	} else {
		print $sock $cmd;
	}

}

sub close_connection {
	my $sock = shift;

	close($sock);
}

sub set_output {
	my $sock = shift;
	#my %output_pins = %{@_};
	#my @up_pins = grep { $output_pins{$_} } keys %output_pins;
	#set_pinouts(@up_pins);
	set_pinouts(@_);
}

sub reset_output {
	info("Received SIG ALARM\n");
	set_pinouts($fallback_output);
}

sub set_pinouts {
	my %values = map {$_ => 0} sort keys %pins;
	# set controls pins grabbed from input to high state
	map {$values{$_} = 1 if exists $values{$_}} @_;

	foreach my $pin (sort keys %values) {
		debug("Set output pin $pin with value $values{$pin}");
		Device::BCM2835::gpio_write($pins{$pin}, $values{$pin});
	}
}

# service routines
sub info {
	print shift,"\n" if $debug or $verbose; 
}

sub debug {
	print shift."\n" if $debug;
}

sub usage {
	print <<EOF;
This Daemon listens tcp socket and give remote access over TCP/IP to GPIO pins of Raspberry PI.
EOF
exit(0);
}

