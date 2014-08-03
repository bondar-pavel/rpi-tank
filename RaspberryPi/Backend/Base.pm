package RaspberryPi::Backend::Base;

=head1 RaspberryPi::Backend::Base

Base class for backend modules.
It defines interface that is used by RaspberryPi::GPIO module
to control GPIO hardware.

Backend modules are runtime loaded and initializated.
Main idea is that module can be checked if it can be used without breaking 
main daemon because of missed specific dependency or so on.

So backen module should:
- Load only standard libraries via 'use', so we can be sure, that hardware
specific library, that is not currently availabe, will not cause application
to fail.
- There should be defined a class method is_available(); that returns true
if it is safe to call init and all needed 3-rd party libraries are available.
- As a result 3-rd party libraries are required when instance of Backend class
is created.
- Backend class should implement all methods listed below, this is example of
Backend API

=cut

my $not_defined_message = "Should be redefined in child backend class";

sub new{
	my $class = shift;
	my $self = {};

	if( $class->is_available() ) {
		$self = init(@_);
	}
	return bless $self, $class;
}

sub init{
	my %opts = @_;
	return \%opts; 
}

=item is_available

Should return true if module is safe to load and all dependencies are availabe,
i.e. third party modules are present, all needed hardware exists and so no.
So once is_available returns true we can be sure that creating instance of
Backend module will not fail.
Method itseld should not fail or generate exception.
Exceptions should be hadnled internally.

=cut

sub is_available{
	die 'is_available(): ' . $not_defined_message;
}

=item set_output

Method for setting all pins in one call.
Should accept various argument count.
Each argument stands for pin number.
Pins that are passed to this method will be set to the high state,
all other pins are set to the low state.

=cut

sub set_output{
	die 'set_output(): ' . $not_defined_message;
}

=item set_pin

Method for setting only one pin at ones, 
should not affect other pins.
Should accept two argument.
Argument one: pin number
Argument two: pin level
0 for low level
1 for high level
If backend supports PWM values between 0..1 are treated as percents of PWM,
otherwise, everything that is not 0 is treated as 1.

=cut

sub set_pin{
	die 'set_pin(): ' . $not_defined_message;
}

1;
