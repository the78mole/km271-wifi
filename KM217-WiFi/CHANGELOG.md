= Changelog

== v1.0.x -> v2.0 (SMPS + USB-serial, in preparation)

    - Power supply
	  * U8 TPS62162DSG step-down converter (1 A, 3.3 V fixed, WSON-8, LCSC C40256) replaces the AZ1117 LDO
	  * L1 2.2 µH cjiang FTC252012S2R2MBCA (molded 2520, ISAT 3.8 A, 55 mOhm, LCSC C5832372; replaces WE-MAPI 4020 74438356022; alternatives XR XRIM252012S2R2MBCA C22471111, MetalLions MTQH252012S2R2MBT C17701218), C28 10u input, C29 22u output
	  * U2 (LDO) and C4 kept as DNP alternative, selected by R78 (SMPS, populated) / R79 (LDO, DNP)
	  * J3 power select header removed, USB VBUS and Buderus 5V combined by D8/D9 (BAT760)
	  * D10 SMAJ5.0A TVS on the Buderus 5V input
    - USB
	  * U10 CP2102N USB-serial converter on J2, connected to UART0 (R76/R77)
	  * CP2102N self-powered: VREGIN and VDD on +3V3, VBUS sensed via R71/R72 (22K1/47K5); R73 1K RSTb pull-up, C5 4u7
	  * Q1/Q2 auto-reset/boot circuit for EN/IO0 (R82, R84-R86)
	  * U3 WE-TVS 82400102 ESD protection on the USB data lines, 2R2 series resistors for EMC (see data path selection)
	  * D6/D7 TX/RX LEDs on the CP2102N
	  * J4 DEBUG header no longer populated by default
	  * USB data path selected by population: R69/R70 (2R2, populated) = ESP32-S3 native USB (GPIO19/20, default), R87/R88 (2R2, DNP) = CP2102N (recovery). Never populate both pairs. With the S3 path only, U10, Q1/Q2 and their parts can stay unpopulated
	  * Layout: R88 straddles the D+ line to reach D-, CP2102N branch taps directly at the J2 vias (minimal stub on the S3 path); C19 moved next to D8
	  * S3_D+/S3_D- routed as coupled pair (0.2 mm, 0.4 mm pitch) to U1 pads 14/13; GND stitching vias along the route moved, GND via added in U10 exposed pad
	  * Fix: SRV05-4 (U3) is not flow-through; D+/D- now connect to both pins of each channel (3/4, 1/6) directly behind J2 instead of passing through U3 pin 4 -> 3
    - Removed: I2C EEPROM (old U3), I2C-OneWire bridge DS2484 (U7), test points TP1-TP4
    - OneWire on IO32 populated by default (R49 1K pull-up via R57)
    - BOM: generated with scripts/export-jlc-bom.sh (DNP-aware grouping)

== 0.0.8 -> 0.1.0

    - TSENS changed CH7 input circuitry to oil counter compatible configuration
	  * R52: 1K -> np (remove pull-up)
	  * R16: np -> 1K (add pull-down)
	  * R9 : 0R -> 300R  (make it 5V compatible)