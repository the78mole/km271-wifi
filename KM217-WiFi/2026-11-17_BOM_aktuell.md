# KM217-WiFi – BOM mit Bestand und Preis (17.11.2026)

Quelle: JLCPCB-Bauteil-API, abgefragt am 17.11.2026 um 01:37 Uhr (MEZ), mit `scripts/jlc-bom-report.py`.
Grundlage ist der aktuelle Schaltplan (ESP32-S3, Projektbibliothek KM217-WiFi).
Preise in USD für **10 Platinen**, inklusive JLC-Ausschuss und Mindestmenge. Die Spalte „Bestand 06.11.“ zeigt den Stand des letzten Berichts zum Vergleich.

## Zusammenfassung

- Bauteilkosten: **138.97 USD** für 10 Platinen (13.90 USD pro Platine)
- Extended-Rüstgebühren: 13 × 3,00 = 39.00 USD
- Gesamt Bauteile inkl. Gebühren: **177.97 USD** (17.80 USD pro Platine)
- Nicht enthalten: Leiterplatte, Bestückung, Setup, Versand, Zoll.
- Bauteile ohne LCSC-Nummer sind alle DNP (nicht bestückt) oder aus der Stückliste ausgeschlossen (H1, J1).

## Tabelle

| Bauteile | Stk./Platine | Wert | LCSC | Herstellerteil | JLC-Typ | Bestand | Bestand 06.11. | Stückpreis USD | Preis 10 Platinen USD | Bemerkung |
|---|---:|---|---|---|---|---:|---:|---:|---:|---|
| C1, C3, C9-C11, C15-C17, C19-C23, C25-C27 | 16 | 100n | C14663 | CC0603KRX7R9BB104 | Basic | 33.238.675 | 35.429.175 | 0.0059 | 1.03 | Preis vorher 0.0067 |
| C2, C14 | 2 | 2u2 | C23630 | CL10A225KO8NNNC | Basic | 2.967.447 | 2.388.711 | 0.0100 | 0.30 | Preis vorher 0.0119 |
| C5 | 1 | 4u7 | C19666 | CL10A475KO8NNNC | Basic | 3.499.097 | 4.027.825 | 0.0150 | 0.30 |  |
| C7, C8 | 2 | 100u/16V | C340722 | UWT1C101MCL1GB | Extended | 20.005 | 1.139 | 0.1234 | 2.59 | Preis vorher 0.1400 |
| C12 | 1 | 33n | C21117 | CL10B333KB8NNNC | Basic | 897.877 | 776.066 | 0.0151 | 0.30 | Preis vorher 0.0136 |
| C13, C29 | 2 | 22u | C45783 | CL21A226MAQNNNE | Basic | 3.970.724 | 3.461.243 | 0.1084 | 2.60 | Preis vorher 0.1836 |
| C18 | 1 | 4p7 | C1669 | 0603CG4R7C500NT | Promo-Ext. | 563.788 | 591.303 | 0.0054 | 0.11 |  |
| C28 | 1 | 10u | C15850 | CL21A106KAYNNNE | Basic | 8.906.206 | 7.358.212 | 0.0311 | 0.62 | Preis vorher 0.0397 |
| C30 | 1 | 1u | C15849 | CL10A105KB8NNNC | Basic | 12.971.162 |  | 0.0083 | 0.17 | neu |
| D1, D2, D7 | 3 | LED green | C12624 | KT-0603G | Extended | 220.079 | 355.522 | 0.0119 | 0.55 |  |
| D3, D6 | 2 | LED yellow | C2287 | KT-0603Y | Extended | 57.499 | 94.830 | 0.0106 | 0.36 |  |
| D4 | 1 | LED red | C2286 | KT-0603R | Basic | 5.628.556 | 6.652.561 | 0.0077 | 0.15 |  |
| D8, D9 | 2 | 1N5819WS | C191023 | 1N5819WS | Basic | 3.813.868 | 3.170.170 | 0.0124 | 0.40 |  |
| D10 | 1 | SMAJ5.0A | C19077523 | SMAJ5.0A | Promo-Ext. | 233.295 | 248.870 | 0.0406 | 0.57 |  |
| J2 | 1 | USB_B_Mini | C5120592 | 65100516121 | Extended | 1.049 | 1.063 | 1.7608 | 17.61 |  |
| J6 | 1 | TSENS | C6074290 | 2086-1208 | Extended | 0 | 0 |  |  | DNP, ⚠ nicht lieferbar |
| J7 | 1 | EXT | C3330868 | 54202-G0805LF | Extended | 2.890 | 2.933 | 0.5499 | 5.50 |  |
| L1 | 1 | 2u2 | C5521727 | 74438356022 | Extended | 1.417 | 1.449 | 1.7264 | 17.26 |  |
| Q1, Q2 | 2 | SS8050 | C2150 | SS8050(RANGE:200-350) | Basic | 3.071.179 | 3.206.256 | 0.0147 | 0.37 |  |
| R1, R3, R76, R77, R84, R86 | 6 | 220 | C22962 | 0603WAF2200T5E | Basic | 1.875.815 | 2.886.799 | 0.0019 | 0.13 |  |
| R2, R27, R29, R32, R82, R85 | 6 | 10K | C25804 | 0603WAF1002T5E | Basic | 41.956.754 | 43.019.118 | 0.0020 | 0.14 | Preis vorher 0.0024 |
| R4, R30, R61-R63 | 5 | 4K7 | C23162 | 0603WAF4701T5E | Basic | 14.632.937 | 16.214.208 | 0.0028 | 0.17 |  |
| R5, R11 | 2 | 100K | C25803 | 0603WAF1003T5E | Basic | 14.455.592 | 16.331.052 | 0.0029 | 0.09 |  |
| R6 | 1 | 10 | C22859 | 0603WAF100JT5E | Basic | 5.712.703 | 5.807.592 | 0.0018 | 0.04 | Preis vorher 0.0021 |
| R7, R8, R33-R40, R57, R59, R64, R65, R78 | 15 | 0 | C21189 | 0603WAF0000T5E | Basic | 16.879.743 | 19.413.773 | 0.0021 | 0.34 |  |
| R9 | 1 | 330 | C23138 | 0603WAF3300T5E | Basic | 2.226.810 | 2.927.964 | 0.0020 | 0.04 |  |
| R12, R72 | 2 | 47K | C25819 | 0603WAF4702T5E | Basic | 2.667.670 | 3.074.246 | 0.0016 | 0.05 |  |
| R16, R49-R51, R73-R75 | 7 | 1K | C21190 | 0603WAF1001T5E | Basic | 26.416.497 | 27.652.889 | 0.0017 | 0.14 |  |
| R17 | 1 | 3K3 | C22978 | 0603WAF3301T5E | Basic | 4.264.897 | 4.855.575 | 0.0022 | 0.04 |  |
| R20-R22, R45-R48, R54-R56, R60, R80 | 12 | 22 | C23345 | 0603WAF220JT5E | Basic | 5.156.233 | 6.146.128 | 0.0017 | 0.23 |  |
| R23-R26 | 4 | 680 | C23228 | 0603WAF6800T5E | Basic | 1.386.543 | 1.798.828 | 0.0021 | 0.10 |  |
| R28 | 1 | 1M | C22935 | 0603WAF1004T5E | Basic | 4.360.662 | 4.502.849 | 0.0018 | 0.04 |  |
| R69, R70 | 2 | 2R2 | C22939 | 0603WAF220KT5E | Basic | 195.704 | 244.646 | 0.0027 | 0.08 |  |
| R71 | 1 | 22K | C31850 | 0603WAF2202T5E | Basic | 2.365.155 | 2.712.932 | 0.0042 | 0.08 |  |
| SW3 | 1 | BOOT | C306880 | B3SL-1002P | Extended | 5.137 | 5.982 | 0.2550 | 2.55 |  |
| SW4 | 1 | RESET | C306880 | B3SL-1002P | Extended | 5.137 | 5.982 | 0.2550 | 2.55 |  |
| U1 | 1 | ESP32-S3-WROOM-1 | C2913204 | ESP32-S3-WROOM-1-N8R2 | Extended | 11.429 |  | 4.0010 | 40.01 | neu |
| U2 | 1 | AZ1117IH-3.3TRG1 | C108495 | AZ1117IH-3.3TRG1 | Extended | 4.822 | 8.648 |  |  | DNP |
| U3 | 1 | WE-TVS-82400102 | C22435120 | 82400102 | Extended | 2.074 | 5.322 | 0.1385 | 1.66 |  |
| U4, U5 | 2 | SN74LV1T34DBV | C100024 | SN74LV1T34DBVR | Extended | 26.973 | 29.722 | 0.3571 | 7.86 |  |
| U6 | 1 | PCA9306DC1 | C5119911 | PCA9306DC1Z | Extended | 2.946 | 2.979 | 0.6431 | 6.43 |  |
| U8 | 1 | TPS62162DSG | C40256 | TPS62162DSGR | Extended | 4.487 | 5.172 | 0.9655 | 9.65 |  |
| U10 | 1 | CP2102N-Axx-xQFN28 | C964632 | CP2102N-A02-GQFN28R | Extended | 29.216 | 33.800 | 1.5759 | 15.76 |  |

## Auffälligkeiten

- **U1 ESP32-S3-WROOM-1-N8R2 (C2913204)** ist mit 4,00 USD das teuerste Teil. Der Bestand reicht derzeit für rund 11.000 Platinen.
- **J2 Mini-USB (C5120592, ca. 1.000 Stück)** und **L1 Würth 74438356022 (C5521727, ca. 1.400 Stück)** haben den kleinsten Bestand unter den bestückten Teilen. Für eine Kleinserie reicht das, bei größeren Stückzahlen sollte man sie im Auge behalten.
- **J6 WAGO 2086-1208 (C6074290)** ist bei JLC aktuell nicht lieferbar (Bestand 0). Das Teil ist DNP/THT und wird ohnehin von Hand bestückt.
- U2 (AZ1117, DNP) und J6 sind als DNP markiert und deshalb nicht im Preis enthalten.
