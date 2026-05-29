#!/usr/bin/env python3
"""
Erzeugt die druckfertigen STL-Dateien aus der gleichen Geometrie wie
design/gehaeuse.scad (v7).  Nutzt trimesh + manifold3d.

    pip install numpy scipy trimesh manifold3d
    python3 design/build_stl.py

Ausgabe:  design/unterteil.stl  ·  design/deckel.stl

v7-Konzept:  gleichmäßiger Kasten (Deckel ≈ Unterteil breit, nur kleiner
Überstand-Rand wie ein klassischer Deckel).  Der Reader ruht im Deckel
auf einer umlaufenden Auflage-Leiste (Hals enger als der Reader).
Deckel wird mit dem DACH nach unten gedruckt → nur kleine Überhänge,
KEIN Support nötig.
"""

import os
import numpy as np
import trimesh

# ── Parameter (identisch zu gehaeuse.scad) ───────────────────
WALL, FLOOR, TOP, GAP = 2.5, 2.5, 1.5, 0.2

PI_W, PI_D, PI_PCB = 85, 56, 1.4
PI_HX1, PI_HX2, PI_HY1, PI_HY2 = 3.5, 61.5, 3.5, 52.5
STAND_H, STAND_OD, STAND_ID = 4.0, 6.0, 2.3

RDR_W, RDR_D, RDR_H, RDR_R = 98, 65, 12.8, 5

# Unterteil – Außenmaß bewusst „reader-breit" → gleichmäßige Optik
INNER_W, INNER_D, INNER_H = 98, 62, 20
OUTER_W = INNER_W + 2 * WALL          # 103
OUTER_D = INNER_D + 2 * WALL          # 67
OUTER_H = FLOOR + INNER_H             # 22.5
PI_X = (INNER_W - PI_W) / 2           # 6.5  (Pi zentriert)
PI_Y = (INNER_D - PI_D) / 2           # 3
OX, OY = WALL + PI_X, WALL + PI_Y     # 9, 5.5
PCB_TOP = FLOOR + STAND_H + PI_PCB    # 7.9

# Deckel
SKIRT_H    = 10.0             # Höhe bis Mulden-/Leistenboden
NECK_H     = 1.0             # dünnes Band der Auflage-Leiste
ENGAGE     = SKIRT_H - NECK_H # 9 mm: so tief greift der Rock über die Box
SKIRT_T    = 2.5
RDR_POCKET = RDR_H + 0.5     # 13.3

pocket_w, pocket_d   = RDR_W + 1, RDR_D + 1            # 99, 66
skirt_cav_w, skirt_cav_d = OUTER_W + 2 * GAP, OUTER_D + 2 * GAP  # 103.4, 67.4
neck_w, neck_d       = RDR_W - 5, RDR_D - 5            # 93, 60 (< Reader → Leiste)

LID_W = skirt_cav_w + 2 * SKIRT_T    # 108.4
LID_D = skirt_cav_d + 2 * SKIRT_T    # 72.4
LID_H = SKIRT_H + RDR_POCKET + TOP   # 24.8

SEC = 64  # Facetten (≙ $fn)


# ── Primitive ────────────────────────────────────────────────
def rbox(w, d, h, r=4):
    r_ = min(r, w / 2 - 0.01, d / 2 - 0.01)
    corners = [(r_, r_), (w - r_, r_), (r_, d - r_), (w - r_, d - r_)]
    cyls = []
    for x, y in corners:
        c = trimesh.creation.cylinder(radius=r_, height=h, sections=SEC)
        c.apply_translation([x, y, h / 2])
        cyls.append(c)
    return trimesh.util.concatenate(cyls).convex_hull


def cube(x, y, z, w, d, h):
    b = trimesh.creation.box(extents=[w, d, h])
    b.apply_translation([x + w / 2, y + d / 2, z + h / 2])
    return b


def standoff(cx, cy, z, h):
    outer = trimesh.creation.cylinder(radius=STAND_OD / 2, height=h, sections=SEC)
    inner = trimesh.creation.cylinder(radius=STAND_ID / 2, height=h + 0.2, sections=SEC)
    outer.apply_translation([cx, cy, z + h / 2])
    inner.apply_translation([cx, cy, z + h / 2])
    return outer.difference(inner)


# ── Unterteil ────────────────────────────────────────────────
def bottom():
    body = rbox(OUTER_W, OUTER_D, OUTER_H, 4)

    cuts = [
        cube(WALL, WALL, FLOOR, INNER_W, INNER_D, OUTER_H),          # Innenraum
        cube(OX + 5.6,  -0.1, PCB_TOP - 2, 10, WALL + 0.2, 8),       # Power
        cube(OX + 23.5, -0.1, PCB_TOP - 2, 17, WALL + 0.2, 8),       # HDMI
        cube(OX + 49,   -0.1, PCB_TOP - 2, 9,  WALL + 0.2, 8),       # Klinke
        cube(OUTER_W - WALL - 0.1, OY + 4, PCB_TOP - 2,              # USB/LAN
             WALL + 0.2, PI_D - 8, 14),
        cube(-0.1, OY + 21, FLOOR + 1.5, WALL + 0.2, 14, 5),         # microSD
    ]
    for i in range(4):                                              # Lüftung
        cuts.append(cube(OUTER_W / 2 - 22 + i * 13, OUTER_D - WALL - 0.1,
                         PCB_TOP, 7, WALL + 0.2, 6))

    shell = body.difference(trimesh.boolean.union(cuts))

    sz, sh = FLOOR - 0.5, STAND_H + 0.5
    posts = [
        standoff(OX + PI_HX1, OY + PI_HY1, sz, sh),
        standoff(OX + PI_HX2, OY + PI_HY1, sz, sh),
        standoff(OX + PI_HX1, OY + PI_HY2, sz, sh),
        standoff(OX + PI_HX2, OY + PI_HY2, sz, sh),
    ]
    return trimesh.boolean.union([shell, *posts])


# ── Deckel ───────────────────────────────────────────────────
def lid():
    px, py = (LID_W - pocket_w) / 2, (LID_D - pocket_d) / 2
    sx, sy = (LID_W - skirt_cav_w) / 2, (LID_D - skirt_cav_d) / 2
    nx, ny = (LID_W - neck_w) / 2, (LID_D - neck_d) / 2

    body = rbox(LID_W, LID_D, LID_H, 5)

    pocket = rbox(pocket_w, pocket_d, RDR_POCKET + 0.01, RDR_R)
    pocket.apply_translation([px, py, SKIRT_H])

    cuts = [
        cube(sx, sy, -0.1, skirt_cav_w, skirt_cav_d, ENGAGE + 0.1),   # Rock greift über Box
        cube(nx, ny, ENGAGE, neck_w, neck_d, NECK_H + 0.01),          # Hals (Auflage-Leiste)
        pocket,                                                        # Reader-Mulde
        cube(LID_W / 2 - 13, -0.1, LID_H - 3, 26, 11, 2.9),           # Griffmulde (< 3 mm, kein Durchbruch)
    ]
    return body.difference(trimesh.boolean.union(cuts))


# ── Export ───────────────────────────────────────────────────
def report(name, mesh):
    print(f"  {name:12s} watertight={mesh.is_watertight}  "
          f"bodies={mesh.body_count}  "
          f"bbox={np.round(mesh.extents, 1)}")


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    print("Baue Unterteil …")
    b = bottom()
    print("Baue Deckel …")
    l = lid()

    b.export(os.path.join(here, "unterteil.stl"))
    l.export(os.path.join(here, "deckel.stl"))

    print("Fertig:")
    report("unterteil", b)
    report("deckel", l)
