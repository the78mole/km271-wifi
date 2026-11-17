#!/usr/bin/env python3
"""
KM271-WiFi supply analysis: Buderus slot (V0 + Ri) -> old LDO (AZ1117) vs. new buck (TPS62162).

Behavioural ngspice models (no vendor models).  Run:  python3 sim.py
Needs ngspice, numpy, matplotlib.  Writes PNGs next to this script.
"""
import os, subprocess, tempfile
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- parameters
V0     = 5.0      # Buderus 5 V rail, no-load (issue dewenni#57: 5.0..5.1 V measured)
RI     = 1.0      # assumed source impedance of the Buderus 5 V incl. slot contact
I_BASE = 0.060    # ESP32 idle / WiFi RX, at 3V3
I_STEP = 0.300    # load step (WiFi TX burst), at 3V3
I_STEP_S3 = 0.400 # ESP32-S3 worst case: 355 mA TX peak + CPU/peripherals, at 3V3
T_ON, T_OFF, T_END = 1e-3, 6e-3, 9e-3
TR = 1e-6         # edge time of the load step
BOD = 2.43        # ESP32 / ESP32-S3 brown-out level 0 / 7 (~2.43 / 2.44 V)
VMIN_SPEC = 3.0   # ESP32-(S3)-WROOM minimum supply voltage

def load_src(i_base=I_BASE, i_step=I_STEP):
    return (f"Vld o3 ild 0\nIload ild 0 PWL(0 {i_base} {T_ON} {i_base} {T_ON+TR} {i_base+i_step} "
            f"{T_OFF} {i_base+i_step} {T_OFF+TR} {i_base} {T_END} {i_base})")

# ------------------------------------------------------------ source (slot)
def source(v0, ri):
    return f"""
V0 v0 0 {v0}
Ri v0 slot {ri}
"""

# ---------------------------------------------- OLD: J3 jumper + AZ1117 LDO
# +5V : C7 100u/16V Al-elko (ESR ~0.7R assumed), C2 2u2, C3/C10/C20/C24 100n
# 3V3 : C8 100u/16V Al-elko, C13 22u/10V (1812), C14 2u2, C5 2u2 (LDO out), 5x100n
def old_circuit(v0=V0, ri=RI, i_step=I_STEP):
    return f"""* OLD LDO
{source(v0, ri)}
Rjmp slot in5 10m
C7  in5 c7n 100u
R7  c7n 0 0.7
C2  in5 0 1.6u
Cin in5 0 0.4u
* AZ1117: quiescent ~5 mA from input
Iq  in5 0 5m
* error amp: gain 2000, pole 50 Hz, anti-windup clamp 0..2 V
Bea 0 ea I = 1m*(3.3 - V(o3)) - 1*max(V(ea)-2,0) + 1*max(-V(ea),0)
Rea ea 0 2Meg
Cea ea 0 1.6n
* pass element: transconductance 1 A/V, limited by dropout Vdo = 1.0 V + 0.25 R * I
Bpass in5 o3 I = min(max(V(ea),0)*1, max(V(in5)-V(o3)-1.0,0)/0.25)
C8  o3 c8n 100u
R8  c8n 0 0.7
C13 o3 c13n 18u
R13 c13n 0 0.05
Cout o3 0 4.5u
{load_src(I_BASE, i_step)}
.ic V(o3)=3.3 V(in5)={v0-ri*0.07:.3f} V(ea)=0.07
.tran 0.5u {T_END} 0 0.5u uic
.control
run
wrdata {{OUT}} V(slot) V(in5) V(o3) I(V0) I(Vld)
.endc
.end
"""

# ------------------------------------- NEW: D9 1N5819WS + TPS62162 buck (3V3)
# +5V : C7 220u/16V polymer (ESR ~25m), C28 10u/25V 0805 (~6.5u @5V), C2 2u2, 4x100n
# 3V3 : C8 220u polymer, C29 22u + C13 22u 0805 (~11u each @3.3V), C5 4u7, C14 2u2, 6x100n
# Average current-mode model: inner current loop ~200 kHz, outer PI ~30 kHz,
# 100 % duty mode when V(sw) hits V(in5).  L1 2u2 / 29 mOhm, RDS(on),HS ~0.42 R @ 4.5 V.
def new_circuit(v0=V0, ri=RI, i_step=I_STEP):
    return f"""* NEW BUCK
{source(v0, ri)}
D9  slot in5 DSCH
.model DSCH D(IS=2e-4 N=1.74 RS=0.2 CJO=50p)
C7  in5 c7n 220u
R7  c7n 0 25m
C28 in5 0 6.5u
Cin in5 0 2.0u
Iq  in5 0 1m
* outer voltage loop (PI) -> current command, current limit 1.5 A
Bvi 0 vi I = 8.9e5*(3.3 - V(o3)) - 1e3*max(V(vi)-1.5,0) - 1e3*min(V(vi),0)
Cvi vi 0 1
Bicmd icmd 0 V = min(max(47*(3.3-V(o3)) + V(vi), 0), 1.5)
* inner current loop: averaged switch-node voltage, clamped to 0..Vin (100 % mode)
Bsw sw 0 V = min(max(V(o3) + 0.35*I(Vsen) + 3*(V(icmd)-I(Vsen)), 0), V(in5))
Vsen sw swa 0
Rc  swa lx 0.35
L1  lx o3 2.2u
* input current by power balance of the ideal switch (+ 25 mW switching loss)
Bin in5 0 I = V(sw)*I(Vsen)/max(V(in5),0.5) + 0.025/max(V(in5),0.5)
C8  o3 c8n 220u
R8  c8n 0 25m
Cout o3 0 31u
{load_src(I_BASE, i_step)}
.ic V(o3)=3.3 V(in5)={v0-ri*0.06-0.27:.3f} V(vi)=0.065 V(icmd)=0.065
.tran 0.5u {T_END} 0 0.5u uic
.control
run
wrdata {{OUT}} V(slot) V(in5) V(o3) I(V0) I(Vld) I(Vsen)
.endc
.end
"""

def run(net):
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, "out.txt")
        cir = os.path.join(d, "c.cir")
        open(cir, "w").write(net.replace("{OUT}", out))
        r = subprocess.run(["ngspice", "-b", cir], capture_output=True, text=True)
        if not os.path.exists(out):
            raise RuntimeError(r.stdout + r.stderr)
        a = np.loadtxt(out)
    t = a[:, 0]
    cols = a[:, 1::2]           # wrdata writes "t v" pairs
    return t, cols

def plot_case(t, c, title, fname, extra=None):
    slot, in5, o3, i0, il = c[:, 0], c[:, 1], c[:, 2], -c[:, 3], c[:, 4]
    tm = t * 1e3
    fig, ax = plt.subplots(3, 1, figsize=(10, 9), sharex=True,
                           gridspec_kw=dict(height_ratios=[3, 2, 2]))
    ax[0].plot(tm, slot, label="Steckplatz J1 (nach Ri)", color="#1f77b4")
    ax[0].plot(tm, in5, label="+5V (Reglereingang)", color="#ff7f0e")
    ax[0].plot(tm, o3, label="+3V3 (ESP32)", color="#2ca02c", lw=2)
    ax[0].axhline(VMIN_SPEC, color="#999", ls="--", lw=1)
    ax[0].text(tm[-1], VMIN_SPEC + 0.03, "ESP32 min. 3,0 V", ha="right", va="bottom", fontsize=8, color="#666")
    ax[0].axhline(BOD, color="#d62728", ls="--", lw=1)
    ax[0].text(tm[-1], BOD + 0.03, "Brown-out ~2,43 V", ha="right", va="bottom", fontsize=8, color="#d62728")
    ax[0].set_ylabel("Spannung [V]"); ax[0].set_ylim(2.2, 5.2); ax[0].grid(alpha=.3)
    ax[0].legend(loc="center right", fontsize=8); ax[0].set_title(title)
    ax[1].plot(tm, i0 * 1e3, label="Strom aus Buderus (Ri)", color="#1f77b4")
    ax[1].plot(tm, il * 1e3, label="Last an +3V3", color="#2ca02c")
    if extra is not None:
        ax[1].plot(tm, extra * 1e3, label="Spulenstrom L1", color="#9467bd", lw=.8)
    ax[1].set_ylabel("Strom [mA]"); ax[1].grid(alpha=.3); ax[1].legend(fontsize=8)
    ax[2].plot(tm, (o3 - 3.3) * 1e3, color="#2ca02c")
    ax[2].set_ylabel("+3V3 − 3,3 V [mV]"); ax[2].set_xlabel("Zeit [ms]"); ax[2].grid(alpha=.3)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return dict(slot_min=slot.min(), in5_min=in5.min(), o3_min=o3.min(),
                o3_max=o3.max(), i0_max=i0.max())

def zoom(results, fname):
    fig, ax = plt.subplots(1, 2, figsize=(11, 4), sharey=True)
    for k, (t, c) in results.items():
        for i, (t0, lab) in enumerate([(T_ON, "Lastsprung +300 mA"), (T_OFF, "Lastabwurf −300 mA")]):
            m = (t > t0 - 50e-6) & (t < t0 + 400e-6)
            ax[i].plot((t[m] - t0) * 1e6, c[m, 2], label=k)
            ax[i].set_title(lab.replace('300 mA', 'Sprung')); ax[i].set_xlabel("Zeit ab Flanke [µs]"); ax[i].grid(alpha=.3)
    ax[0].set_ylabel("+3V3 [V]"); ax[0].legend()
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)

def sweep(fname):
    ris = np.round(np.arange(0.5, 6.01, 0.25), 2)
    cases = (("alt (LDO), +300 mA", old_circuit, I_STEP),
             ("neu (Buck), +300 mA", new_circuit, I_STEP),
             ("neu (Buck), +400 mA", new_circuit, I_STEP_S3))
    res = {k: [] for k, _, _ in cases}
    for ri in ris:
        for k, f, i_step in cases:
            t, c = run(f(V0, ri, i_step))
            res[k].append(c[(t > T_ON), 2].min())
    fig, ax = plt.subplots(figsize=(9, 4.5))
    for k, v in res.items():
        ax.plot(ris, v, marker="o", ms=3, label=k)
    ax.axhline(VMIN_SPEC, color="#999", ls="--", lw=1, label="ESP32 min. 3,0 V")
    ax.axhline(BOD, color="#d62728", ls="--", lw=1, label="Brown-out ~2,43 V")
    ax.axvline(RI, color="#555", ls=":", lw=1)
    ax.set_xlabel("Innenwiderstand Buderus-5V Ri [Ω]"); ax.set_ylabel("min. +3V3 [V]")
    ax.set_title(f"Empfindlichkeit: V0 = {V0} V, Grundlast 60 mA + Sprung")
    ax.grid(alpha=.3); ax.legend(fontsize=8)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, fname), dpi=110); plt.close(fig)
    return ris, res

if __name__ == "__main__":
    t1, c1 = run(old_circuit())
    s1 = plot_case(t1, c1, f"ALT: AZ1117-LDO, V0 = {V0} V, Ri = {RI} Ω, Last 60 → 360 mA",
                   "ldo_1ohm.png")
    t2, c2 = run(new_circuit())
    s2 = plot_case(t2, c2, f"NEU: D9 + TPS62162-Buck, V0 = {V0} V, Ri = {RI} Ω, Last 60 → 360 mA",
                   "buck_1ohm.png", extra=c2[:, 5])
    t3, c3 = run(new_circuit(V0, RI, I_STEP_S3))
    s3 = plot_case(t3, c3, f"NEU: D9 + TPS62162-Buck, V0 = {V0} V, Ri = {RI} Ω, Last 60 → 460 mA (S3)",
                   "buck_1ohm_400mA.png", extra=c3[:, 5])
    zoom({"alt (LDO), +300 mA": (t1, c1), "neu (Buck), +300 mA": (t2, c2),
          "neu (Buck), +400 mA": (t3, c3)}, "zoom_edges.png")
    ris, res = sweep("sweep_ri.png")
    print("OLD", {k: round(float(v), 3) for k, v in s1.items()})
    print("NEW", {k: round(float(v), 3) for k, v in s2.items()})
    print("NEW400", {k: round(float(v), 3) for k, v in s3.items()})
    for k, v in res.items():
        print(k, " ".join(f"{r}:{x:.2f}" for r, x in zip(ris, v)))
