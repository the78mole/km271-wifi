# JLC Part Sourcing — KM217-WiFi

Check ONE box per section for the part to use, then tell Claude "apply selections".
Stock/price verified live against LCSC product pages on 2026-07-20 — re-check anything
marked **Out of Stock** before ordering, availability changes daily.

Konnect's own JLCPCB database tools are currently broken (hardcoded source URL
`bouni.github.io/kicad-jlcpcb-tools/jlcpcb_parts.db` returns 404) — every candidate below
was found via web search and individually verified against the live LCSC product page
(JSON-LD product data: name, description, price, stock).

Where possible each group now lists a **second source** (different manufacturer) in case
the primary is out of stock or goes end-of-life.

---

## C1, C3, C4, C9-C11, C15-C17, C19-C23, C25-C27 — 100n (Capacitor_SMD:C_0603...)

- [x] [C14663](https://www.lcsc.com/product-detail/_C14663.html) — YAGEO CC0603KRX7R9BB104, 100nF ±10% 50V X7R 0603 — **In Stock** (215,660), $0.0181/ea
- [ ] [C1591](https://www.lcsc.com/product-detail/_C1591.html) — Samsung CL10B104KB8NNNC, 100nF ±10% 50V X7R 0603 — **In Stock** (3,599,300), $0.0130/ea *(second source)*

## C12 — 33n (Capacitor_SMD:C_0603...)

- [x] [C21117](https://www.lcsc.com/product-detail/_C21117.html) — Samsung CL10B333KB8NNNC, 33nF ±10% 50V X7R 0603 — **In Stock** (102,650), $0.0098/ea

_No second source found for 33nF 0603 X7R via search — this is the only candidate._

## C13 — 22u/10V (Capacitor_SMD:C_1812_4532Metric... electrolytic)

- [ ] [C140394](https://www.lcsc.com/product-detail/_C140394.html) — CEC(Zhenhua XinYun) CA45-A-10V-22uF-M, 22µF 10V tantalum — **In Stock**, $0.0503/ea ⚠️ **unverified case size** — listed as tantalum "Case A" (~3.2×1.6mm), which does not obviously match your 1812/4532-metric footprint (4.5×3.2mm). Double-check the physical dimensions before ordering — this may not actually fit.

_No exact 1812-case 22µF/10V match found despite extensive search. Treat the candidate above as a lead to verify manually, not a confirmed fit._

## C18 — 4p7 (Capacitor_SMD:C_0603...)

- [ ] [C1669](https://www.lcsc.com/product-detail/_C1669.html) — FH (Guangdong Fenghua) 0603CG4R7C500NT, 4.7pF ±0.25pF 50V C0G 0603 — **In Stock** (196,600), $0.0055/ea

_No second source found for 4.7pF 0603 C0G via search — this is the only candidate._

## D10 — SMAJ5.0A (Diode_SMD:D_SMA)

- [x] [C87074](https://www.lcsc.com/product-detail/_C87074.html) — Diodes Inc SMAJ5.0A-13-F, 400W TVS, 9.2V clamp — **In Stock** (15,805), $0.0656/ea
- [ ] [C98802](https://www.lcsc.com/product-detail/_C98802.html) — ST SMAJ5.0A-TR, 400W TVS, 13.4V clamp — **In Stock** (22,225), $0.0814/ea
- [ ] [C140902](https://www.lcsc.com/product-detail/_C140902.html) — LRC SMAJ5.0A — Out of Stock, $0.0351/ea
- [ ] [C908198](https://www.lcsc.com/product-detail/_C908198.html) — FUXINSEMI SMAJ5.0A — Out of Stock, $0.0167/ea

## J1 — KM271-CON (the78mole:LM2107_ComModuleCon)

_No candidate — confirmed via search this is a project-specific footprint (matches the
original Buderus Logamatic 2107 communication-module connector), not a generic catalog
part. No generic LCSC equivalent exists to search for. Please source manually — check the
Hardware Description doc or original Buderus service documentation for the exact mating
connector part number._

## Q1, Q2 — SS8050 (Package_TO_SOT_SMD:SOT-23)

- [ ] [C2150](https://www.lcsc.com/product-detail/_C2150.html) — JSCJ SS8050, NPN 25V 1.5A SOT-23 — Out of Stock, $0.0121/ea

**S8050 substitute confirmed viable** — same BEC pinout/SOT-23 package as SS8050, just a
lower current/power rating (0.5A/0.3W vs 1.5A/2W). Fine for general logic-level switching;
only a concern if this transistor is driving a real load near 1A. In-stock S8050 options:

- [ ] [C181158](https://www.lcsc.com/product-detail/_C181158.html) — Guangdong Hottech S8050 — **In Stock** (2,812,950), $0.0076/ea
- [ ] [C111272](https://www.lcsc.com/product-detail/_C111272.html) — Shikues S8050 — **In Stock** (99,950), $0.0074/ea
- [ ] [C2828466](https://www.lcsc.com/product-detail/_C2828466.html) — CBI S8050 — **In Stock** (29,860), $0.0063/ea
- [ ] [C2146](https://www.lcsc.com/product-detail/_C2146.html) — JSCJ S8050 J3Y — **In Stock** (156,250), $0.0109/ea
- [ ] [C266592](https://www.lcsc.com/product-detail/_C266592.html) — BORN S8050 — **In Stock** (22,300), $0.0087/ea

## R1, R3, R76, R77, R84, R86 — 220 (Resistor_SMD:R_0603...)

- [ ] [C22962](https://www.lcsc.com/product-detail/_C22962.html) — UNI-ROYAL 0603WAF2200T5E, 220Ω ±1% 0603 — **In Stock** (173,100), $0.0055/ea
- [ ] [C140105](https://www.lcsc.com/product-detail/_C140105.html) — FH RS-03K221JT, 220Ω ±5% 0603 — **In Stock** (49,800), $0.0013/ea *(second source, note: ±5% not ±1%)*

## R2, R27, R29, R32, R82, R85 — 10K (Resistor_SMD:R_0603...)

- [ ] [C25804](https://www.lcsc.com/product-detail/_C25804.html) — UNI-ROYAL 0603WAF1002T5E, 10kΩ ±1% 0603 — Out of Stock, $0.0060/ea
- [ ] [C5628780](https://www.lcsc.com/product-detail/_C5628780.html) — Venkel CR0603-10W-1002FT, 10kΩ ±1% 0603 — Out of Stock, $0.0015/ea
- [ ] [C115301](https://www.lcsc.com/product-detail/_C115301.html) — FH RS-03K103FT, 10kΩ ±1% 0603 — Out of Stock

⚠️ **All three candidates found are currently out of stock.** 10kΩ 0603 1% is about as
common as it gets, so this is likely a temporary/regional stock gap — re-check closer to
order time rather than treating this as a rare part.

## R4, R30, R61-R63 — 4K7 (Resistor_SMD:R_0603...)

- [ ] [C23162](https://www.lcsc.com/product-detail/_C23162.html) — UNI-ROYAL 0603WAF4701T5E, 4.7kΩ ±1% 0603 — Out of Stock, $0.0016/ea
- [ ] [C163914](https://www.lcsc.com/product-detail/_C163914.html) — Walsin WR06X4701FTL, 4.7kΩ ±1% 0603 — **In Stock** (483,800), $0.0013/ea *(second source)*

## R5, R11 — 100K (Resistor_SMD:R_0603...)

- [ ] [C2889376](https://www.lcsc.com/product-detail/_C2889376.html) — VO 0603 ±1% 100K — Out of Stock
- [ ] [C116674](https://www.lcsc.com/product-detail/_C116674.html) — YAGEO AC0603FR-07100KL, 100kΩ ±1% 0603 — **In Stock** (108,200), $0.0052/ea *(second source)*

## R6 — 10 (Resistor_SMD:R_0603...)

- [ ] [C109318](https://www.lcsc.com/product-detail/_C109318.html) — YAGEO RC0603FR-0710RL, 10Ω ±1% 0603 — **In Stock** (985,300), $0.0083/ea
- [ ] [C313648](https://www.lcsc.com/product-detail/_C313648.html) — Vishay CRCW060310R0FKEAHP, 10Ω ±1% 0603 — **In Stock** (75,200), $0.0293/ea *(second source, pricier)*

## R9 — 330 (Resistor_SMD:R_0603...)

- [ ] [C23138](https://www.lcsc.com/product-detail/_C23138.html) — UNI-ROYAL 0603WAF3300T5E, 330Ω ±1% 0603 — Out of Stock, $0.0058/ea
- [ ] [C880919](https://www.lcsc.com/product-detail/_C880919.html) — ROHM MCR03EZPFX3300, 330Ω ±1% 0603 — Out of Stock
- [ ] [C844926](https://www.lcsc.com/product-detail/_C844926.html) — Vishay CRCW0603330RFKEA, 330Ω ±1% 0603 — Out of Stock, $0.0038/ea

⚠️ **All three candidates out of stock.** Re-check before ordering.

## R12 — 47K (Resistor_SMD:R_0603...)

- [ ] [C25819](https://www.lcsc.com/product-detail/_C25819.html) — UNI-ROYAL 0603WAF4702T5E, 47kΩ ±1% 0603 — Out of Stock, $0.0083/ea
- [ ] [C844929](https://www.lcsc.com/product-detail/_C844929.html) — Vishay CRCW060347K0FKEA, 47kΩ ±1% 0603 — **In Stock** (2,100, low), $0.0023/ea *(second source)*

## R16, R49-R51, R74, R75 — 1K (Resistor_SMD:R_0603...)

- [ ] [C21190](https://www.lcsc.com/product-detail/_C21190.html) — UNI-ROYAL 0603WAF1001T5E, 1kΩ ±1% 0603 — Out of Stock, $0.0077/ea
- [ ] [C22548](https://www.lcsc.com/product-detail/_C22548.html) — YAGEO RC0603FR-071KL, 1kΩ ±1% 0603 — **In Stock** (966,000), $0.0050/ea *(second source)*
- [ ] [C176132](https://www.lcsc.com/product-detail/_C176132.html) — Ever Ohms QR0603F1K00P05Z, 1kΩ ±1% 0603 — **In Stock** (9,600), $0.0027/ea *(third source)*

## R17 — 3K3 (Resistor_SMD:R_0603...)

- [ ] [C22978](https://www.lcsc.com/product-detail/_C22978.html) — UNI-ROYAL 0603WAF3301T5E, 3.3kΩ ±1% 0603 — Out of Stock, $0.0018/ea

_No second source found for 3.3kΩ 0603 1% via search — only candidate, and it's currently
out of stock._

## R23-R26 — 680 (Resistor_SMD:R_0603...)

- [ ] [C23228](https://www.lcsc.com/product-detail/_C23228.html) — UNI-ROYAL 0603WAF6800T5E, 680Ω ±1% 0603 — Out of Stock, $0.0028/ea
- [ ] [C4228334](https://www.lcsc.com/product-detail/_C4228334.html) — Venkel CR0603-10W-6800FT, 680Ω ±1% 0603 — Out of Stock, $0.0009/ea

⚠️ **Both candidates out of stock.** Re-check before ordering.

## R28 — 1M (Resistor_SMD:R_0603...)

- [ ] [C105578](https://www.lcsc.com/product-detail/_C105578.html) — YAGEO RC0603FR-071ML, 1MΩ ±1% 0603 — Out of Stock, $0.0016/ea
- [ ] [C116678](https://www.lcsc.com/product-detail/_C116678.html) — YAGEO AC0603FR-071ML (automotive grade), 1MΩ ±1% 0603 — Out of Stock, $0.0021/ea

⚠️ **Both candidates out of stock.** Re-check before ordering.

## R69, R70 — 2R2 (Resistor_SMD:R_0603...)

_No candidate found — every search resolved to 2.2kΩ instead of 2.2Ω, and the only 2.2Ω
part surfaced was a 5W through-hole wirewound resistor, not a 0603 chip resistor. 2.2Ω in
0603 thick-film form seems to be a genuinely uncommon combination at LCSC. Please source
manually or check if a different footprint/technology (e.g. current-sense/shunt resistor
category) is more realistic for this value._

## R71 — 22K1 (Resistor_SMD:R_0603...)

- [ ] [C723484](https://www.lcsc.com/product-detail/_C723484.html) — YAGEO RT0603BRD0722K1L, 22.1kΩ ±0.1% 0603 **thin film** — Out of Stock, $0.0191/ea

_Only candidate found (E96 precision value, thin-film not thick-film), and it's out of
stock. No second source found._

## R72 — 47K5 (Resistor_SMD:R_0603...)

- [ ] [C136962](https://www.lcsc.com/product-detail/_C136962.html) — YAGEO RT0603BRD0747K5L, 47.5kΩ ±0.1% 0603 **thin film** — **In Stock** (20,900), $0.0198/ea

_Note: thin-film ±0.1% rather than thick-film ±1% — tighter tolerance, pricier, but a valid
fit. No second source found for this E96 value._

## R73 — 2K2 (Resistor_SMD:R_0603...)

- [ ] [C4190](https://www.lcsc.com/product-detail/_C4190.html) — UNI-ROYAL 0603WAF2201T5E, 2.2kΩ ±1% 0603 — **In Stock, only 100 units** ⚠️, $0.0054/ea
- [ ] [C114662](https://www.lcsc.com/product-detail/_C114662.html) — YAGEO RC0603FR-072K2L, 2.2kΩ ±1% 0603 — Out of Stock, $0.0034/ea *(second source, currently OOS too)*

⚠️ Both the primary (100 units left) and the second source (OOS) are stock-constrained —
worth re-checking close to order time.

## U4, U5 — SN74LV1T34DBV (Package_TO_SOT_SMD:SOT-23-5)

- [ ] [C100024](https://www.lcsc.com/product-detail/_C100024.html) — TI SN74LV1T34DBVR, SOT-23-5 single buffer — **In Stock** (50,955), $0.1212/ea

_No second source found — TI appears to be the sole manufacturer of this exact part in this
exact package on LCSC (a DCK/SC70-5 variant exists but requires a different footprint, so
it's not a drop-in second source)._

## U10 — CP2102N-Axx-xQFN28 (Package_DFN_QFN:QFN-28-1EP_5x5mm...)

- [ ] [C964632](https://www.lcsc.com/product-detail/_C964632.html) — Silicon Labs CP2102N-A02-GQFN28R (tape&reel), QFN-28 5x5 — **In Stock** (1,070), $1.1069/ea
- [ ] [C1550553](https://www.lcsc.com/product-detail/_C1550553.html) — Silicon Labs CP2102N-A02-GQFN28 (cut tape), QFN-28 5x5 — Out of Stock, $1.3884/ea

_Same manufacturer/die, just packaging variants (reel vs. cut tape) — no independent second
source found for this specific USB-UART part._

---

## Not sourced (skipped intentionally)

- **H1** (MountingHole) — mechanical, not an orderable electronic part.
- **J8** (ATS_mate, DNP, no footprint) — not a placed part.
- **C2, C5, C14** (2u2, 0603) — already has `JLC=C2167142`. Note: C14 was missing this value
  even though it's the identical value+footprint as C2/C5 — looks like an oversight, will be
  filled in with the same part unless you say otherwise.
- All **DNP** ("Nicht bestücken") groups — D5, J4, J5, J6 (already has JLC), R7/R8/R33-40/etc
  (0Ω, DNP), R10/R13-15/etc ("np", DNP), R20-22/etc (22Ω, DNP), SW1, SW2.

## Summary of remaining gaps after this round

- **No candidate at all**: J1 (project-specific connector), R69/R70 (2.2Ω 0603 — genuinely
  hard to find in thick-film chip form)
- **Candidate found but ALL sources out of stock**: R2 group (10K), R9 (330), R23-26 (680),
  R28 (1M), R71 (22K1) — five groups where you'll likely need to re-check stock closer to
  order time or accept a longer lead time / extended-part fee alternative.
- **Only one source found (in stock)**: C12 (33nF), C18 (4.7pF), R17 (3.3K, and that one's
  OOS too), R72 (47K5), U4/U5 (SN74LV1T34DBV), U10 (CP2102N, only packaging variants)
