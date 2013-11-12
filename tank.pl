#!/usr/bin/perl

# This program allows to map your keyboad pressing into GPIO actions.
# Developed for Raspberry Pi GPIO(BCM2835)
# author: Pavel Bondar, 2013
# license: MIT

use Device::BCM2835;
use Term::ReadKey;
use Getopt::Long;
use strict;

my ($debug, $show_usage);
my $version = 2;
GetOptions (
	'debug' =>\$debug, 
	'help' => \$show_usage,
	'version|i' => \$version,
);

usage() if $show_usage;

Device::BCM2835::set_debug(1) if $debug;
Device::BCM2835::init() || die "Could not init library";

# define tank controls
## This versioning looks pretty ugly for me,
## but since it it just prof of concept I want to do it fast
## Try to make it pretty a bit later(10 years later?:)
# v1 uses only odd pinouts of gpio due to 1 element wide connector
my %v1 = (
	'left_forward'   => &Device::BCM2835::RPI_GPIO_P1_26,
	'left_backward'  => &Device::BCM2835::RPI_GPIO_P1_24,

	'right_forward'  => &Device::BCM2835::RPI_GPIO_P1_22,
	'right_backward' => &Device::BCM2835::RPI_GPIO_P1_18,

	'tower_left'     => &Device::BCM2835::RPI_GPIO_P1_16,
	'tower_right'    => &Device::BCM2835::RPI_GPIO_P1_12,
);
# v2 uses floppy drive cable as gpio connector, so even and odd pinout of rasprebby pi can be used
my %v2 = (
	'left_forward'   => &Device::BCM2835::RPI_GPIO_P1_26,
	'left_backward'  => &Device::BCM2835::RPI_GPIO_P1_24,

	'right_forward'  => &Device::BCM2835::RPI_GPIO_P1_23,
	'right_backward' => &Device::BCM2835::RPI_GPIO_P1_22,

	'tower_left'     => &Device::BCM2835::RPI_GPIO_P1_21,
	'tower_right'    => &Device::BCM2835::RPI_GPIO_P1_19,
);

my %controls;
if ($version == 2){
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
	'w' => \&forward,
	's' => \&backward,
	'd' => \&right,
	'[' => \&tower_move_left,
	']' => \&tower_move_right,
);

# set all controls as outputs
foreach my $pin (keys %controls){
	Device::BCM2835::gpio_fsel($controls{$pin}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
}

# clear all control bits after initialization
stop();

# set custom readmode and return it back to normal after terminating
ReadMode('cbreak');
END {ReadMode('normal');}
$SIG{TERM} = $SIG{INT} = $SIG{QUIT} = $SIG{HUP} = sub { die; };

while (1)
{
	my $char = lc(ReadKey(0.2));
	print "Char is $char, " .ord($char). "\n";
	if (exists $keys{$char} and ref($keys{$char}) eq 'CODE'){
		&{$keys{$char}};
	} else {
		stop();
	}
	#Device::BCM2835::delay(200); # Milliseconds
}

# Control actions
sub forward {
	debug('Move forward');

	set_pinouts('left_forward', 'right_forward');
}

sub backward {
	debug('Move backward');

	set_pinouts('left_backward', 'right_backward');
}

sub stop {
	debug('Stop');

	set_pinouts();
}

sub left {
	debug('Turn left');

	set_pinouts('right_forward');
}

sub right {
	debug('Turn right');

	set_pinouts('left_forward');
}

sub tower_move_left {
        debug('Move tower left');

	set_pinouts('tower_left');
}

sub tower_move_right {
        debug('Move tower right');

	set_pinouts('tower_right');
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
'WASD' controls are used for movement:
  'W' - move forward;
  'S' - move backward;
  'A' - move left;
  'D' - move right;
'[' and ']' are used to move tower left and right
EOF
exit(0);
}

