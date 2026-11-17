#!/usr/bin/env python3
"""Schematic of the exhaust sensor input (IEC symbols). Run: python3 schematic.py"""
import os
import sys
import schemdraw
import schemdraw.elements as elm

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "Power-Analysis"))
from schematics import SourceVIEC, CapacitorIEC  # noqa: E402  (IEC symbols)

schemdraw.config(fontsize=11, lw=1.3)

with schemdraw.Drawing(show=False) as d:
    d.config(unit=2)
    # Logamatic side (assumed): supply at pin 3
    elm.Ground()
    SourceVIEC().up().length(4).label("VS ≈ 5 V\n(Annahme)", loc="bottom")
    elm.Line().right().length(2.2)
    elm.Dot(open=True).label("J1-3", loc="top")
    elm.Line().right().length(1)
    p3 = elm.Dot()
    d.push()
    CapacitorIEC().down().length(4).label("C11\n100n", loc="bottom")
    elm.Ground()
    d.pop()
    elm.ResistorIEC().right().length(4.5).label("R17 3k3", loc="top")
    s = elm.Dot().label("ATS +", loc="top", color="#c05000")
    d.push()
    elm.Thermistor().down().length(4).label("FG (J5)\nNTC ≈100k\n−ϑ", loc="top")
    elm.Ground()
    d.pop()
    elm.Line().right().length(2.6)
    elm.Dot()
    d.push()
    elm.Zener().down().reverse().length(4).label("D5\nBZX84C5V1\nDNP", loc="bottom", color="#d62728").color("#d62728").linestyle("--")
    elm.Ground()
    d.pop()
    elm.ResistorIEC().right().length(3).label("R11 100k", loc="top")
    elm.Dot()
    d.push()
    CapacitorIEC().down().length(4).label("C12\n33n", loc="bottom")
    elm.Ground()
    d.pop()
    elm.Line().right().length(1)
    elm.Dot(open=True).label("J1-7\nU_aus → Logamatic-ADC", loc="right")

    # pin 4 / pin 8
    elm.Label().at((0, -1.4)).label("ATS − (J5-2) = GND = J1-4;  J1-8 → R32 10k → ATS −  (vermutlich Erkennung)", halign="left", fontsize=10)
    elm.Label().at((0, -2.1)).label("Abgassensor-Eingang KM271-WiFi (R33…R40 = 0 Ω weggelassen, Logamatic-Seite angenommen)", halign="left", fontsize=12)
    for ext in ("svg", "png"):
        d.save(os.path.join(HERE, f"schematic_abgas.{ext}"), dpi=130)
