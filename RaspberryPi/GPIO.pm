package RaspberryPi::GPIO;

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
	# fallback output: if fallback timeout is exceeded, 
	'set_fallback_output' =>{
		help =>	"If fallback timeout is exceeded, server set fallback values as output.\n" .
			"Useful to stop in case of connection issues.",
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


sub init{
	my $class = shift;
	my %self = @_;
	
	return bless \%self, $class;
}

sub start{
	my $self = shift;
	$self->{Socket} =  new IO::Socket::INET (
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

1;
