# L1 im 3V3-Wandler: alte gegen neue Speicherdrossel

Diese Seite vergleicht per Simulation die bisherige und die neue Speicherdrossel L1 des Abwärtswandlers U8 (TPS62162, 5 V → 3,3 V).

| | alt | neu |
|---|---|---|
| Typ | Würth WE-MAPI 74438356022 | cjiang FTC252012S2R2MBCA |
| LCSC | C5521727 | C5832372 |
| Bauform | 4,1 × 4,1 × 2,0 mm | 2,5 × 2,0 × 1,2 mm (1008), molded, geschirmt |
| Induktivität | 2,2 µH ±20 % | 2,2 µH ±20 % |
| Isat | 4,05 A | 3,8 A |
| DCR | 29 mΩ | 55 mΩ |
| Preis (JLC) | 1,73 USD | 0,035 USD |

## Ergebnis

- **Im Betrieb sind beide Drosseln praktisch gleichwertig.** Bei 460 mA Dauerlast (ESP32-S3 sendet) unterscheiden sich Rippelstrom (118 / 116 mA Spitze-Spitze), Spitzenstrom (518 / 516 mA) und Ausgangsrippel (0,25 / 0,24 mV) kaum. Die Induktivität sinkt bei 0,52 A nur um 0,5 %.
- **Lastsprung 60 → 460 mA:** Bei beiden Drosseln fällt +3V3 auf 3,290 V und steigt beim Lastabwurf auf 3,311 V. Die Kurven liegen übereinander.
- **Verluste:** Der höhere DCR der neuen Drossel kostet bei 460 mA **11,7 statt 6,2 mW**, also 5,5 mW mehr. Der Wirkungsgrad des Wandlers sinkt dadurch um etwa 0,3 Prozentpunkte (94,1 statt 94,4 % ohne Schalt- und Kernverluste). Ab der Buderus-5V gerechnet (inklusive Ri und D9) sind es 80,0 statt 80,3 %.
- **Kurzschluss mit Strombegrenzung am oberen Datenblattwert (2,45 A):** Der Spulenstrom erreicht bei beiden etwa 2,5 A. Die Induktivität sinkt dabei um 11,5 % (alt) bzw. 13 % (neu). Selbst mit −20 % Toleranz bleiben 1,56 bzw. 1,53 µH. Keine der beiden Drosseln geht in die harte Sättigung.

Die neue Drossel ist damit für diese Anwendung ohne Einschränkung geeignet.

## Simulierte Schaltung

![Schaltbild](Step-Down-Inductor/schematic_l1.png)

Die Quelle ist dieselbe wie in der [Versorgungsanalyse](Power-Analysis/README.md): Buderus-5V mit 5,0 V Leerlauf und 1 Ω Innenwiderstand, dahinter D9. Die Kondensatoren sind zusammengefasst (Vektorfassung: [schematic_l1.svg](Step-Down-Inductor/schematic_l1.svg)).

| Teil | Modell |
|---|---|
| Quelle | V0 = 5,0 V, Ri = 1 Ω, D9 1N5819WS (IS = 0,2 mA, N = 1,74, RS = 0,2 Ω) |
| Eingang | C7 220 µF Polymer (25 mΩ ESR), C28 + C2 ≈ 8,5 µF effektiv |
| U8 | Schalter HS 0,42 Ω / LS 0,15 Ω (RDS(on) bei ~4,5 V), Verhaltensmodell der DCS-Control-Regelung (siehe Schaltbild) |
| L1 | L(I) = L0 · max(1 − 0,3 · (I/Isat)², 0,2) plus DCR, also −30 % bei Isat |
| Ausgang | C8 220 µF Polymer (25 mΩ ESR), C29, C13, C5, C14 ≈ 31 µF effektiv |
| Last | Stromsenke 60 mA bzw. 460 mA, im Kurzschlussfall 0,1 Ω |

Das Modell schaltet Zyklus für Zyklus und wird mit 1 ns Schrittweite gerechnet. Herstellermodelle werden nicht verwendet. Die Sättigungskennlinie ist angenommen, weil die Datenblätter nur Isat bei 30 % Abfall angeben. Die Form gilt für geformte Metallpulver-Drosseln, die weich sättigen, und beide Drosseln gehören zu dieser Bauart.

![Kennlinie](Step-Down-Inductor/l_kennlinie.png)

Im Betrieb (≈0,6 A) liegen beide Kurven aufeinander. Erst in der Strombegrenzung (≈2,5 A) wird der Unterschied von 4,05 zu 3,8 A Isat sichtbar, und auch dort beträgt er nur etwa 1,5 %.

## Dauerlast 460 mA

![Dauerlast](Step-Down-Inductor/dauerlast_460mA.png)

| | alt | neu |
|---|---:|---:|
| Eingangsspannung U8 | 4,24 V | 4,24 V |
| Spulenstrom Spitze-Spitze | 118 mA | 116 mA |
| Spitzenstrom | 518 mA | 516 mA |
| Ausgangsrippel | 0,25 mV | 0,24 mV |
| kleinste Induktivität | 2,189 µH | 2,188 µH |

Mit −20 % Induktivität (Toleranzgrenze, gilt für beide Typen gleich) steigt der Rippelstrom um etwa 25 % auf rund 148 mA, und der Spitzenstrom liegt dann bei etwa 0,53 A. Das ist weit unter beiden Isat-Werten. Der sehr kleine Ausgangsrippel ergibt sich aus dem idealisierten Ausgang ohne ESL und Leiterbahnen. Auf der Platine misst man mehr, und zwar für beide Drosseln gleich viel.

## Lastsprung

![Lastsprung](Step-Down-Inductor/lastsprung.png)

| | alt | neu |
|---|---:|---:|
| Minimum nach 60 → 460 mA | 3,290 V | 3,290 V |
| Maximum nach 460 → 60 mA | 3,311 V | 3,311 V |
| größter Spulenstrom | 571 mA | 570 mA |

Bei 60 mA arbeitet der Wandler im Power-Save-Modus (lückender Strom). Die Sprungantwort bestimmt der Regler zusammen mit den Ausgangskondensatoren, die Drossel spielt dabei keine Rolle.

## Kurzschluss und Strombegrenzung

![Kurzschluss](Step-Down-Inductor/ueberlast.png)

Die Strombegrenzung ist auf den oberen Datenblattwert ILIMF = 2,45 A gesetzt. Dazu kommen 30 ns Abschaltverzug. Nach dem Abschalten bleibt der High-Side-Schalter aus, bis der Strom unter 1,2 A gefallen ist.

| | Spitzenstrom | kleinste L | Abfall |
|---|---:|---:|---:|
| alt, L nominal | 2,50 A | 1,95 µH | 11,5 % |
| alt, L −20 % | 2,52 A | 1,56 µH | 11,6 % |
| neu, L nominal | 2,50 A | 1,91 µH | 13,0 % |
| neu, L −20 % | 2,52 A | 1,53 µH | 13,2 % |

Der Spitzenstrom wird von der Strombegrenzung und nicht von der Drossel bestimmt. Beide Drosseln behalten auch hier deutlich mehr als 2/3 ihrer Induktivität, sodass der Strom kontrolliert ansteigt.

## Verluste und Wirkungsgrad

![Verluste](Step-Down-Inductor/verluste.png)

| Last an +3V3 | DCR-Verlust alt | DCR-Verlust neu | Wandler alt | Wandler neu | ab Buderus alt | ab Buderus neu |
|---:|---:|---:|---:|---:|---:|---:|
| 100 mA | 0,4 mW | 0,7 mW | 97,2 % | 97,1 % | 88,1 % | 88,1 % |
| 300 mA | 2,7 mW | 5,1 mW | 96,1 % | 95,9 % | 84,1 % | 83,9 % |
| 460 mA | 6,2 mW | 11,7 mW | 94,4 % | 94,1 % | 80,3 % | 80,0 % |
| 600 mA | 10,5 mW | 19,9 mW | 92,9 % | 92,4 % | 76,9 % | 76,5 % |

Gerechnet sind nur die Leitverluste in DCR und Schaltern sowie 1 mA Eigenstrom, ohne Schalt-, Gate- und Kernverluste. Die absoluten Wirkungsgrade liegen deshalb etwas zu hoch, für den Vergleich der Drosseln ist das unerheblich. Die Kernverluste hängen vom Material ab und sind in keinem der Datenblätter für 2,25 MHz angegeben. Ab etwa 0,65 A geht der Wandler bei Ri = 1 Ω in den 100-%-Modus, weil die Buderus-Spannung zu weit einbricht. Deshalb endet die Kurve bei 600 mA.

Der Mehrverlust von 5,5 mW bei 460 mA ändert den Strom aus der Buderus um etwa 1,3 mA und die Spannung im 100-%-Modus um etwa 12 mV.

## Reproduzieren

```bash
cd DOC/Step-Down-Inductor
python3 sim.py        # Plots, Zahlen auf stdout (numpy, matplotlib, ~10 s)
python3 schematic.py  # Schaltbild als SVG (schemdraw); das PNG ist daraus gerendert
```

## Gegenprobe mit dem TI-PSpice-Modell

Zur Kontrolle des vereinfachten Modells oben wurde dieselbe Schaltung zusätzlich mit dem Transientenmodell von Texas Instruments gerechnet (TPS62162 PSpice Unencrypted Transient Model, SLVM430B, „TPS62162_TRANS“). Es läuft in ngspice im PSpice-Kompatibilitätsmodus. Quelle, Eingangs- und Ausgangskondensatoren sind wie oben. U8 ist durch das TI-Modell ersetzt (EN an VIN, FB an GND für die Festspannung, PG über 100 kΩ an +3V3), und L1 ist dieselbe nichtlineare Drossel L(I) mit DCR. Das TI-Modell selbst liegt wegen der TI-Lizenz nicht im Repository, das Skript lädt es beim ersten Lauf von ti.com.

Jeder Lauf enthält nacheinander den Anlauf mit 60 mA Last, bei 1,2 ms den Lastsprung auf 460 mA, bei 1,6 ms den Sprung zurück auf 60 mA und ab 1,9 ms einen Kurzschluss von 0,1 Ω an +3V3. Gerechnet wurden beide Drosseln, jeweils mit nominaler Induktivität und mit −20 %.

![Ablauf TI-Modell](Step-Down-Inductor/ti_ablauf.png)

![Details TI-Modell](Step-Down-Inductor/ti_details.png)

### Ergebnisse

| | alt | neu | alt, L −20 % | neu, L −20 % |
|---|---:|---:|---:|---:|
| Anlauf: größter Spulenstrom | 1,87 A | 1,78 A | 1,88 A | 1,80 A |
| Anlauf: kleinste VIN an U8 | 3,72 V | 3,71 V | 3,72 V | 3,71 V |
| 460 mA: Schaltfrequenz | 1,01 MHz | 1,00 MHz | 1,01 MHz | 1,00 MHz |
| 460 mA: Rippelstrom Spitze-Spitze | 299 mA | 299 mA | 374 mA | 373 mA |
| 460 mA: Spitzenstrom | 607 mA | 607 mA | 644 mA | 643 mA |
| 460 mA: Ausgangsrippel | 1,18 mV | 1,19 mV | 1,48 mV | 1,49 mV |
| 460 mA: Verlust in der DCR | 6,4 mW | 12,1 mW | 6,5 mW | 12,3 mW |
| Lastsprung: Minimum +3V3 | 3,294 V | 3,294 V | 3,294 V | 3,294 V |
| Lastabwurf: Maximum +3V3 | 3,305 V | 3,305 V | 3,305 V | 3,305 V |
| Kurzschluss: größter Spulenstrom | 1,77 A | 1,77 A | 1,79 A | 1,79 A |

- **Auch mit dem TI-Modell verhalten sich beide Drosseln im Betrieb gleich.** Spannungen, Rippel und Lastsprung unterscheiden sich nur in der dritten Nachkommastelle. Der einzige messbare Unterschied ist der DCR-Verlust von 12,1 statt 6,4 mW bei 460 mA.
- **Höchster Spulenstrom überhaupt sind 1,88 A beim Anlauf.** Der TPS62162 lädt dann die gut 250 µF am Ausgang in etwa 0,7 ms mit seiner Strombegrenzung auf. Bei diesem Strom ist die Induktivität beider Drosseln nur um etwa 6,5 % gesunken, und auch im Kurzschluss bleibt der Strom bei höchstens 1,79 A. Beide Werte liegen weit unter Isat (3,8 bzw. 4,05 A).
- **Beim Anlauf bricht VIN an U8 auf etwa 3,7 V ein.** Das liegt an Ri und D9, nicht an der Drossel, und ist für beide Varianten gleich. +3V3 läuft trotzdem sauber hoch und schwingt nur leicht über, auf 3,36 V (alt) bzw. 3,38 V (neu).

### Vergleich mit dem vereinfachten Modell

| | vereinfachtes Modell (oben) | TI-Modell |
|---|---:|---:|
| Schaltfrequenz bei 460 mA | ≈2,4 MHz | ≈1,0 MHz |
| Rippelstrom bei 460 mA | 116 bis 118 mA | 299 mA |
| Spitzenstrom bei 460 mA | 0,52 A | 0,61 A |
| Minimum beim Lastsprung | 3,290 V | 3,294 V |
| Spitzenstrom im Kurzschluss | 2,50 A (Grenze auf 2,45 A gesetzt) | 1,77 A (typische Grenze) |
| DCR-Verlust alt / neu bei 460 mA | 6,2 / 11,7 mW | 6,4 / 12,1 mW |

Das TI-Modell schaltet bei 4,3 V Eingangsspannung nur mit etwa 1 MHz. Das passt zum Datenblatt: Die DCS-Control-Regelung senkt die Frequenz, wenn die Eingangsspannung nahe an der Ausgangsspannung liegt. Das vereinfachte Modell hält dagegen etwa 2,4 MHz und unterschätzt deshalb den Rippelstrom um den Faktor 2,5. Der Kurzschluss im vereinfachten Modell war absichtlich mit der oberen Stromgrenze von 2,45 A gerechnet und ist damit der strengere Fall.

Die Schlussfolgerung bleibt in beiden Modellen dieselbe. Der Spitzenstrom im Betrieb liegt höchstens bei etwa 0,65 A, im Anlauf und im Kurzschluss bei unter 1,9 A. Beide Drosseln sind dafür reichlich ausgelegt, und die neue cjiang FTC252012S2R2MBCA kostet nur 5 bis 6 mW mehr Kupferverluste.

### Reproduzieren

```bash
cd DOC/Step-Down-Inductor
python3 ti_spice.py          # lädt das TI-Modell, 4 ngspice-Läufe parallel (~20 min, ~1,5 GB temporär)
python3 ti_spice.py --plot   # nur neu auswerten und plotten
```

Benötigt ngspice ab Version 39 (PSpice-Kompatibilität `set ngbehavior=psa`, schreibt das Skript selbst in `ti_work/.spiceinit`).
