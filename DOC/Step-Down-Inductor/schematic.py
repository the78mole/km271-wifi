#!/usr/bin/env python3
"""Draws the simulated buck stage (TPS62162 + L1) with schemdraw, IEC 60617 symbols
(same symbol classes as DOC/Power-Analysis/schematics.py).
Run: python3 schematic.py  ->  schematic_l1.svg / schematic_l1.png"""
import os
import math
import schemdraw
import schemdraw.elements as elm
from schemdraw.elements import Element2Term
from schemdraw.elements.sources import Source
from schemdraw.segments import Segment, SegmentPoly, SegmentText

# --- IEC 60617 / DIN EN 60617 symbols ------------------------------------
GAP = (math.nan, math.nan)
H = 0.25  # half plate height


class SourceVIEC(Source):
    """Ideal voltage source (IEC): circle, line along the conductor."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.segments.append(Segment([(0, 0), (1, 0)]))


class SourceIIEC(Source):
    """Ideal current source (IEC): circle, line across the conductor."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.segments.append(Segment([(0.5, -0.5), (0.5, 0.5)]))


class InductorIEC(Element2Term):
    """Inductor (IEC): filled rectangle."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        w, h = 1.0, 0.14
        self.segments.append(Segment([(0, 0), GAP, (w, 0)]))
        self.segments.append(SegmentPoly([(0, -h), (0, h), (w, h), (w, -h)], fill='black'))


class CapacitorIEC(Element2Term):
    """Capacitor (IEC); polar=True: electrolytic, positive plate as open rectangle."""
    def __init__(self, polar=False, **kwargs):
        super().__init__(**kwargs)
        g = 0.2
        if polar:
            t = 0.1
            self.segments.append(Segment([(0, 0), GAP, (g + t, 0)]))
            self.segments.append(SegmentPoly([(0, -H), (0, H), (t, H), (t, -H)]))
            self.segments.append(Segment([(g + t, H), (g + t, -H)]))
            self.segments.append(SegmentText((-0.12, -H - 0.12), '+', fontsize=11))
        else:
            self.segments.append(Segment([(0, 0), GAP, (0, H), (0, -H), GAP, (g, H), (g, -H), GAP, (g, 0)]))


HERE = os.path.dirname(os.path.abspath(__file__))
schemdraw.config(fontsize=11, lw=1.3)


def shunt(d, label, esr=None, polar=False):
    d.push()
    if esr:
        CapacitorIEC(polar=polar).down().length(1.5).label(label, loc="bottom", ofst=0.15)
        elm.ResistorIEC().down().length(1.5).label(esr, loc="bottom", ofst=0.15).scale(0.8)
    else:
        CapacitorIEC(polar=polar).down().length(3).label(label, loc="bottom", ofst=0.15)
    elm.Ground()
    d.pop()


with schemdraw.Drawing(show=False) as d:
    d.config(unit=2)
    elm.Ground()
    SourceVIEC().up().length(3).label("V0\n5,0 V", loc="bottom")
    elm.ResistorIEC().right().length(2.5).label("Ri 1 Ω", loc="top").label("Buderus", loc="bottom", fontsize=9)
    elm.Diode().right().length(2).label("D9\n1N5819WS", loc="top", fontsize=9)
    elm.Dot().label("in5", loc="top")
    shunt(d, "C7\n220 µF\nPolymer", "25 mΩ", polar=True)
    elm.Line().right().length(2.0); elm.Dot()
    shunt(d, "C28, C2\n8,5 µF")
    elm.Line().right().length(2.5)
    hs = elm.Switch().right().label("HS 0,42 Ω", loc="bottom", fontsize=9)
    sw = elm.Dot().label("SW", loc="top")
    d.push()
    ls = elm.Switch().down().label("LS\n0,15 Ω", loc="bottom", fontsize=9)
    elm.Ground()
    d.pop()
    elm.Line().right().length(1.6)
    InductorIEC().right().length(2.2).label("L1: L(I)", loc="top").label("2,2 µH ±20 %", loc="bottom", fontsize=9)
    elm.ResistorIEC().right().length(2.2).label("DCR", loc="top").label("29 / 55 mΩ", loc="bottom", fontsize=9)
    elm.Line().right().length(1.0)
    elm.Dot().label("+3V3", loc="top")
    shunt(d, "C8\n220 µF\nPolymer", "25 mΩ", polar=True)
    elm.Line().right().length(2.0); elm.Dot()
    shunt(d, "C29, C13,\nC5, C14\n31 µF")
    elm.Line().right().length(2.4)
    SourceIIEC().down().length(3).reverse().label("Last\n60…460 mA", loc="bottom")
    elm.Ground()
    elm.EncircleBox([hs, sw, ls], padx=0.4, pady=0.5).linestyle("--").label("U8 TPS62162", loc="top", ofst=0.2)
    elm.Label().at((hs.start[0] - 9.0, hs.start[1] + 3.0)).label(
        "Regelung (Verhaltensmodell): tON = Vout/Vin · 444 ns (min. 80 ns), Einschalten, wenn I(L1) den Talstrom-Sollwert\n"
        "eines PI-Spannungsreglers unterschreitet; Strombegrenzung 1,95 A (max. 2,45 A) + 30 ns Verzug, Freigabe unter 1,2 A;\n"
        "Power-Save-Modus (LS aus) bei I(L1) = 0; 100-%-Modus ab Vout/Vin ≥ 0,97", halign="left", fontsize=10)
    for ext in ("svg", "png"):
        d.save(os.path.join(HERE, f"schematic_l1.{ext}"), dpi=130)
