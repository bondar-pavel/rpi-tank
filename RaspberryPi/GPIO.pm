package RaspberryPi::GPIO;

=pod
=head1 RaspberryPi::GPIO - GPIO control via tcp/ip using text protocol.

This module provide ability to control Raspberry Pi GPIO ports using simple
text protocol. You can use wide range of clients to interact with this daemon,
the most simple one is telnet.
By default daemon listens to port 11700 on localhost.
Try in console after starting daemon:
$ telnet localhost 11700
Examples of commands:
> help
Type help to get list of supported commands.
> set_output 5
Set pin 6 in high state, all other pins are in low state.
> set_output 1 3 6 23
Set pins 1,3,6,23 in high state, all other pins are in low state.
Pins are separated by space character, there is no limitations on pins count.

=cut

use Pod::Usage;
use IO::Socket;
use Fcntl qw(:flock);
use strict;

my $fallback_timeout;
my $debug;
my %commands = (
	'set_output' =>{
		code => \&set_output,
		help => "Set list of pins into high state. Will be set to fallback output values\n" .
			"once fallback timeout has exceeded.\n" .
			"Example 'set_output 23 26'.\n" .
			"If pi-blaster backend is used, allows to set PWM on pin:\n" .
			"Example 'set_output 23=40 26=80', where 23 is a pin, and 40 is 40% PWM for pin 23."
	},
	'set_fallback_timeout' =>{
		code => \&set_fallback_timeout,
		help => 'After timeout have passed fallback_output are set by server as outputs automatically.' .
			"\nHave no effect if unset or 0.",
	},
	'help' => {
		code => \&autogenerate_help,
		help => 'Generate this help.'
	},
	'exit' => {
		code => \&close_connection,
		help => 'Close connection to the client.'
	},
	'quit' => {
		code => \&close_connection,
		help => 'Close connection to the client.'
	},
);


sub new{
	my $class = shift;
	my $self = { @_ };
	
	return bless $self, $class;
}

sub start{
	my $self = shift;
	$self->{Socket} = new IO::Socket::INET (
				LocalHost => $self->{Host} || 'localhost',
				LocalPort => $self->{Port} || '11700',
				Proto => 'tcp',
				Listen => 1,
				Reuse => 1,
			);
	die "Could not create socket: $!\n" unless $self->{Socket};

	# prevent zombies
	$SIG{CHLD} = 'IGNORE';

	while (1) {
		my $new_sock = $self->{Socket}->accept();

		if (my $pid = fork()) {
			debug("Forked successfully");
			next;
		} elsif ($pid == 0) {
			info("Client connected");

			# Reset outputs to default state in case of exceeding $fallback_timeout 
			$SIG{ALRM} = \&reset_output;

			# provide user friendly command promt
			$new_sock->send('>');

			while(<$new_sock>) {
				alarm 0;

				info("Receiving transmission: " . $_);
				select_command($new_sock, $_);
				alarm $fallback_timeout;

				$new_sock->send('>');
			}
			close($new_sock) if $new_sock;
			info("Client disconnected");
			exit 0;
		} else {
			info("Failed to fork");
		}
	}
}

sub select_command {
	my ($sock, $command) = @_;
	if($command =~ /^(\S+)(.*)$/){
		my $cmd = lc($1);
		my @params = split(/\s+/, $2);
		shift @params;	#remove space between command and arguments
		print $sock "Params are ". join(" ", @params)."\n" if ($debug);
		if (exists $commands{$cmd}){
			process_command($sock, $commands{$cmd}, @params);
		} else { 
			$sock->send("Command '$cmd' is not a valid command, try 'help' to see commands list\n");
		}
	}
}

sub process_command {
	my $sock = shift; 
	my $cmd = shift;
	my @args = @_;

	if (ref($cmd) eq 'CODE') {
		&{$cmd}($sock, @args);
	} elsif (ref($cmd) eq 'HASH' && exists $$cmd{code}) {
		&{$$cmd{code}}($sock, @args);
	} else {
		print $sock $cmd;
	}

}

sub close_connection {
	my $sock = shift;

	close($sock);
}

sub set_fallback_timeout {
	my $sock = shift;
	my $timeout = int(shift);

	$fallback_timeout = $timeout if ($timeout > 0 && $timeout < 30);
}

sub autogenerate_help {
	my $sock = shift;

	$sock->send("List of commands:\n");
	foreach my $cmd (sort keys %commands) {
		$sock->send($cmd ." -\n");
		if (ref($commands{$cmd}) eq 'HASH' and exists $commands{$cmd}->{help}){
			# add TAB before each line of help message
			$sock->send(join("\n", map{"\t" . $_} split("\n", $commands{$cmd}->{help}))."\n");
		}
	}
}
# service routines
sub info {
	my $msg = shift;
	print "[$$] $msg\n";
}

sub debug {
	my $msg = shift;
	print "[$$] $msg\n" if $debug;
}

sub usage {
	print <<EOF;
This Daemon listens tcp socket and provide remote access over TCP/IP to GPIO pins of Raspberry PI.
EOF
	exit(0);
}

1;
