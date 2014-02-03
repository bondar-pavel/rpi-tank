install:
	chmod +x ./rpi-gpiod.pl
	cp ./rpi-gpiod.pl /usr/bin/rpi-gpiod
	cp ./rpi-gpiod.service /usr/lib/systemd/system

	chmod +x ./rpi-video
	cp ./rpi-video /usr/bin/rpi-video

uninstall:
	rm /usr/bin/rpi-gpiod
	rm /usr/lib/systemd/system/rpi-gpiod.service

	rm /usr/bin/rpi-video
