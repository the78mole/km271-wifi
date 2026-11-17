#!/usr/bin/env python3
"""
KM271-WiFi: L1 of the TPS62162 buck (5 V -> 3.3 V), old vs. new inductor.

  old: Wuerth WE-MAPI 74438356022  2.2 uH, Isat 4.05 A, DCR 29 mOhm (4.1 x 4.1 x 2.0 mm)
  new: cjiang FTC252012S2R2MBCA    2.2 uH, Isat 3.8 A,  DCR 55 mOhm (2.5 x 2.0 x 1.2 mm)

Cycle-by-cycle switching model (no vendor model), explicit integration with 1 ns steps.
Control: DCS-like on-time control (tON = Vout/Vin / 2.25 MHz, min. 80 ns), valley-current
command from a PI voltage loop, cycle-by-cycle current limit ILIMF + (Vin-Vout)*30 ns/L with
low-side release at 1.2 A, diode emulation (power save mode) when the current reaches zero.
Inductor: L(I) = L0 * max(1 - 0.3 (I/Isat)^2, 0.2), i.e. -30 % at Isat, plus DCR.

Run: python3 sim.py   (numpy, matplotlib)  -> PNGs next to this script.
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))

INDUCTORS = {
    "alt: Würth 74438356022": dict(L0=2.2e-6, isat=4.05, dcr=0.029, color="#1f77b4"),
    "neu: cjiang FTC252012S2R2MBCA": dict(L0=2.2e-6, isat=3.8, dcr=0.055, color="#d62728"),
}

# ------------------------------------------------------------- circuit
V0, RI = 5.0, 1.0                       # Buderus 5 V, source impedance (as in DOC/Power-Analysis)
D_IS, D_N, D_RS = 2e-4, 1.74, 0.2       # D9 1N5819WS (same model as DOC/Power-Analysis)
VT = 0.02585
C7, ESR7 = 220e-6, 0.025                # input polymer
CIN = 8.5e-6                            # C28 10u @5V + C2 2u2 + 100n
C8, ESR8 = 220e-6, 0.025                # output polymer
COUT = 31e-6                            # C29 + C13 (22u @3.3V ~11u each), C5, C14, 100n
RHS, RLS = 0.42, 0.15                   # TPS62162 RDS(on) at ~4.5 V
VREF = 3.3
FSW = 2.25e6
TON_MIN, TOFF_MIN = 80e-9, 40e-9
ILIMF, ILIM_LS, TPD = 1.95, 1.2, 30e-9
DT = 1e-9

# diode + Ri lookup: current from V0 as function of v_in5
_vd = np.linspace(-1, 1.5, 2001)
_i = np.zeros_like(_vd)
for k, v in enumerate(_vd):            # solve V0 - vin = Ri*i + n*VT*ln(1+i/Is) + Rs*i
    lo, hi = 0.0, 5.0
    for _ in range(60):
        m = (lo + hi) / 2
        f = (RI + D_RS) * m + D_N * VT * np.log1p(m / D_IS) - v
        lo, hi = (m, hi) if f < 0 else (lo, m)
    _i[k] = (lo + hi) / 2 if v > 0 else 0.0


def i_source(vin):
    return float(np.interp(V0 - vin, _vd, _i))


def L_of(i, L0, isat):
    return L0 * max(1.0 - 0.3 * (i / isat) ** 2, 0.2)


def simulate(ind, t_end, iload, L_scale=1.0, ilimf=ILIMF, rload=None, rec=1, x0=None):
    """iload(t) -> A drawn from +3V3 (or rload in Ohm). Returns dict of arrays."""
    L0, isat, dcr = ind["L0"] * L_scale, ind["isat"], ind["dcr"]
    il0 = iload(0) if rload is None else 0.0
    vout, vc8 = VREF, VREF
    vin = V0 - 0.4 - RI * il0 * 0.75
    vc7 = vin
    il = il0
    xi = il0 if x0 is None else x0      # integrator of the valley command
    kp, ki = 25.0, 25.0 * 2 * np.pi * 4e3
    state, t_sw = 0, 0.0                # 0 = LS on, 1 = HS on, 2 = both off (DCM)
    lim_hold = False
    n = int(t_end / DT)
    out = {k: [] for k in ("t", "il", "vout", "vin", "isrc", "L", "sw")}
    p_dcr = p_sw = e_in = e_out = 0.0
    for s in range(n):
        t = s * DT
        err = VREF - vout
        xi += ki * err * DT
        xi = min(max(xi, -0.3), 2.5)
        icmd = xi + kp * err
        ton = max(min(vout / max(vin, 0.5), 1.0) / FSW, TON_MIN)
        ipk = ilimf + max(vin - vout, 0) * TPD / L0
        # --- switch decisions
        if state == 1:
            if il >= ipk:
                state, t_sw, lim_hold = 0, t, True
            elif t - t_sw >= ton and vout / max(vin, 0.5) < 0.97:   # >= 97 %: 100 % mode
                state, t_sw = 0, t
        else:
            if lim_hold and il < ILIM_LS:
                lim_hold = False
            if state == 0 and il <= 0 and icmd <= 0:
                state = 2                                     # diode emulation (PSM)
            if not lim_hold and t - t_sw >= TOFF_MIN and il <= icmd and icmd > 0:
                state, t_sw = 1, t
        # --- switch node
        if state == 1:
            vsw = vin - RHS * il
        elif state == 0:
            vsw = -RLS * il
        else:
            vsw = vout + dcr * il                             # off: no current change
        L = L_of(il, L0, isat)
        dil = (vsw - vout - dcr * il) / L * DT
        if state == 2:
            dil = 0.0
            il = 0.0
        il += dil
        if state == 0 and il < 0 and icmd <= 0:
            il = 0.0
        # --- output node
        io = (vout / rload) if rload is not None else iload(t)
        i8 = (vout - vc8) / ESR8
        vc8 += i8 / C8 * DT
        vout += (il - io - i8) / COUT * DT
        # --- input node
        isrc = i_source(vin) if s % 10 == 0 or s == 0 else isrc
        ihs = il if state == 1 else 0.0
        i7 = (vin - vc7) / ESR7
        vc7 += i7 / C7 * DT
        vin += (isrc - ihs - 1e-3 - i7) / CIN * DT
        # --- losses
        p_dcr += il * il * dcr * DT
        p_sw += il * il * (RHS if state == 1 else RLS if state == 0 else 0) * DT
        e_in += isrc * V0 * DT
        e_out += io * vout * DT
        if s % rec == 0:
            out["t"].append(t); out["il"].append(il); out["vout"].append(vout); out["vin"].append(vin)
            out["isrc"].append(isrc); out["L"].append(L); out["sw"].append(vsw)
    res = {k: np.array(v) for k, v in out.items()}
    T = n * DT
    res.update(p_dcr=p_dcr / T, p_sw=p_sw / T, p_in=e_in / T, p_out=e_out / T, xi=xi)
    return res


def window(r, t0, t1):
    m = (r["t"] >= t0) & (r["t"] < t1)
    return {k: (v[m] if isinstance(v, np.ndarray) else v) for k, v in r.items()}


# ------------------------------------------------------------- scenarios
def steady(fname):
    """460 mA continuous load: inductor current and output ripple."""
    fig, ax = plt.subplots(3, 1, figsize=(10, 8.5), sharex=True)
    stats = {}
    for name, ind in INDUCTORS.items():
        r = simulate(ind, 140e-6, lambda t: 0.46)
        w = window(r, 120e-6, 140e-6)
        tt = (w["t"] - 120e-6) * 1e6
        m = tt < 4
        ax[0].plot(tt[m], w["il"][m] * 1e3, color=ind["color"], label=name)
        ax[1].plot(tt[m], (w["vout"][m] - VREF) * 1e3, color=ind["color"], label=name)
        ax[2].plot(tt[m], w["L"][m] * 1e6, color=ind["color"], label=name)
        stats[name] = dict(il_pp=np.ptp(w["il"]) * 1e3, il_pk=w["il"].max() * 1e3,
                           vout_pp=np.ptp(w["vout"]) * 1e3, vout_mean=w["vout"].mean(),
                           vin_mean=w["vin"].mean(), L_min=w["L"].min() * 1e6)
    ax[0].set_ylabel("Spulenstrom [mA]"); ax[1].set_ylabel("+3V3 − 3,3 V [mV]")
    ax[2].set_ylabel("L(I) [µH]"); ax[2].set_xlabel("Zeit [µs]")
    ax[0].set_title("Dauerlast 460 mA, V0 = 5,0 V, Ri = 1 Ω (eingeschwungen)")
    for a in ax: a.grid(alpha=.3); a.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return stats


def load_step(fname):
    """60 -> 460 mA step (ESP32-S3 WiFi TX) and back."""
    t1, t2, tend = 50e-6, 250e-6, 400e-6
    def iload(t):
        if t < t1: return 0.06
        if t < t1 + 1e-6: return 0.06 + 0.4 * (t - t1) / 1e-6
        if t < t2: return 0.46
        if t < t2 + 1e-6: return 0.46 - 0.4 * (t - t2) / 1e-6
        return 0.06
    fig, ax = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    stats = {}
    for name, ind in INDUCTORS.items():
        r = simulate(ind, tend, iload, rec=5)
        tt = r["t"] * 1e6
        ax[0].plot(tt, r["il"] * 1e3, color=ind["color"], lw=.6, label=name)
        ax[1].plot(tt, r["vout"], color=ind["color"], lw=.8, label=name)
        w = window(r, t1, t2)
        stats[name] = dict(vmin=w["vout"].min(), vmax=window(r, t2, tend)["vout"].max(),
                           il_pk=r["il"].max() * 1e3)
    ax[0].set_ylabel("Spulenstrom [mA]"); ax[1].set_ylabel("+3V3 [V]"); ax[1].set_xlabel("Zeit [µs]")
    ax[0].set_title("Lastsprung 60 → 460 mA → 60 mA (Flanke 1 µs)")
    for a in ax: a.grid(alpha=.3); a.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return stats


def overload(fname):
    """Short circuit 0.1 Ohm on +3V3 with ILIMF at its maximum 2.45 A, incl. L -20 %."""
    fig, ax = plt.subplots(2, 1, figsize=(10, 7), sharex=True)
    stats = {}
    for name, ind in INDUCTORS.items():
        for scale, ls in ((1.0, "-"), (0.8, ":")):
            r = simulate(ind, 60e-6, None, L_scale=scale, ilimf=2.45, rload=0.1, x0=2.5)
            w = window(r, 50e-6, 60e-6)
            tt = (w["t"] - 50e-6) * 1e6
            m = tt < 4
            lab = f"{name}, L {'nominal' if scale == 1 else '−20 %'}"
            ax[0].plot(tt[m], w["il"][m], color=ind["color"], ls=ls, label=lab)
            ax[1].plot(tt[m], w["L"][m] * 1e6, color=ind["color"], ls=ls, label=lab)
            stats[lab] = dict(il_pk=w["il"].max(), L_min=w["L"].min() * 1e6,
                              drop=100 * (1 - w["L"].min() / (ind["L0"] * scale)))
    ax[0].axhline(2.45, color="#999", ls="--", lw=1, label="ILIMF max. 2,45 A")
    ax[0].set_ylabel("Spulenstrom [A]"); ax[1].set_ylabel("L(I) [µH]"); ax[1].set_xlabel("Zeit [µs]")
    ax[0].set_title("Kurzschluss 0,1 Ω an +3V3, Strombegrenzung am oberen Datenblattwert 2,45 A")
    for a in ax: a.grid(alpha=.3); a.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return stats


def losses(fname):
    """DCR and switch conduction losses vs. load (core/AC losses not modelled)."""
    loads = [0.05, 0.1, 0.2, 0.3, 0.4, 0.46, 0.53, 0.6]   # above ~0.65 A Ri = 1 Ohm forces 100 % mode
    res = {}
    for name, ind in INDUCTORS.items():
        rows = []
        for i in loads:
            r = simulate(ind, 90e-6, lambda t, i=i: i)
            # evaluate losses on the second half only
            r2 = simulate(ind, 40e-6, lambda t, i=i: i, x0=r["xi"])
            # loss accounting (robust against the slow input-capacitor settling):
            # buck input power = output + DCR + switch conduction + 1 mA quiescent
            vin = r2["vin"].mean()
            p_buck_in = r2["p_out"] + r2["p_dcr"] + r2["p_sw"] + vin * 1e-3
            i_in = p_buck_in / vin
            rows.append((i, r2["p_dcr"] * 1e3, r2["p_sw"] * 1e3, r2["p_out"] / (V0 * i_in) * 100,
                         r2["p_out"] / p_buck_in * 100))
        res[name] = rows
    fig, ax = plt.subplots(1, 2, figsize=(11, 4.2))
    for name, rows in res.items():
        a = np.array(rows); c = INDUCTORS[name]["color"]
        ax[0].plot(a[:, 0] * 1e3, a[:, 1], marker="o", ms=3, color=c, label=name)
        ax[1].plot(a[:, 0] * 1e3, a[:, 4], marker="o", ms=3, color=c, label=f"{name}, Buck")
        ax[1].plot(a[:, 0] * 1e3, a[:, 3], marker="s", ms=3, ls="--", color=c, label=f"{name}, ab Buderus (Ri, D9)")
    ax[0].set_xlabel("Last an +3V3 [mA]"); ax[0].set_ylabel("Verlust in der DCR [mW]")
    ax[1].set_xlabel("Last an +3V3 [mA]"); ax[1].set_ylabel("Wirkungsgrad [%]")
    ax[0].set_title("Kupferverluste L1"); ax[1].set_title("Wirkungsgrad (nur Leitverluste + 1 mA Iq)")
    for a in ax: a.grid(alpha=.3); a.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return res


def lcurve(fname):
    i = np.linspace(0, 5, 200)
    fig, ax = plt.subplots(figsize=(8, 4))
    for name, ind in INDUCTORS.items():
        ax.plot(i, [L_of(x, ind["L0"], ind["isat"]) * 1e6 for x in i], color=ind["color"], label=name)
        ax.plot(i, [L_of(x, ind["L0"] * 0.8, ind["isat"]) * 1e6 for x in i], color=ind["color"], ls=":",
                label=f"{name}, −20 %")
    for x, lab in ((0.6, "Betrieb ≈0,6 A"), (2.5, "Strombegrenzung ≈2,5 A")):
        ax.axvline(x, color="#777", ls="--", lw=1); ax.text(x + 0.05, 2.45, lab, fontsize=8)
    ax.set_xlabel("Spulenstrom [A]"); ax.set_ylabel("L [µH]"); ax.set_ylim(0.8, 2.6)
    ax.set_title("Angenommene Sättigungskennlinie L(I) = L0·(1 − 0,3·(I/Isat)²)")
    ax.grid(alpha=.3); ax.legend(fontsize=8, loc="lower left")
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)


if __name__ == "__main__":
    lcurve("l_kennlinie.png")
    print("STEADY", steady("dauerlast_460mA.png"))
    print("STEP", load_step("lastsprung.png"))
    print("OVERLOAD", overload("ueberlast.png"))
    for k, rows in losses("verluste.png").items():
        print(k)
        for r in rows: print("  %.2f A  Pdcr %.1f mW  Psw %.1f mW  eta_total %.1f %%  eta_buck %.1f %%" % r)
