install:
	chmod +x ./rpi-gpiod.pl
	cp ./rpi-gpiod.pl /usr/bin/rpi-gpiod
	cp ./rpi-gpiod.service /usr/lib/systemd/system

uninstall:
	rm /usr/bin/rpi-gpiod
	rm /usr/lib/systemd/system/rpi-gpiod.service
