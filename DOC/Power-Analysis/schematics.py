#!/usr/bin/env python3
"""Draws the two simulated supply circuits (old LDO / new buck) with schemdraw.
Run: python3 schematics.py  ->  schematic_ldo.svg/.png, schematic_buck.svg/.png"""
import os
import schemdraw
import schemdraw.elements as elm

HERE = os.path.dirname(os.path.abspath(__file__))
schemdraw.config(fontsize=11, lw=1.3)


def shunt_cap(d, label, esr=None, polar=False):
    """Vertical C (+ optional ESR) from current point down to GND, cursor stays on the rail."""
    d.push()
    if esr:
        elm.Capacitor(polar=polar).down().length(1.5).label(label, loc="bottom", ofst=0.15)
        elm.Resistor().down().length(1.5).label(esr, loc="bottom", ofst=0.15).scale(0.8)
    else:
        elm.Capacitor(polar=polar).down().length(3).label(label, loc="bottom", ofst=0.15)
    elm.Ground()
    d.pop()


def source(d):
    """V0 + Ri, returns with cursor at J1 node."""
    elm.Ground()
    elm.SourceV().up().length(3).label("V0\n5,0 V", loc="bottom")
    elm.Resistor().right().length(2.5).label("Ri 1 Ω", loc="top").label("Buderus\n(LM317 + Leitung + Kontakt)", loc="bottom", fontsize=8)
    elm.Dot(open=True).label("J1", loc="top")


def load(d):
    elm.Line().right().length(2.4)
    d.push()
    elm.SourceI().down().length(3).reverse().label("Last\n60 mA\n+300 mA", loc="bottom")
    elm.Ground()
    d.pop()


def draw_ldo():
    with schemdraw.Drawing(show=False) as d:
        d.config(unit=2)
        source(d)
        elm.Switch().right().length(1.8).label("J3\nJumper", loc="top", fontsize=9)
        elm.Dot().label("+5V", loc="top", color="#c05000")
        shunt_cap(d, "C7\n100µ\nAl", "0,7 Ω", polar=True)
        elm.Line().right().length(1.6)
        elm.Dot()
        shunt_cap(d, "C2\n2µ2")
        elm.Line().right().length(1.6)
        elm.Dot()
        shunt_cap(d, "4×100n")
        elm.Line().right().length(1)
        ldo = elm.Ic(pins=[elm.IcPin(name="IN", side="left"),
                           elm.IcPin(name="OUT", side="right"),
                           elm.IcPin(name="GND", side="bottom")],
                     size=(2.6, 1.8)).anchor("IN").label("U2  AZ1117-3.3", loc="top", fontsize=10)
        d.push()
        d.move_from(ldo.GND); elm.Line().down().length(0.6); elm.Ground()
        d.pop()
        d.move_from(ldo.OUT)
        elm.Line().right().length(1.2)
        elm.Dot()
        shunt_cap(d, "C5\n2µ2")
        elm.Switch().right().length(1.8).label("J3\nJumper", loc="top", fontsize=9)
        elm.Dot().label("+3V3", loc="top", color="#208020")
        shunt_cap(d, "C8\n100µ\nAl", "0,7 Ω", polar=True)
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C13\n22µ")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C14\n2µ2")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "5×100n")
        load(d)
        elm.Label().at((0, -1.3)).label("Alt (bis v0.1.0): Buderus-5V → J3 → AZ1117-LDO → +3V3 (Simulationsmodell)", halign="left", fontsize=12)
        for ext in ("svg", "png"):
            d.save(os.path.join(HERE, f"schematic_ldo.{ext}"), dpi=130)


def draw_buck():
    with schemdraw.Drawing(show=False) as d:
        d.config(unit=2)
        source(d)
        elm.Diode().right().length(2).label("D9\n1N5819WS", loc="top", fontsize=9)
        elm.Dot().label("+5V", loc="top", color="#c05000")
        shunt_cap(d, "C7\n220µ\nPolymer", "25 mΩ", polar=True)
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C28\n10µ")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C2 2µ2\n+4×100n")
        elm.Line().right().length(2.4)
        bk = elm.Ic(pins=[elm.IcPin(name="VIN", side="left", slot="2/2"),
                          elm.IcPin(name="EN", side="left", slot="1/2"),
                          elm.IcPin(name="SW", side="right", slot="2/2"),
                          elm.IcPin(name="VOS", side="right", slot="1/2"),
                          elm.IcPin(name="GND", side="bottom")],
                    size=(2.8, 2.4)).anchor("VIN").label("U8  TPS62162 (3,3 V fix)", loc="top", fontsize=10)
        d.push()
        d.move_from(bk.EN); elm.Line().left().length(0.5); elm.Line().up().toy(bk.VIN); elm.Dot()
        d.pop()
        d.push()
        d.move_from(bk.GND); elm.Line().down().length(0.6); elm.Ground()
        d.pop()
        d.move_from(bk.SW)
        L = elm.Inductor2().right().length(2.2).label("L1 2µ2\n29 mΩ", loc="top", fontsize=9)
        elm.Dot()
        out = d.here
        d.push()
        d.move_from(bk.VOS); elm.Line().right().tox(out); elm.Line().up().toy(out)
        d.pop()
        elm.Line().right().length(1.6); elm.Dot().label("+3V3", loc="top", color="#208020")
        shunt_cap(d, "C29\n22µ")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C8\n220µ\nPolymer", "25 mΩ", polar=True)
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C13\n22µ")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C5\n4µ7")
        elm.Line().right().length(1.6); elm.Dot()
        shunt_cap(d, "C14 2µ2\n6×100n")
        load(d)
        elm.Label().at((0, -1.3)).label("Neu (S3-Stand): Buderus-5V → D9 → TPS62162-Buck → +3V3 (Simulationsmodell)", halign="left", fontsize=12)
        for ext in ("svg", "png"):
            d.save(os.path.join(HERE, f"schematic_buck.{ext}"), dpi=130)


if __name__ == "__main__":
    draw_ldo()
    draw_buck()
