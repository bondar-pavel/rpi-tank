package RaspberryPi::Backend::BCM2835;

use parent(RaspberryPi::Backend::Base);

sub is_available{
	my $verbose = shift;
	eval{ require Device::BCM2835; };
	if ($@) {
		print "Unable to load module Device::BCM2835\n" . $@ if $verbose;
		return 0;
	}
	unless ($<) {
		print "Should be executed by superuser\n" if $verbose;
	}
	return 1;
}

sub init{
	my $self = shift;

	require Device::BCM2835;
	Device::BCM2835::init() || die "Could not init library";

	#Device::BCM2835::set_debug(1) if $debug_hardware;

	# hardware pins that can be used for reading/writing
	$self->{Pins} = {
		12 => &Device::BCM2835::RPI_GPIO_P1_12,
		16 => &Device::BCM2835::RPI_GPIO_P1_16,
		18 => &Device::BCM2835::RPI_GPIO_P1_18,
		19 => &Device::BCM2835::RPI_GPIO_P1_19,
		21 => &Device::BCM2835::RPI_GPIO_P1_21,
		22 => &Device::BCM2835::RPI_GPIO_P1_22,
		23 => &Device::BCM2835::RPI_GPIO_P1_23,
		24 => &Device::BCM2835::RPI_GPIO_P1_24,
		26 => &Device::BCM2835::RPI_GPIO_P1_26,
	};
	# set all controls as outputs
	foreach my $pin (keys %{$self->{Pins}}){
		Device::BCM2835::gpio_fsel($self->{Pins}->{$pin}, &Device::BCM2835::BCM2835_GPIO_FSEL_OUTP);
	}
	# set all outputs as 0
	$self->set_output();
}

sub set_output{
	my $self = shift;

	my %values = map {$_ => 0} keys %{$self->{Pins}};
	map {$values{$_} = 1 if exists $values{$_}} @_;
	foreach (@_) {
		# set controls pins grabbed from input to high state, binary format
		if (exists $values{$_}) {
			$values{$_} = 1;
		}
	}

	foreach my $pin (sort keys %values) {
		#debug("Set output pin $pin with value $values{$pin}");
		Device::BCM2835::gpio_write($self->{Pins}->{$pin}, $values{$pin} ? 1 : 0);
	}
}

1;
