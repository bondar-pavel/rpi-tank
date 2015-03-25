#!/usr/bin/perl

# This program allows to map your keyboad pressing into GPIO actions.
# Developed for Raspberry Pi GPIO(BCM2835)
# author: Pavel Bondar, 2013
# license: MIT

use IO::Socket;
use Term::ReadKey;
use Getopt::Long;
use strict;

my ($debug, $show_usage, $servo);
my $version = 2;
GetOptions (
	'debug' =>\$debug, 
	'help' => \$show_usage,
	'version|i' => \$version,
	'servo' => \$servo,
);

usage() if $show_usage;

# define tank controls
## This versioning looks pretty ugly for me,
## but since it it just prof of concept I want to do it fast
## Try to make it pretty a bit later(10 years later?:)
# v1 uses only odd pinouts of gpio due to 1 element wide connector
my %v1 = (
	'left_forward'   => 26,
	'left_backward'  => 24,

	'right_forward'  => 22,
	'right_backward' => 18,

	'tower_left'     => 16,
	'tower_right'    => 12,
);
# v2 uses floppy drive cable as gpio connector, so even and odd pinout of rasprebby pi can be used
my %v2 = (
	'left_forward'   => 26,
	'left_backward'  => 24,

	'right_forward'  => 23,
	'right_backward' => 22,

	'tower_left'     => 21,
	'tower_right'    => 19,
);

my %servo_ctl = (
	'tower_left'	=> '12=+1',
	'tower_right'	=> '12=-1',

	'tower_up'	=> '11=-1',
	'tower_down'	=> '11=+1',

	'tower_left_fast'    => '12=+3',
        'tower_right_fast'   => '12=-3',

        'tower_up_fast'      => '11=-3',
        'tower_down_fast'    => '11=+3',
);

my %controls;

if ($servo) {
	%controls = %servo_ctl;
} elsif ($version == 2){
	%controls = %v2;
} elsif ($version == 1) {
	%controls = %v1;
} else {
	print "WTF? available versions only 1 and 2";
	usage();
}

print "Using version $version\n";

# define keys control hash
my %keys = (
	'a' => \&left,
	'A' => \&left_fast,
	'w' => \&forward,
	's' => \&backward,
	'd' => \&right,
	'D' => \&right_fast,
	'[' => \&tower_move_left,
	']' => \&tower_move_right,
	'p' => \&tower_move_up,
	';' => \&tower_move_down,
	'{' => \&tower_left_fast,
	'}' => \&tower_right_fast,
	'P' => \&tower_up_fast,
	':' => \&tower_down_fast,
);

# hash button names, just to show correct direction
my %key_names = (
	'a' => 'left',
	'A' => 'left fast',
	'w' => 'forward',
	's' => 'backward',
	'd' => 'right',
	'D' => 'right fast',
	'[' => 'tower left',
	']' => 'tower right',
	'p' => 'tower up',
	';' => 'tower down',
	';' => 'tower move down',
	'{' => 'tower left fast',
	'}' => 'tower right fast',
	'P' => 'tower up fast',
	':' => 'tower down fast',
);

# establish connection to gpiod
my $socket  = init_network($ARGV[0]);

# set custom readmode and return it back to normal after terminating
ReadMode('cbreak');
END {
	ReadMode('normal');
}
$SIG{TERM} = $SIG{INT} = $SIG{QUIT} = $SIG{HUP} = sub {$socket->close; print 'killed...'; die; };

while (1)
{
	my $char = ReadKey(0.2);
	if (exists $keys{$char} and ref($keys{$char}) eq 'CODE'){
		print "Moving $key_names{$char}\n" if exists $key_names{$char};
		&{$keys{$char}};
	} elsif (not $servo) {
		print "Stop\n";
		stop();
	}
}

# Control actions
sub forward {
	set_pinouts('left_forward', 'right_forward');
}

sub backward {
	set_pinouts('left_backward', 'right_backward');
}

sub stop {
	set_pinouts();
}

sub left_fast {
	set_pinouts('right_forward', 'left_backward');
}

sub left {
	set_pinouts('right_forward');
}

sub right_fast {
	set_pinouts('left_forward', 'right_backward');
}

sub right {
	set_pinouts('left_forward');
}

sub tower_move_left {
	set_pinouts('tower_left');
}

sub tower_move_right {
	set_pinouts('tower_right');
}

sub tower_move_up {
	set_pinouts('tower_up');
}

sub tower_move_down {
	set_pinouts('tower_down');
}
sub tower_left_fast {
        set_pinouts('tower_left_fast');
}
sub tower_right_fast{
        set_pinouts('tower_right_fast');
}
sub tower_up_fast{
        set_pinouts('tower_up_fast');
}
sub tower_down_fast{
        set_pinouts('tower_down_fast');
}


sub set_pinouts {
	# set controls from the input to active state
	my @pins = map {$controls{$_} if exists $controls{$_}} @_;
	my $cmd = 'set_output '.join(' ', @pins)."\n";

	print {$socket} $cmd;
}

sub init_network {
	my $host = shift || '127.0.0.1';
	print $host."\n";
        my $sock = new IO::Socket::INET (
                                PeerHost => $host,
                                PeerPort => '11700',
                                Proto => 'tcp',
                              );
        die "Could not create socket: $!\n" unless $sock;
	debug("Connection established");
        return $sock;
}

# service routines

sub debug {
	print shift."\n" if $debug;
}

sub usage {
	print <<EOF;
'WASD' controls are used for movement:
  'w' - move forward;
  's' - move backward;
  'a' - move left;
  'A' - move left fast;
  'd' - move right;
  'D' - move right fast;
'[' and ']' are used to move tower left and right
EOF
exit(0);
}

