# KM217-WiFi – BOM mit Bestand und Preis (17.11.2026)

Quelle: JLCPCB-Bauteil-API, abgefragt am 17.11.2026 um 10:47 Uhr (MEZ), mit `scripts/jlc-bom-report.py`.
Grundlage ist der aktuelle Schaltplan (ESP32-S3, Projektbibliothek KM217-WiFi) inklusive der Teiletausche aus PR #24 und der neuen Speicherdrossel L1.
Preise in USD für **10 Platinen**, inklusive JLC-Ausschuss und Mindestmenge. Die Spalte „Bestand 01:37“ zeigt den Stand des vorigen Berichts vom selben Tag zum Vergleich.

## Zusammenfassung

- Bauteilkosten: **117.39 USD** für 10 Platinen (11.74 USD pro Platine)
- Extended-Rüstgebühren: 11 × 3,00 = 33.00 USD
- Gesamt Bauteile inkl. Gebühren: **150.39 USD** (15.04 USD pro Platine)
- Vorheriger Bericht (01:37 Uhr, vor den Teiletauschen): 177.97 USD (17.80 USD pro Platine). Allein L1 spart 16.76 USD pro 10 Platinen.
- Nicht enthalten: Leiterplatte, Bestückung, Setup, Versand, Zoll.
- Bauteile ohne LCSC-Nummer sind alle DNP (nicht bestückt) oder aus der Stückliste ausgeschlossen (H1, J1).

## Tabelle

| Bauteile | Stk./Platine | Wert | LCSC | Herstellerteil | JLC-Typ | Bestand | Bestand 01:37 | Stückpreis USD | Preis 10 Platinen USD | Bemerkung |
|---|---:|---|---|---|---|---:|---:|---:|---:|---|
| C1, C3, C9-C11, C15-C17, C19-C23, C25-C27 | 16 | 100n | C14663 | CC0603KRX7R9BB104 | Basic | 31.918.879 | 33.238.675 | 0.0058 | 1.01 |  |
| C2, C14 | 2 | 2u2 | C23630 | CL10A225KO8NNNC | Basic | 2.848.197 | 2.967.447 | 0.0100 | 0.30 |  |
| C5 | 1 | 4u7 | C19666 | CL10A475KO8NNNC | Basic | 3.384.659 | 3.499.097 | 0.0150 | 0.30 |  |
| C7, C8 | 2 | 220u/16V | C41410193 | SPT1CM221E06TRVZC | Extended | 4.714 |  | 0.1324 | 2.65 | neu (vorher C340722) |
| C12 | 1 | 33n | C21117 | CL10B333KB8NNNC | Basic | 867.434 | 897.877 | 0.0151 | 0.30 |  |
| C13, C29 | 2 | 22u | C45783 | CL21A226MAQNNNE | Basic | 3.860.150 | 3.970.724 | 0.1085 | 2.60 |  |
| C18 | 1 | 4p7 | C1669 | 0603CG4R7C500NT | Promo-Ext. | 560.506 | 563.788 | 0.0054 | 0.11 |  |
| C28 | 1 | 10u | C15850 | CL21A106KAYNNNE | Basic | 8.745.145 | 8.906.206 | 0.0312 | 0.62 |  |
| C30 | 1 | 1u | C15849 | CL10A105KB8NNNC | Basic | 12.763.334 | 12.971.162 | 0.0083 | 0.17 |  |
| D1, D2, D7 | 3 | LED green | C12624 | KT-0603G | Extended | 215.216 | 220.079 | 0.0119 | 0.55 |  |
| D3, D6 | 2 | LED yellow | C2287 | KT-0603Y | Extended | 48.154 | 57.499 | 0.0106 | 0.36 |  |
| D4 | 1 | LED red | C2286 | KT-0603R | Basic | 5.531.110 | 5.628.556 | 0.0077 | 0.15 |  |
| D8, D9 | 2 | 1N5819WS | C191023 | 1N5819WS | Basic | 3.753.450 | 3.813.868 | 0.0124 | 0.40 |  |
| D10 | 1 | SMAJ5.0A | C19077523 | SMAJ5.0A | Promo-Ext. | 232.979 | 233.295 | 0.0407 | 0.57 |  |
| J2 | 1 | USB_B_Mini | C5120592 | 65100516121 | Extended | 1.049 | 1.049 | 1.7627 | 17.63 |  |
| J6 | 1 | TSENS | C6074290 | 2086-1208 | Extended | 0 | 0 |  |  | DNP, ⚠ nicht lieferbar |
| J7 | 1 | EXT | C3330868 | 54202-G0805LF | Extended | 2.890 | 2.890 | 0.5505 | 5.50 |  |
| L1 | 1 | 2u2 | C5832372 | FTC252012S2R2MBCA | Extended | 1.060.426 |  | 0.0354 | 0.50 | neu (vorher C5521727) |
| Q1, Q2 | 2 | SS8050 | C2150 | SS8050(RANGE:200-350) | Basic | 3.015.301 | 3.071.179 | 0.0147 | 0.37 |  |
| R1, R3, R76, R77, R84, R86 | 6 | 220 | C22962 | 0603WAF2200T5E | Basic | 1.835.361 | 1.875.815 | 0.0019 | 0.13 |  |
| R2, R27, R29, R32, R82, R85 | 6 | 10K | C25804 | 0603WAF1002T5E | Basic | 41.294.581 | 41.956.754 | 0.0020 | 0.14 |  |
| R4, R30, R61-R63 | 5 | 4K7 | C23162 | 0603WAF4701T5E | Basic | 14.421.524 | 14.632.937 | 0.0028 | 0.17 |  |
| R5, R11 | 2 | 100K | C25803 | 0603WAF1003T5E | Basic | 14.258.939 | 14.455.592 | 0.0029 | 0.09 |  |
| R6 | 1 | 10 | C22859 | 0603WAF100JT5E | Basic | 5.553.141 | 5.712.703 | 0.0018 | 0.04 |  |
| R7, R8, R33-R40, R57, R59, R64, R65, R78 | 15 | 0 | C21189 | 0603WAF0000T5E | Basic | 16.642.957 | 16.879.743 | 0.0021 | 0.34 |  |
| R9 | 1 | 330 | C23138 | 0603WAF3300T5E | Basic | 2.193.209 | 2.226.810 | 0.0020 | 0.04 |  |
| R12, R72 | 2 | 47K | C25819 | 0603WAF4702T5E | Basic | 2.651.487 | 2.667.670 | 0.0016 | 0.05 |  |
| R16, R49-R51, R73-R75 | 7 | 1K | C21190 | 0603WAF1001T5E | Basic | 26.066.345 | 26.416.497 | 0.0017 | 0.14 |  |
| R17 | 1 | 3K3 | C22978 | 0603WAF3301T5E | Basic | 4.238.798 | 4.264.897 | 0.0022 | 0.04 |  |
| R20-R22, R45-R48, R54-R56, R60, R80 | 12 | 22 | C23345 | 0603WAF220JT5E | Basic | 5.037.788 | 5.156.233 | 0.0017 | 0.23 |  |
| R23-R26 | 4 | 680 | C23228 | 0603WAF6800T5E | Basic | 1.375.074 | 1.386.543 | 0.0021 | 0.10 |  |
| R28 | 1 | 1M | C22935 | 0603WAF1004T5E | Basic | 4.309.622 | 4.360.662 | 0.0018 | 0.04 |  |
| R69, R70 | 2 | 2R2 | C22939 | 0603WAF220KT5E | Basic | 187.645 | 195.704 | 0.0027 | 0.08 |  |
| R71 | 1 | 22K | C31850 | 0603WAF2202T5E | Basic | 2.329.846 | 2.365.155 | 0.0042 | 0.08 |  |
| SW3 | 1 | BOOT | C318884 | TS-1187A-B-A-B | Basic | 789.160 |  | 0.0215 | 0.30 | neu (vorher C306880) |
| SW4 | 1 | RESET | C318884 | TS-1187A-B-A-B | Basic | 789.160 |  | 0.0215 | 0.30 | neu (vorher C306880) |
| U1 | 1 | ESP32-S3-WROOM-1 | C2913204 | ESP32-S3-WROOM-1-N8R2 | Extended | 11.332 | 11.429 | 4.0053 | 40.05 |  |
| U2 | 1 | AZ1117IH-3.3TRG1 | C108495 | AZ1117IH-3.3TRG1 | Extended | 4.812 | 4.822 |  |  | DNP |
| U3 | 1 | SRV05-4 | C7420376 | SRV05-4 | Promo-Ext. | 554.561 |  | 0.0852 | 1.19 | neu (vorher C22435120) |
| U4, U5 | 2 | SN74LV1T34DBV | C100024 | SN74LV1T34DBVR | Extended | 25.448 | 26.973 | 0.3575 | 7.87 |  |
| U6 | 1 | PCA9306DC1 | C5119911 | PCA9306DC1Z | Extended | 2.946 | 2.946 | 0.6438 | 6.44 |  |
| U8 | 1 | TPS62162DSG | C40256 | TPS62162DSGR | Extended | 4.477 | 4.487 | 0.9666 | 9.67 |  |
| U10 | 1 | CP2102N-Axx-xQFN28 | C964632 | CP2102N-A02-GQFN28R | Extended | 26.314 | 29.216 | 1.5776 | 15.78 |  |

## L1 im Vergleich

| | vorher | jetzt |
|---|---|---|
| Hersteller, Typ | Würth WE-MAPI 74438356022 | cjiang FTC252012S2R2MBCA |
| LCSC | C5521727 | C5832372 |
| Bauform | 4,1 × 4,1 × 2,0 mm | 2,5 × 2,0 × 1,2 mm (1008), molded, geschirmt |
| Induktivität | 2,2 µH ±20 % | 2,2 µH ±20 % |
| Isat | 4,05 A | 3,8 A |
| DCR | 29 mΩ | 55 mΩ |
| Stückpreis | 1,73 USD | 0,035 USD |
| Bestand | ca. 1.400 | ca. 1,06 Mio. |
| Footprint | L_Wuerth_MAPI-4020 | L_Changjiang_FTC252012S (KiCad-Bibliothek) |

Beide liegen weit über dem Bedarf des TPS62162 (Spitzenstrom etwa 0,6 A bei 460 mA Last, Stromgrenze höchstens 2,45 A). Der höhere DCR kostet bei 0,46 A etwa 6 mW und 12 mV.

## Auffälligkeiten

- **U1 ESP32-S3-WROOM-1-N8R2 (C2913204)** ist mit 4,01 USD das teuerste Teil. Der Bestand reicht derzeit für rund 11.000 Platinen.
- **J2 Mini-USB (C5120592, ca. 1.000 Stück)** hat jetzt allein den kleinsten Bestand unter den bestückten Teilen. Der Engpass bei L1 ist mit der neuen Drossel weg.
- **J6 WAGO 2086-1208 (C6074290)** ist bei JLC aktuell nicht lieferbar (Bestand 0). Das Teil ist DNP/THT und wird ohnehin von Hand bestückt.
- U2 (AZ1117, DNP) und J6 sind als DNP markiert und deshalb nicht im Preis enthalten.
