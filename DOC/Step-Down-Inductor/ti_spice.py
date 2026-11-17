#!/usr/bin/env python3
"""
Cross-check of DOC/Step-Down-Inductor/sim.py with TI's PSpice transient model of the
TPS62162 (SLVM430B, "TPS62162_TRANS", unencrypted), run in ngspice (PSpice compatibility).

The TI model is not part of this repository (TI licence).  The script downloads it from
https://www.ti.com/lit/zip/slvm430 into ./ti_model/ on the first run.

Circuit: same as sim.py (V0 5 V, Ri 1 Ohm, D9, C7/C28, C8/C29/C13/C5/C14), TPS62162 with
FB to GND (fixed 3.3 V), EN = VIN, PG via 100k to +3V3.  L1 is a nonlinear inductor
L(I) = L0 * max(1 - 0.3 (I/Isat)^2, 0.2) plus DCR, built from a B-source integrator.
Sequence (one run per inductor): start-up with 60 mA, 1.2 ms step to 460 mA,
1.6 ms back to 60 mA, 1.9 ms short circuit 0.1 Ohm on +3V3, end 2.15 ms.

Run:  python3 ti_spice.py            (4 ngspice runs in parallel, ~12 min, ~1.5 GB temp files)
      python3 ti_spice.py --plot     (only re-plot from ./ti_work/*.npz)
Needs ngspice (>= 39), numpy, matplotlib.
"""
import io, os, sys, subprocess, urllib.request, zipfile
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(HERE, "ti_model")
WORK = os.path.join(HERE, "ti_work")
LIB = os.path.join(MODEL_DIR, "TPS62162_TRANS.lib")

CASES = {
    "alt":   dict(label="alt: Würth 74438356022", L0=2.2e-6, isat=4.05, dcr=0.029, color="#1f77b4", ls="-"),
    "neu":   dict(label="neu: cjiang FTC252012S2R2MBCA", L0=2.2e-6, isat=3.8, dcr=0.055, color="#d62728", ls="-"),
    "alt80": dict(label="alt, L −20 %", L0=1.76e-6, isat=4.05, dcr=0.029, color="#1f77b4", ls=":"),
    "neu80": dict(label="neu, L −20 %", L0=1.76e-6, isat=3.8, dcr=0.055, color="#d62728", ls=":"),
}
T_STEP_UP, T_STEP_DN, T_SHORT, T_END = 1.2e-3, 1.6e-3, 1.9e-3, 2.15e-3


def fetch_model():
    if os.path.exists(LIB):
        return
    os.makedirs(MODEL_DIR, exist_ok=True)
    req = urllib.request.Request("https://www.ti.com/lit/zip/slvm430", headers={"User-Agent": "Mozilla/5.0"})
    data = urllib.request.urlopen(req, timeout=60).read()
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        name = next(n for n in z.namelist() if n.endswith("TPS62162_TRANS.lib"))
        open(LIB, "wb").write(z.read(name))


def netlist(key, c):
    return f"""* TPS62162 (TI PSpice model) + L1 {key}
.include {LIB}
V0 v0 0 5.0
Ri v0 slot 1
D9 slot in5 DSCH
.model DSCH D(IS=2e-4 N=1.74 RS=0.2 CJO=50p)
C7 in5 c7n 220u
R7 c7n 0 25m
C28 in5 0 8.5u
XU8 in5 in5 0 0 0 pg 0 o3 sw TPS62162_TRANS
Rpg pg o3 100k
* L1: state node il carries the inductor current (1 V = 1 A)
Cil il 0 1
Bil 0 il I = (V(sw)-V(o3)-{c['dcr']}*V(il)) / ({c['L0']}*max(1-0.3*(V(il)/{c['isat']})**2, 0.2))
Bl sw o3 I = V(il)
C8 o3 c8n 220u
R8 c8n 0 25m
Cout o3 0 31u
Iload o3 0 PWL(0 0.06 {T_STEP_UP} 0.06 {T_STEP_UP + 1e-6} 0.46 {T_STEP_DN} 0.46 {T_STEP_DN + 1e-6} 0.06)
Sshort o3 0 ctl 0 SWS
.model SWS SW(RON=0.1 ROFF=1G VT=0.5 VH=0.1)
Vctl ctl 0 PWL(0 0 {T_SHORT} 0 {T_SHORT + 1e-7} 1)
.save V(o3) V(il) V(in5) V(slot) V(sw)
.tran 2n {T_END} 0 5n
.control
run
wrdata {key}.txt V(o3) V(il) V(in5) V(slot) V(sw)
.endc
.end
"""


def run_all():
    fetch_model()
    os.makedirs(WORK, exist_ok=True)
    open(os.path.join(WORK, ".spiceinit"), "w").write("set ngbehavior=psa\n")
    procs = []
    for k, c in CASES.items():
        open(os.path.join(WORK, f"{k}.cir"), "w").write(netlist(k, c))
        procs.append(subprocess.Popen(["ngspice", "-b", f"{k}.cir"], cwd=WORK,
                                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
    for p in procs:
        p.wait()
    for k in CASES:
        convert(os.path.join(WORK, f"{k}.txt"), os.path.join(WORK, f"{k}.npz"))


def convert(txt, npz):
    a = np.loadtxt(txt)
    np.savez_compressed(npz, t=a[:, 0], vout=a[:, 1], il=a[:, 3], vin=a[:, 5],
                        islot=5.0 - a[:, 7], vsw=a[:, 9])
    os.remove(txt)


def load(k):
    return dict(np.load(os.path.join(WORK, f"{k}.npz")))


def win(r, t0, t1):
    m = (r["t"] >= t0) & (r["t"] < t1)
    return {k: v[m] for k, v in r.items()}


def L_of(i, c):
    return c["L0"] * np.maximum(1 - 0.3 * (i / c["isat"]) ** 2, 0.2)


def mean_t(w, x):
    """time-weighted mean (ngspice uses a variable time step)"""
    return np.trapezoid(x, w["t"]) / (w["t"][-1] - w["t"][0])


def analyse():
    R = {k: load(k) for k in CASES}
    stats = {}
    for k, r in R.items():
        c = CASES[k]
        su = win(r, 0, 1.0e-3)
        ss = win(r, T_STEP_DN - 100e-6, T_STEP_DN - 5e-6)       # 460 mA, settled
        st = win(r, T_STEP_UP, T_STEP_DN)
        sd = win(r, T_STEP_DN, T_SHORT)
        sc = win(r, T_SHORT, T_END)
        p_dcr = mean_t(ss, ss["il"] ** 2) * c["dcr"]
        stats[k] = dict(
            startup_ilpk=su["il"].max(), startup_Lmin=L_of(su["il"].max(), c) * 1e6,
            il_pp=np.ptp(win(ss, ss["t"][-1] - 10e-6, ss["t"][-1])["il"]) * 1e3,
            il_pk=ss["il"].max() * 1e3, vout_pp=np.ptp(win(ss, ss["t"][-1] - 10e-6, ss["t"][-1])["vout"]) * 1e3,
            vout_mean=mean_t(ss, ss["vout"]),
            fsw=fsw(ss) / 1e6,
            step_vmin=st["vout"].min(), step_vmax=sd["vout"].max(),
            short_ilpk=sc["il"].max(), short_Lmin=L_of(sc["il"].max(), c) * 1e6,
            p_dcr=p_dcr * 1e3, vin_startup_min=su["vin"].min())
    return R, stats


def fsw(w):
    s = (w["vsw"] > 2.0).astype(int)
    rises = np.flatnonzero(np.diff(s) == 1)
    return (len(rises) - 1) / (w["t"][rises[-1]] - w["t"][rises[0]]) if len(rises) > 2 else float("nan")


def plots(R):
    main = ("alt", "neu")
    # 1) whole sequence
    fig, ax = plt.subplots(3, 1, figsize=(10, 9), sharex=True)
    for k in main:
        r, c = R[k], CASES[k]
        n = max(len(r["t"]) // 40000, 1)
        ax[0].plot(r["t"][::n] * 1e3, r["vout"][::n], color=c["color"], lw=.7, label=c["label"])
        ax[1].plot(r["t"][::n] * 1e3, r["il"][::n], color=c["color"], lw=.4, label=c["label"])
        ax[2].plot(r["t"][::n] * 1e3, r["vin"][::n], color=c["color"], lw=.7, label=c["label"])
    for a, t, s in ((ax[0], T_STEP_UP, "60→460 mA"), (ax[0], T_STEP_DN, "460→60 mA"), (ax[0], T_SHORT, "Kurzschluss")):
        for aa in ax: aa.axvline(t * 1e3, color="#999", ls=":", lw=1)
        a.text(t * 1e3 + 0.01, 0.3, s, fontsize=8)
    ax[0].set_ylabel("+3V3 [V]"); ax[1].set_ylabel("I(L1) [A]"); ax[2].set_ylabel("VIN U8 [V]")
    ax[2].set_xlabel("Zeit [ms]")
    ax[0].set_title("TI-PSpice-Modell TPS62162: Anlauf, Lastsprung, Kurzschluss (V0 = 5 V, Ri = 1 Ω)")
    for a in ax: a.grid(alpha=.3); a.legend(fontsize=8, loc="lower left")
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "ti_ablauf.png"), dpi=110); plt.close(fig)

    # 2) zooms: 460 mA steady, load step, short circuit
    fig, ax = plt.subplots(2, 3, figsize=(14, 7))
    for k in CASES:
        r, c = R[k], CASES[k]
        w = win(r, T_STEP_DN - 4e-6, T_STEP_DN)
        tt = (w["t"] - w["t"][0]) * 1e6
        if k in main:
            ax[0, 0].plot(tt, w["il"] * 1e3, color=c["color"], ls=c["ls"], label=c["label"])
            ax[1, 0].plot(tt, (w["vout"] - w["vout"].mean()) * 1e3, color=c["color"], ls=c["ls"], label=c["label"])
            w = win(r, T_STEP_UP - 20e-6, T_STEP_UP + 200e-6)
            ax[0, 1].plot((w["t"] - T_STEP_UP) * 1e6, w["il"], color=c["color"], lw=.5, label=c["label"])
            ax[1, 1].plot((w["t"] - T_STEP_UP) * 1e6, w["vout"], color=c["color"], lw=.8, label=c["label"])
        w = win(r, T_END - 6e-6, T_END)
        tt = (w["t"] - w["t"][0]) * 1e6
        ax[0, 2].plot(tt, w["il"], color=c["color"], ls=c["ls"], label=c["label"])
        ax[1, 2].plot(tt, L_of(w["il"], c) * 1e6, color=c["color"], ls=c["ls"], label=c["label"])
    ax[0, 0].set_title("460 mA eingeschwungen"); ax[0, 0].set_ylabel("I(L1) [mA]")
    ax[1, 0].set_ylabel("+3V3 − Mittelwert [mV]"); ax[1, 0].set_xlabel("Zeit [µs]")
    ax[0, 1].set_title("Lastsprung 60 → 460 mA"); ax[0, 1].set_ylabel("I(L1) [A]")
    ax[1, 1].set_ylabel("+3V3 [V]"); ax[1, 1].set_xlabel("Zeit ab Flanke [µs]")
    ax[0, 2].set_title("Kurzschluss 0,1 Ω (eingeschwungen)"); ax[0, 2].set_ylabel("I(L1) [A]")
    ax[1, 2].set_ylabel("L(I) [µH]"); ax[1, 2].set_xlabel("Zeit [µs]")
    for a in ax.flat: a.grid(alpha=.3); a.legend(fontsize=7)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "ti_details.png"), dpi=110); plt.close(fig)


if __name__ == "__main__":
    if "--plot" not in sys.argv:
        run_all()
    R, stats = analyse()
    plots(R)
    for k, s in stats.items():
        print(k, {a: round(float(b), 4) for a, b in s.items()})
