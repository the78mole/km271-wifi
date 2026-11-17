#!/usr/bin/env python3
"""
KM271-WiFi exhaust gas temperature input (J5 "ATS"): output voltage vs. exhaust temperature,
with and without zener D5 (BZX84C5V1, normally not populated).

Assumed Logamatic side (not documented by Buderus):
  J1 pin 3  -> R35 0R -> C11 / R17 3k3 -> sensor (+)     : supply of the divider, VS = 5.0 V
  J1 pin 7  <- R39 0R <- C12 / R11 100k <- sensor (+)    : measurement input (high impedance)
  J1 pin 4  -> R36 0R -> sensor (-) = GND reference
  J1 pin 8  -> R40 0R -> R32 10k -> sensor (-)           : (presumably) module / sensor detection
Run: python3 abgas.py   (numpy, matplotlib)
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))

VS = 5.0        # supply at J1 pin 3 (assumption)
R17 = 3.3e3     # series / pull-up resistor
R11 = 100e3     # series resistor to measurement pin 7
RIN = 1e9       # input resistance of the Logamatic ADC at pin 7 (assumed high-Z)

# --- sensor FG (digitised from Buderus service manual, see fg_kennlinie.csv)
tab = np.loadtxt(os.path.join(HERE, "fg_kennlinie.csv"), delimiter=",", comments="#")
T_TAB, R_TAB = tab[:, 0], tab[:, 1]


def r_ntc(t):
    return np.exp(np.interp(t, T_TAB, np.log(R_TAB)))


# --- zener BZX84C5V1: VZ = 4.8 / 5.1 / 5.4 V @ 5 mA (min/typ/max), soft knee
#     I = 5 mA * exp((V - VZ) / 0.109 V)  ->  ~50 uA at VZ - 0.5 V, ~1 uA at VZ - 0.9 V
def i_zener(v, vz):
    return 5e-3 * np.exp((v - vz) / 0.109)


def v_out(t, vz=None):
    """Node voltage at sensor (+) / pin 7, solved by bisection."""
    rn = r_ntc(t)
    rl = 1 / (1 / rn + 1 / (R11 + RIN))       # NTC parallel to measurement path
    lo, hi = 0.0, VS
    for _ in range(60):
        v = 0.5 * (lo + hi)
        i_in = (VS - v) / R17
        i_out = v / rl + (i_zener(v, vz) if vz else 0.0)
        if i_in > i_out:
            lo = v
        else:
            hi = v
    return v * RIN / (R11 + RIN)               # pin 7 (practically = sensor voltage)


def t_from_v(v, tgrid, vref):
    """Temperature the Logamatic would derive from v, using the curve without D5."""
    return np.interp(v, vref[::-1], tgrid[::-1])


if __name__ == "__main__":
    t = np.linspace(0, 250, 501)
    v0 = np.array([v_out(x) for x in t])
    vz = {k: np.array([v_out(x, z) for x in t]) for k, z in (("min", 4.8), ("typ", 5.1), ("max", 5.4))}

    # 1) sensor curve
    fig, ax = plt.subplots(figsize=(8, 4.2))
    ax.semilogy(T_TAB, R_TAB / 1e3, "o", ms=3, label="digitalisiert (Buderus FG)")
    ax.semilogy(t, r_ntc(t) / 1e3, "-", lw=1.2, label="interpoliert")
    ax.set_xlabel("Abgastemperatur [°C]"); ax.set_ylabel("Widerstand [kΩ]")
    ax.set_title("Abgastemperaturfühler FG (NTC, ≈100 kΩ @ 25 °C)")
    ax.grid(which="both", alpha=.3); ax.legend()
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "fg_kennlinie.png"), dpi=110); plt.close(fig)

    # 2) output voltage vs temperature
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.plot(t, v0, lw=2.2, color="#1f77b4", label="ohne D5 (Standard, unbestückt)")
    ax.fill_between(t, vz["min"], vz["max"], color="#d62728", alpha=.15, label="mit D5, Toleranz VZ 4,8…5,4 V")
    ax.plot(t, vz["typ"], lw=2, color="#d62728", label="mit D5 (BZX84C5V1, VZ typ. 5,1 V)")
    ax.set_xlabel("Abgastemperatur [°C]"); ax.set_ylabel("Ausgangsspannung an J1 Pin 7 [V]")
    ax.set_title(f"Abgassensor-Eingang: VS = {VS:.1f} V an Pin 3, R17 = 3,3 kΩ, R11 = 100 kΩ")
    ax.axvspan(50, 250, color="#999", alpha=.07)
    ax.text(150, 0.15, "Einstellbereich Abgas-Schwelle 50…250 °C", ha="center", fontsize=8, color="#555")
    ax.set_xlim(0, 250); ax.set_ylim(0, 5.2); ax.grid(alpha=.3); ax.legend()
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "abgas_spannung.png"), dpi=110); plt.close(fig)

    # 3) apparent temperature error caused by D5
    fig, ax = plt.subplots(figsize=(9, 4.2))
    for k, c in (("min", "#ff9896"), ("typ", "#d62728"), ("max", "#8c1c1c")):
        ax.plot(t, t_from_v(vz[k], t, v0) - t, color=c, label=f"mit D5, VZ {k}")
    ax.axhline(0, color="#1f77b4", lw=1, label="ohne D5")
    ax.set_xlabel("tatsächliche Abgastemperatur [°C]"); ax.set_ylabel("Anzeigefehler [K]")
    ax.set_title("Wie viel zu warm die Logamatic mit bestückter D5 anzeigen würde")
    ax.set_xlim(0, 250); ax.grid(alpha=.3); ax.legend()
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "abgas_fehler_d5.png"), dpi=110); plt.close(fig)

    # table
    print("T[°C]  R_NTC[kΩ]  U ohne D5  U mit D5 (min/typ/max)  Fehler typ [K]")
    for T in (0, 20, 25, 40, 50, 60, 70, 80, 100, 120, 150, 200, 250):
        i = np.argmin(abs(t - T))
        err = t_from_v(vz["typ"][i], t, v0) - T
        print(f"{T:5d} {r_ntc(T)/1e3:9.2f} {v0[i]:9.3f}   {vz['min'][i]:.3f}/{vz['typ'][i]:.3f}/{vz['max'][i]:.3f}   {err:6.1f}")
    print("I(R17) max at 250 °C: %.2f mA" % ((VS - v0[-1]) / R17 * 1e3))
