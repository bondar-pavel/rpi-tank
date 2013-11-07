rpi-tank
========

Raspberry Pi Tanks.

This command line utility reads you keyboard pressing and translates into GPIO actions.
Main purpose is controlling external electronics in realtime.
Code was written to control toy tanks directly by Raspberry Pi.
Originally this device was controlled by Radio waves(40Mhz), but it is very
limited in distanse and absolutely doesn't use my Raspbery Pi.

GPIO pins are connected directly to control routes on tank board.
+3.3V is used internally in tank, so Raspberry Pi GPIO is totally fine with it.
Exact match between pin and it's control functions you can see in source(hash %controls).

Keyboard pressing are red and translated into actions.
See hash %keys in soure code for more details.

'WASD' controls are used for movement:
  'W' - move forward;
  'S' - move backward;
  'A' - move left;
  'D' - move right;
'[' and ']' are used to move tower left and right

License: MIT
