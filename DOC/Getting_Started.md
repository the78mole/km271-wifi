---
title: "KM271-WiFi Quick Start Guide"
author: "Daniel (the78mole) Glaser"
---

# KM271-WiFi Quick Start

This is a short guide for commissioning the KM271-WiFi module.

![KM271-WiFi mostly assembled](../IMG/KM271-WiFi-0.1.0.jpg)

## Prerequisites

First, check if everything is present as ordered (from left to right):

- **J5** is the connector for the exhaust temperature sensor (the counterpart was included in the package; colors may vary: black or green)
- **J6** is the connector for sensor lines
- **J4** is the debug interface for programming via a serial connection

Depending on your order and selected options, some connectors may not be populated. The Ethernet extension in the second image is a separate module, also available in my Tindie store.

![KM271-WiFi with Ethernet Extension](../IMG/KM271-WiFi-0.1.0-ETH-Ext.jpg)

Now **check if the PWRSEL header** is configured as shown in the image. The middle and bottom jumpers should be in place. This is the correct setup for **powering via the Buderus control unit**. If you want to **power the module via USB**, you need to move the bottom jumper (blue in the image) to the top. Use the label under the capacitor as orientation. The black jumper must only be removed when flashing via the serial interface.

For the Ethernet extension, check: J5 is closed, J4 is open, and jumpers J1 to J3 are set to positions 2–3.

## Installation

If you plan to use Ethernet, now is the right time to attach the Ethernet extension.

1. Power off the Buderus control unit  
2. Remove the two screws of the housing and lift it carefully  
3. Slightly bend the cables above the KM271 slot upward so the module can be inserted from the side  
4. Align the module with the guide rails of the KM271 and slide it down  
5. Gently press the module into the slot – it clicks into place with a small tab in the rectangular opening of the KM271 module (shown next to the flat connector in the picture). To remove it again, release the tab with a screwdriver  
6. Connect additional sensors if needed: exhaust temperature probe, oil meter, OneWire, etc.  
7. Reattach the housing of the Buderus control unit  
8. Power the unit back on

The Buderus control unit's display should now show a new entry `ABGAS` or `EXHAUST`. If not, use the rotary knob to navigate. If an exhaust temperature sensor is connected, its current temperature will be shown. If not, it will display `---` – which is perfectly fine.

Now take your smartphone or PC and look for the Wi-Fi network `Fallback Hotspot` (for ESPhome, passphrase: `Z8zfajgxVvNw`) or `ESP-Buderus-KM271` (for dewennis firmware). On Android, the device may ask after 10–20 seconds whether you want to stay connected (since there’s no internet) – confirm with `Yes`. Then open your browser and visit http://192.168.4.1. Sometimes it takes a few minutes to establish the connection or load the page (probably a bug in ESPhome). Up to this point, the steps are the same for dewennis firmware – it's usually just a bit faster. Continue with the appropriate chapter for your firmware.

### ESPhome Configuration

You should now see the fallback hotspot page:

![Fallback Hotspot Page](../IMG/esphome-fallback-page.png)

Select your Wi-Fi and enter the password. If you accidentally choose the wrong network, it can be difficult to regain access to the board. In that case, you need to disable the wrong Wi-Fi. Alternatively, you can remove the module from the Buderus unit, move out of WiFi range and power it via USB (set the PWRSEL jumper accordingly). Then you can restart the setup process.

You can also flash a new firmware on the fallback hotspot page – but **not a different firmware** (e.g., the one by dewenni).

After setup, the board should appear in your ESPhome add-on in Home Assistant. You can now adjust the YAML configuration or leave it as is. If a new firmware version becomes available (e.g., via an update to the add-on), it can usually be flashed without issue.

You’ll find the device and its sensors, values, etc., in Home Assistant under:  
**Settings → Devices & Services → ESPhome**

More information:  
https://github.com/the78mole/ESPhome-KM271-WiFi

[![QR](https://api.qrserver.com/v1/create-qr-code/?data=https%3A%2F%2Fgithub.com%2Fthe78mole%2FESPhome-KM271-WiFi&size=150x150)](https://github.com/the78mole/ESPhome-KM271-WiFi)

### Dewennis MQTT Configuration

On first access to the dewennis web interface, you should configure the GPIOs – especially if you plan to use the Ethernet extension (ETH-Ext) to connect the KM271-WiFi to your home network. The GPIOs are as follows:

| Signal | GPIO  | Pin (J7) |
|--------|-------|----------|
| VCC    |       | J7.2     |
| GND    |       | J7.10    |
| CLK    | 18    | J7.9     |
| MOSI   | 23    | J7.7     |
| MISO   | 19    | J7.5     |
| CS     | 15    | J7.3     |
| INT    | 14    | J7.8     |
| RST    | 13    | J7.6     |

Apart from the Ethernet configuration, all other settings can be made after a restart.

Next, you need to configure the GPIOs for communication with the Buderus control unit. A predefined option exists for KM271-WiFi – please select it. If you want to connect different hardware, a detailed description is available here:

https://bit.ly/4jA7aHu

[![QR](https://api.qrserver.com/v1/create-qr-code/?data=https%3A%2F%2Fbit.ly%2F4jA7aHu&size=150x150)](https://bit.ly/4jA7aHu)

---

For additional support, you can join my Matrix channel:  
https://matrix.to/#/#molesblog:matrix.org

---

**Enjoy your oil burner – until the heat pump sends it into retirement!**
