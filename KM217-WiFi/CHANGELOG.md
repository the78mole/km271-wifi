= Changelog

== v1.0.x -> v2.0 (SMPS + USB-serial, in preparation)

    - Power supply
	  * U8 TPS62203 step-down converter (L1 10u, C13 22u) replaces the AZ1117 LDO
	  * U2 (LDO) and C4 kept as DNP alternative, selected by R78 (SMPS, populated) / R79 (LDO, DNP)
	  * J3 power select header removed, USB VBUS and Buderus 5V combined by D8/D9 (BAT760)
	  * D10 SMAJ5.0A TVS on the Buderus 5V input
    - USB
	  * U10 CP2102N USB-serial converter on J2, connected to UART0 (R76/R77)
	  * Q1/Q2 auto-reset/boot circuit for EN/IO0 (R82, R84-R86)
	  * U3 WE-TVS 82400102 ESD protection on the USB data lines, R69/R70 in series
	  * D6/D7 TX/RX LEDs on the CP2102N
	  * J4 DEBUG header no longer populated by default
    - Removed: I2C EEPROM (old U3), I2C-OneWire bridge DS2484 (U7), test points TP1-TP4
    - OneWire on IO32 populated by default (R49 1K pull-up via R57)
    - BOM: generated with scripts/export-jlc-bom.sh (DNP-aware grouping)

== 0.0.8 -> 0.1.0

    - TSENS changed CH7 input circuitry to oil counter compatible configuration
	  * R52: 1K -> np (remove pull-up)
	  * R16: np -> 1K (add pull-down)
	  * R9 : 0R -> 300R  (make it 5V compatible)