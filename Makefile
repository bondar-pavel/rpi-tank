install:
	chmod +x ./rpi-gpiod.pl
	rm -f /usr/bin/rpi-gpiod
	ln -s ./rpi-gpiod.pl /usr/bin/rpi-gpiod

uninstall:
	rm /usr/bin/rpi-gpiod
