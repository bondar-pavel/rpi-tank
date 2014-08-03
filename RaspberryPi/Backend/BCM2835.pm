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

1;
