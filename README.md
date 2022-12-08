# logamatic_2107_wifi_comm

A direct KM217 replacement with WiFi connection to control a buderus heating system with Logamatic 2107 controller board.

This hardware and its documentation is released under the *TAPR Open Hardware License* Version 1.0 (May 25, 2007). 
A [copy of the license](LICENSE.txt) is included here or can be accessed in multiple formats on [tapr.org](https://tapr.org/the-tapr-open-hardware-license/). 

For more details, look on my [blog post](https://the78mole.de/reverse-engineering-the-buderus-km217/) or on [tindie](https://www.tindie.com/products/the78mole/buderus-km217-wifi-replacement/).

If you bought the board in my tindie store, you could find a how-to to get it running [here](https://the78mole.de/projects/km271-wifi-howto/)

Here is the latest picture of the 0.0.5 I received as the assembly confirmation (only SMD parts) from manufacturer:

![v0.0.5_SMD_Top fully assembled](IMG/KM271-WiFi_0.0.5_top_fully.jpg)
![v0.0.5_SMD_Top](IMG/KM271-WiFi_0.0.5_bottom.jpg)
![v0.0.5_SMD_Bottom](IMG/KM271-WiFi_0.0.5_top.jpg)

And this is a early 0.0.5 proto hand soldered.

![v0.0.5_proto_top](IMG/KM271-WiFi_0.0.5_proto_top.jpg)

Here is a Version 0.0.1 board with fixes (corrected RX & TX pins of ESP32):

![v0.0.1_fixed](IMG/Buderus-KM217-Clone_0.0.1_with_fixes.jpg)

## Improvements / ToDo

 * Add a 100 nF filter capacitor to the 5V sense signal parallel to R12 (same as the other ADC inputs)
 * Add OneWire connector and optional I2C-OneWire-Master (DS2484)
 * Add extension connector with SPI and I2C interface (e.g. for a Display)
 * Add a OneWire temperature Sensor on the board itself

