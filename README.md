rpi-tank
========

Raspberry Pi Tanks.

Project contains several utilities for Tank controlled by Raspberry Pi:

1) rpi-gpiod.pl - Raspberry Pi GPIO(general purpose input/output) daemon.
TCP/IP Socket -> GPIO.
Daemon listens TCP/IP Socket (by default 11700) and controls GPIO pins of Raspberry Pi.
rpi-gpiod.pl provides universal interface for interacting with Raspberry Pi GPIO for
various backends. Now two backends exists:
- rpi-keyboard - remote console controller
- rpi-rack - provides webui interface to tank controls 
Simple text protocol is used for receiving commands, so even telnet can be used for interacting with it.

2) rpi-keyboard.pl - Raspberry Pi remote Tank controller.
Console commands -> TCP/IP Socket.
This shell script connects to rpi-gpiod daemon(locally or remotely) and transmit commands to it.
List of available keybord keys is described below.
Commands are the same as tank.pl uses.

3) tank.pl - Raspberry Pi console Tank controller.
Console commands -> GPIO.
This is the first script that was developed as part of the Raspberry Pi Tank project.
It simply translate keyboard key presses into GPIO commands on the same device.
It is the simplest and fasters solution(in terms of delay), because there is no
TCP/IP part inside.
But usually you want to controll your Raspberry Pi tank remotely,
so you have to SSH on Raspberry Pi and run this script manually. 

And here is some details about Tank hardware and available keyboard keys in tank.pl and rpi-keyboard.pl.

Originally this device(Tank) was controlled by Radio waves(40Mhz), but it is very
limited in distanse and absolutely doesn't use my Raspbery Pi.
GPIO pins are connected directly to control routes on tank board.
+3.3V is used internally in tank, so Raspberry Pi GPIO is totally fine with it.
Exact match between pin and it's control functions you can see in source(hash %controls).

Keyboard pressing are red and translated into actions.
See hash %keys in soure code for more details.

'WASD' controls are used for movement:<br>
  'W' - move forward;<br>
  'S' - move backward;<br>
  'A' - move left;<br>
  'D' - move right;<br>
'[' and ']' are used to move tower left and right.

License: MIT
