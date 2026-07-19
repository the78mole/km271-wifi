# New Features

Some new features shall be implemented in hardware

## Planning

### USB-Serial-Converter

| Chip / Modul | Hersteller | Typischer Preis (ca.) | Hinweise |
| --- | --- | --- | --- |
| CH340G | WCH | 0,50 – 1,50 € | Sehr verbreitet, günstiger Klon |
| CH341A | WCH | 1,00 – 2,50 € | Auch als Programmer nutzbar |
| CP2102 | Silicon Labs | 1,50 – 3,00 € | Weit verbreitet, stabile Treiber |
| CP2104 | Silicon Labs | 2,00 – 4,00 € | Mehr GPIOs, Flowcontrol |
| FT232RL | FTDI | 4,00 – 8,00 € | Klassiker, sehr stabile Treiber |
| FT232H | FTDI | 8,00 – 15,00 € | High-Speed, SPI/I²C/JTAG möglich |
| PL2303HX | Prolific | 1,00 – 3,00 € | Älterer Standard, Treiber-Probleme unter Win11 |
| PL2303TA | Prolific | 1,50 – 3,50 € | Neuere Revision, bessere Treiberunterstützung |
| MCP2221A | Microchip | 3,00 – 6,00 € | USB-UART + I²C/GPIO |
| STM32 (CDC) | ST | 2,00 – 5,00 € | Custom-Firmware auf STM32 als VCP |

### SMPS for Power Supply

Anforderung: 5 V → 3,3 V @ 300 mA, günstig, platzsparend — **Switching Buck Converter** (kein LDO, Effizienz im Vordergrund)

| IC | Hersteller | Package | Iout max | f_sw | Preis (ca.) | Hinweise |
| --- | --- | --- | --- | --- | --- | --- |
| TPS62203 | TI | SOT-23-5 | 300 mA | 3 MHz | 1,50 – 3,00 € | Fixspannung 3,3 V, sehr klein |
| TPS62240 | TI | SOT-23-5 | 300 mA | 2,25 MHz | 1,50 – 3,00 € | Fixspannung 3,3 V, low quiescent |
| AP3406 | Diodes Inc. | SOT-23-5 | 600 mA | 1,5 MHz | 0,30 – 0,80 € | Einstellbar, günstig |
| RT8068A | Richtek | SOT-23-5 | 600 mA | 1,5 MHz | 0,50 – 1,00 € | Fixspannung wählbar, gute Verfügbarkeit |
| SGM6130 | SG Micro | SOT-23-6 | 600 mA | 1,5 MHz | 0,40 – 1,00 € | Einstellbar, weit verbreitet |
| ME3116 | Nanjing Micro One | SOT-23-5 | 600 mA | 1,5 MHz | 0,20 – 0,60 € | Günstige Alternative |
| XL1509-3.3 | XLSEMI | SOP-8 | 2 A | 150 kHz | 0,20 – 0,50 € | Größer, braucht größere Spule |
| MP2307 | MPS | SOP-8 | 3 A | 340 kHz | 0,50 – 1,50 € | Überdimensioniert, aber sehr günstig |

> Alle ICs benötigen externe Bauteile: Induktivität (1–4,7 µH), Eingangs- und Ausgangskondensatoren.
> Empfehlung für minimale Fläche: **TPS62203** oder **RT8068A** im SOT-23-5-Gehäuse mit 1 µH Spule.

## Done
