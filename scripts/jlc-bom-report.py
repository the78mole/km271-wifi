#!/usr/bin/env python3
"""BOM report for JLCPCB assembly.

Builds a grouped BOM from the KiCad schematic (via kicad-cli) and adds, per line:

  * JLC part type: Basic, Extended or Promotional Extended (JLC API)
  * stock, unit price and line price for N boards (default 10), including
    JLC attrition (lossNumber) and minimum order quantity (leastPatchNumber)
  * whether the footprint can be found in the configured footprint libraries
  * whether every 3D model referenced by the footprints on the board exists

Outputs <project>_BOM_report.csv and <project>_BOM_report.md next to the
schematic, plus a short summary on stdout.

Usage:
  scripts/jlc-bom-report.py [project-dir] [-n BOARDS] [--extended-fee USD]
                            [--offline] [--var NAME=PATH ...]

Library paths are resolved like KiCad does: environment variables, the
"environment.vars" section of kicad_common.json, the global and project
fp-lib-table. Missing variables can be passed with --var.
Needs kicad-cli >= 10 and Python >= 3.8, no extra packages.
"""
import argparse
import collections
import csv
import io
import json
import os
import platform
import re
import subprocess
import sys
import tempfile
import time
import urllib.request

JLC_API = ("https://jlcpcb.com/api/overseas-pcb-order/v1/shoppingCart/"
           "smtGood/selectSmtComponentList")
KICAD_VER = "10.0"


# ---------------------------------------------------------------- KiCad paths
def kicad_config_dir():
    if os.environ.get("KICAD_CONFIG_HOME"):
        return os.environ["KICAD_CONFIG_HOME"]
    system = platform.system()
    if system == "Windows":
        return os.path.join(os.environ.get("APPDATA", ""), "kicad", KICAD_VER)
    if system == "Darwin":
        return os.path.expanduser(f"~/Library/Preferences/kicad/{KICAD_VER}")
    base = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(base, "kicad", KICAD_VER)


def default_share_dir():
    system = platform.system()
    if system == "Windows":
        return r"C:\Program Files\KiCad\10.0\share\kicad"
    if system == "Darwin":
        return "/Applications/KiCad/KiCad.app/Contents/SharedSupport"
    return "/usr/share/kicad"


def build_env(project_dir, extra):
    env = {}
    share = default_share_dir()
    for v in ("KICAD10", "KICAD9", "KICAD8"):
        env[f"{v}_FOOTPRINT_DIR"] = os.path.join(share, "footprints")
        env[f"{v}_3DMODEL_DIR"] = os.path.join(share, "3dmodels")
        env[f"{v}_SYMBOL_DIR"] = os.path.join(share, "symbols")
    common = os.path.join(kicad_config_dir(), "kicad_common.json")
    try:
        with open(common, encoding="utf-8") as fh:
            env.update((json.load(fh).get("environment", {}) or {}).get("vars") or {})
    except (OSError, ValueError):
        pass
    env.update({k: v for k, v in os.environ.items() if k.startswith(("KICAD", "THE78MOLE"))})
    env["KIPRJMOD"] = os.path.abspath(project_dir)
    env.update(extra)
    return env


def expand(path, env):
    def sub(m):
        return env.get(m.group(1), m.group(0))
    for _ in range(5):  # variables may reference other variables
        new = re.sub(r"\$\{([^}]+)\}", sub, path)
        if new == path:
            break
        path = new
    return os.path.expanduser(path)


def read_lib_table(path, env):
    libs = {}
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return libs
    for m in re.finditer(r'\(lib\s+\(name\s+"?([^")]+)"?\).*?\(uri\s+"?([^")]+)"?\)', text):
        libs.setdefault(m.group(1), expand(m.group(2), env))
    return libs


def footprint_libs(project_dir, env):
    libs = read_lib_table(os.path.join(project_dir, "fp-lib-table"), env)
    for k, v in read_lib_table(os.path.join(kicad_config_dir(), "fp-lib-table"), env).items():
        libs.setdefault(k, v)
    return libs


def footprint_status(lib_id, libs, env):
    if not lib_id:
        return "no footprint"
    if ":" not in lib_id:
        return "no library nickname"
    nick, name = lib_id.split(":", 1)
    base = libs.get(nick)
    if base is None:
        # KiCad's stock libraries are found even without a global table entry
        guess = os.path.join(env.get("KICAD10_FOOTPRINT_DIR", ""), nick + ".pretty")
        if os.path.isdir(guess):
            base = guess
        else:
            return f"library '{nick}' not configured"
    if os.path.isfile(os.path.join(base, name + ".kicad_mod")):
        return "ok"
    return f"missing in {nick}"


# ---------------------------------------------------------------- board data
def board_models(pcb_path):
    """Return ({reference: [model paths]}, {reference: mount}) from the .kicad_pcb file."""
    text = open(pcb_path, encoding="utf-8").read()
    result, mount = {}, {}
    starts = [m.start() for m in re.finditer(r"\n\t\(footprint ", text)] + [len(text)]
    for a, b in zip(starts, starts[1:]):
        block = text[a:b]
        ref = re.search(r'\(property "Reference" "([^"]*)"', block)
        if not ref:
            continue
        result[ref.group(1)] = re.findall(r'\(model "([^"]*)"', block)
        attr = re.search(r"\n\t\t\(attr ([^)]*)\)", block)
        attr = attr.group(1) if attr else ""
        mount[ref.group(1)] = "SMD" if "smd" in attr else ("THT" if "through_hole" in attr else "other")
    return result, mount


def model_status(refs, models, env):
    paths, missing = set(), []
    for r in refs:
        if r not in models:
            return "not on board"
        paths.update(models[r])
    if not paths:
        return "no model"
    for p in sorted(paths):
        if p.startswith("kicad-embed://"):
            continue
        if not os.path.isfile(expand(p, env)):
            missing.append(p)
    if missing:
        return "missing: " + ", ".join(sorted(set(missing)))
    return "ok"


# ---------------------------------------------------------------- schematic
def schematic_parts(sch_path):
    fields = "Reference,Value,Footprint,JLC,${DNP}"
    with tempfile.TemporaryDirectory() as tmp:
        out = os.path.join(tmp, "bom.csv")
        subprocess.run(["kicad-cli", "sch", "export", "bom", sch_path,
                        "--fields", fields, "--labels", "Ref,Value,Footprint,JLC,DNP",
                        "--group-by", "", "--ref-range-delimiter", "",
                        "-o", out], check=True, capture_output=True)
        with open(out, encoding="utf-8") as fh:
            return list(csv.DictReader(fh))


def ref_key(ref):
    m = re.match(r"([A-Za-z_#]+)(\d*)", ref)
    return (m.group(1), int(m.group(2) or 0)) if m else (ref, 0)


def compress_refs(refs):
    refs = sorted(refs, key=ref_key)
    out, run = [], []
    for r in refs + [None]:
        if run and r is not None:
            p, n = ref_key(r)
            lp, ln = ref_key(run[-1])
            if p == lp and n == ln + 1:
                run.append(r)
                continue
        if run:
            out.append(run[0] if len(run) < 3 else f"{run[0]}-{run[-1]}")
            if len(run) == 2:
                out.append(run[1])
        run = [r] if r else []
    return ",".join(out)


# ---------------------------------------------------------------- JLC API
def jlc_lookup(code, cache):
    if code in cache:
        return cache[code]
    body = json.dumps({"keyword": code, "currentPage": 1, "pageSize": 10}).encode()
    req = urllib.request.Request(JLC_API, data=body, headers={
        "Content-Type": "application/json", "User-Agent": "km271-bom-report"})
    item = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.load(resp)
            hits = (data.get("data") or {}).get("componentPageInfo", {}).get("list") or []
            item = next((h for h in hits if h.get("componentCode") == code), None)
            break
        except Exception as exc:  # network hiccups: retry, then give up
            if attempt == 2:
                print(f"  ! {code}: {exc}", file=sys.stderr)
            time.sleep(2 ** attempt)
    cache[code] = item
    return item


def part_type(item):
    if not item:
        return "not found"
    if item.get("componentLibraryType") == "base":
        return "Basic"
    if item.get("preferredComponentFlag"):
        return "Promotional Extended"
    return "Extended"


def unit_price(item, qty):
    tiers = sorted(item.get("componentPrices") or [], key=lambda t: t["startNumber"])
    price = None
    for t in tiers:
        if qty >= t["startNumber"]:
            price = t["productPrice"]
    if price is None and tiers:
        price = tiers[0]["productPrice"]
    return price


# ---------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("project_dir", nargs="?", default="KM217-WiFi")
    ap.add_argument("-n", "--boards", type=int, default=10, help="number of boards (default 10)")
    ap.add_argument("--extended-fee", type=float, default=3.0,
                    help="JLC loading fee per unique Extended part in USD (default 3.0)")
    ap.add_argument("--include-tht", action="store_true",
                    help="price THT/other parts too (default: only SMD parts are machine-placed)")
    ap.add_argument("--offline", action="store_true", help="skip the JLC API")
    ap.add_argument("--var", action="append", default=[], metavar="NAME=PATH",
                    help="set a KiCad path variable, e.g. THE78MOLE_LIBS=~/GIT/Libraries/KiCad/userlibs")
    args = ap.parse_args()

    proj = args.project_dir.rstrip("/\\")
    name = os.path.basename(os.path.abspath(proj))
    sch = os.path.join(proj, name + ".kicad_sch")
    pcb = os.path.join(proj, name + ".kicad_pcb")
    for f in (sch, pcb):
        if not os.path.isfile(f):
            sys.exit(f"not found: {f}")

    extra = dict(v.split("=", 1) for v in args.var)
    env = build_env(proj, extra)
    libs = footprint_libs(proj, env)
    models, mount = board_models(pcb)

    groups = collections.OrderedDict()
    for p in schematic_parts(sch):
        dnp = bool(p.get("DNP", "").strip())
        key = (p["Value"], p["Footprint"], p["JLC"].strip(), dnp)
        groups.setdefault(key, []).append(p["Ref"])

    def placed(refs, dnp):
        kinds = {mount.get(r, "other") for r in refs}
        return not dnp and (args.include_tht or kinds == {"SMD"})

    # the same LCSC part in several lines (e.g. SW3/SW4) is ordered as one reel
    need_per_code = collections.Counter()
    for (value, fp, code, dnp), refs in groups.items():
        if code and placed(refs, dnp):
            need_per_code[code] += len(refs) * args.boards

    cache = {}
    rows, total, fees, issues = [], 0.0, 0.0, []
    seen_ext = set()
    for (value, fp, code, dnp), refs in sorted(groups.items(), key=lambda g: ref_key(sorted(g[1], key=ref_key)[0])):
        qty = len(refs)
        item = jlc_lookup(code, cache) if code and not args.offline else None
        ptype = part_type(item) if code and not args.offline else ("" if not code else "offline")
        need = qty * args.boards
        order = unit = line = None
        stock = item.get("stockCount") if item else None
        mnt = "/".join(sorted({mount.get(r, "-") for r in refs}))
        if item and placed(refs, dnp):
            pooled = need_per_code[code]
            pooled_order = max(pooled + int(item.get("lossNumber") or 0), int(item.get("leastPatchNumber") or 0))
            order = round(pooled_order * need / pooled)  # this line's share
            unit = unit_price(item, pooled_order)
            line = round(unit * order, 4) if unit is not None else None
            total += line or 0
            if ptype == "Extended" and code not in seen_ext:
                seen_ext.add(code)
                fees += args.extended_fee
        fps = footprint_status(fp, libs, env)
        mds = model_status(refs, models, env) if fp else "-"
        row = {
            "Designator": compress_refs(refs), "Qty/board": qty, "Value": value,
            "Footprint": fp, "Mount": mnt, "LCSC": code, "DNP": "DNP" if dnp else "",
            "JLC type": ptype,
            "Manufacturer part": (item or {}).get("componentModelEn", ""),
            "Stock": "" if stock is None else stock,
            f"Qty ({args.boards} boards, incl. attrition)": order or "",
            "Unit price USD": "" if unit is None else f"{unit:.4f}",
            f"Line price USD ({args.boards} boards)": "" if line is None else f"{line:.2f}",
            "Footprint lib": fps, "3D model": mds,
        }
        rows.append(row)
        if placed(refs, dnp):
            if not code:
                issues.append(f"{row['Designator']}: no LCSC number")
            elif item is None and not args.offline:
                issues.append(f"{row['Designator']}: {code} not found at JLC")
            elif stock is not None and order and stock < order:
                issues.append(f"{row['Designator']}: {code} stock {stock} < {order}")
        if fps != "ok" and not (dnp and not fp):
            issues.append(f"{row['Designator']}: footprint {fps}")
        if mds not in ("ok", "-"):
            issues.append(f"{row['Designator']}: 3D {mds}")

    cols = list(rows[0].keys()) if rows else []
    out_csv = os.path.join(proj, f"{name}_BOM_report.csv")
    with open(out_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        w.writerows(rows)

    counts = collections.Counter(r["JLC type"] for r in rows if r["Unit price USD"])
    summary = [
        f"Boards: {args.boards}",
        f"Parts cost: {total:.2f} USD (per board {total / args.boards:.2f} USD)",
        f"Extended loading fees: {len(seen_ext)} x {args.extended_fee:.2f} = {fees:.2f} USD",
        f"Total parts incl. fees: {total + fees:.2f} USD (per board {(total + fees) / args.boards:.2f} USD)",
        "Line types: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items())),
        "Prices from the JLC API at " + time.strftime("%Y-%m-%d %H:%M") +
        "; PCB, assembly and setup fees not included.",
    ]

    out_md = os.path.join(proj, f"{name}_BOM_report.md")
    md_cols = ["Designator", "Qty/board", "Value", "Mount", "LCSC", "JLC type", "Stock",
               "Unit price USD", f"Line price USD ({args.boards} boards)", "Footprint lib", "3D model", "DNP"]
    with open(out_md, "w", encoding="utf-8") as fh:
        fh.write(f"# {name} BOM report\n\n")
        fh.write("\n".join(f"- {s}" for s in summary) + "\n\n")
        fh.write("| " + " | ".join(md_cols) + " |\n|" + "---|" * len(md_cols) + "\n")
        for r in rows:
            fh.write("| " + " | ".join(str(r[c]).replace("|", "/") for c in md_cols) + " |\n")
        if issues:
            fh.write("\n## Open points\n\n" + "\n".join(f"- {i}" for i in issues) + "\n")

    print("\n".join(summary))
    if issues:
        print("\nOpen points:")
        print("\n".join(f"  - {i}" for i in issues))
    print(f"\nWritten: {out_csv}, {out_md}")


if __name__ == "__main__":
    main()
