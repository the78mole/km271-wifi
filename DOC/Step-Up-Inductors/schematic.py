#!/usr/bin/env python3
"""Draws the simulated buck stage (TPS62162 + L1) with schemdraw (IEC style).
Run: python3 schematic.py  ->  schematic_l1.svg / schematic_l1.png"""
import os
import schemdraw
import schemdraw.elements as elm

HERE = os.path.dirname(os.path.abspath(__file__))
schemdraw.config(fontsize=11, lw=1.3)
elm.style(elm.STYLE_IEC)


def shunt(d, label, esr=None, polar=False):
    d.push()
    c = elm.Capacitor(polar=polar).down().label(label, loc="bottom")
    d += c
    if esr:
        d += elm.Resistor().down().length(1.5).label(esr, loc="bottom")
    d += elm.Ground()
    d.pop()


with schemdraw.Drawing(show=False) as d:
    d += elm.Ground()
    d += elm.SourceV().up().label("V0\n5,0 V", loc="bottom")
    d += elm.Line().up().length(0.5)
    d += elm.Resistor().right().label("Ri 1 Ω\n(Buderus)")
    d += elm.Diode().right().label("D9\n1N5819WS")
    d += elm.Dot().label("in5", loc="top")
    shunt(d, "C7\n220 µF", "25 mΩ", polar=True)
    d += elm.Line().right().length(2.5)
    d += elm.Dot()
    shunt(d, "C28, C2\n8,5 µF")
    d += elm.Line().right().length(3.0)
    hs = d.add(elm.Switch().right().label("HS 0,42 Ω", loc="bottom"))
    sw = d.add(elm.Dot().label("SW", loc="top"))
    d.push()
    ls = d.add(elm.Switch().down().label("LS\n0,15 Ω", loc="bottom"))
    d += elm.Ground()
    d.pop()
    d += elm.Line().right().length(2.0)
    d += elm.Inductor2(loops=3).right().label("L1: L(I)", loc="top").label("2,2 µH ±20 %", loc="bottom")
    d += elm.Resistor().right().label("DCR", loc="top").label("29 / 55 mΩ", loc="bottom")
    d += elm.Dot().label("+3V3", loc="top")
    shunt(d, "C8\n220 µF", "25 mΩ", polar=True)
    d += elm.Line().right().length(2.5)
    d += elm.Dot()
    shunt(d, "C29, C13,\nC5, C14\n31 µF")
    d += elm.Line().right().length(2.5)
    d += elm.SourceI().down().label("Last\n60…460 mA", loc="bottom")
    d += elm.Ground()
    d += elm.EncircleBox([hs, sw, ls], padx=0.4, pady=0.5).linestyle("--").label("U8 TPS62162", loc="top", ofst=0.2)
    d += elm.Label().at((hs.start[0] - 8.0, hs.start[1] + 3.0)).label(
        "Regelung (Verhaltensmodell): tON = Vout/Vin · 444 ns (min. 80 ns), Einschalten, wenn I(L1) den Talstrom-Sollwert\n"
        "eines PI-Spannungsreglers unterschreitet; Strombegrenzung 1,95 A (max. 2,45 A) + 30 ns Verzug, Freigabe unter 1,2 A;\n"
        "Power-Save-Modus (LS aus) bei I(L1) = 0; 100-%-Modus ab Vout/Vin ≥ 0,97", halign="left", fontsize=10)
    d.save(os.path.join(HERE, "schematic_l1.svg"))
