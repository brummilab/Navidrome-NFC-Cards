// ============================================================
//  Navidrome NFC Box  ·  v5
//  Raspberry Pi 3 Model B (v1.2)  +  ACR1252U NFC-Reader
// ============================================================
//  Konzept (wie Toniebox):
//    · Unterteil  : Pi liegt auf 4 Abstandshaltern, Ports seitlich
//    · Deckel     : ACR1252U liegt OBEN eingelassen, Karte drauflegen
//                   Deckel stülpt sich mit Außenrock über das Unterteil
//
//  Druck: PLA · 0.2 mm · 3 Perimeter · 20 % Infill · ohne Support
//  Deckel zum Slicen NICHT drehen – Lese-Mulde zeigt nach oben,
//  Rock zeigt nach unten (überhängt 8 mm, druckbar ohne Support).
//
//  STL-Export: PART = "bottom"  bzw.  "lid"  setzen → F6 → STL.
//
//  ►►  Alle mit (*) markierten Maße am eigenen Pi mit dem
//      Messschieber prüfen und ggf. anpassen!  ◄◄
// ============================================================

$fn = 64;
PART = "both";          // "bottom" | "lid" | "both"


// ── Globale Wandstärken / Spiel ──────────────────────────────
WALL  = 2.5;            // Seitenwände Unterteil
FLOOR = 2.5;            // Boden Unterteil
TOP   = 1.5;            // Deckel-Dach über dem Reader (NFC liest durch!)
GAP   = 0.4;            // Spiel Deckel ↔ Unterteil


// ── Raspberry Pi 3 Model B ───────────────────────────────────
PI_W   = 85;            // Platinen-Breite  (X)
PI_D   = 56;            // Platinen-Tiefe   (Y)
PI_PCB = 1.4;           // Platinenstärke

// Montagelöcher: Rechteck 58 × 49 mm, 3.5 mm vom Rand (*)
PI_HX1 = 3.5;   PI_HX2 = 61.5;     // 3.5 + 58
PI_HY1 = 3.5;   PI_HY2 = 52.5;     // 3.5 + 49

STAND_H  = 4.0;         // Höhe Abstandshalter (Luft unter dem Pi)
STAND_OD = 6.0;         // Außendurchmesser
STAND_ID = 2.3;         // Loch für M2.5-Schraube (selbstschneidend)


// ── ACR1252U NFC-Reader ──────────────────────────────────────
RDR_W = 98;             // Reader-Breite  (X)
RDR_D = 65;             // Reader-Tiefe   (Y)
RDR_H = 12.8;           // Reader-Höhe    (Z)   ← lt. Datenblatt
RDR_R = 5;              // Eckenradius der Lese-Mulde


// ── Innenraum (muss Pi UND Reader fassen) ────────────────────
INNER_W = 102;          // > RDR_W (98) und > PI_W (85)
INNER_D = 70;           // > RDR_D (65) und > PI_D (56)
INNER_H = 21;           // Höhe für Pi + höchste Bauteile (USB/LAN ~13.5)

OUTER_W = INNER_W + 2*WALL;     // 107
OUTER_D = INNER_D + 2*WALL;     //  75
OUTER_H = FLOOR + INNER_H;      //  23.5

// Pi in die VORDER-RECHTS-Ecke schieben, damit die häufig
// genutzten Anschlüsse direkt an den Wänden liegen:
//   · rechte Schmalseite  (X=85-Kante): 4×USB + Ethernet
//   · vordere Längsseite  (Y=0-Kante) : Power / HDMI / Audio
PI_GAP = 2.0;
PI_X = INNER_W - PI_W - PI_GAP;       // 15  (links bleibt 15 mm, SD-Seite)
PI_Y = PI_GAP;                        //  2  (vorne bündig)

// Pi-Ursprung in Welt-Koordinaten
OX = WALL + PI_X;       // 17.5
OY = WALL + PI_Y;       //  4.5
// Oberkante Platine
PCB_TOP = FLOOR + STAND_H + PI_PCB;   // 7.9


// ── Deckel mit Außenrock ─────────────────────────────────────
SKIRT_T = 2.0;          // Wandstärke Rock
SKIRT_H = 8.0;          // Rock greift 8 mm über das Unterteil
SHELF   = 2.0;          // Boden der Lese-Mulde (Reader ruht darauf)
RDR_POCKET = RDR_H + 1.0;            // Mulde minimal höher als Reader

LID_W = OUTER_W + 2*(SKIRT_T + GAP); // 111.8
LID_D = OUTER_D + 2*(SKIRT_T + GAP); //  79.8
LID_H = SKIRT_H + SHELF + RDR_POCKET + TOP;   // 8+2+13.8+1.5 = 25.3


// ── Hilfsfunktionen ──────────────────────────────────────────

// Abgerundete Box: 2D-hull + linear_extrude (manifold-sicher)
module rbox(w, d, h, r = 4) {
    r_ = min(r, w/2 - 0.01, d/2 - 0.01);
    linear_extrude(height = h)
        hull() {
            translate([r_,    r_   ]) circle(r = r_);
            translate([w-r_,  r_   ]) circle(r = r_);
            translate([r_,    d-r_ ]) circle(r = r_);
            translate([w-r_,  d-r_ ]) circle(r = r_);
        }
}

module standoff(h) {
    difference() {
        cylinder(d = STAND_OD, h = h);
        translate([0, 0, -0.1]) cylinder(d = STAND_ID, h = h + 0.2);
    }
}


// ── UNTERTEIL ────────────────────────────────────────────────
module bottom() {
    difference() {
        // Außenkörper
        rbox(OUTER_W, OUTER_D, OUTER_H, r = 4);

        // Innenraum
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // ── Anschlüsse VORNE (Y = 0): Power · HDMI · Audio ──── (*)
        // micro-USB Power
        translate([OX + 5,  -0.1, PCB_TOP - 2]) cube([10, WALL+0.2, 8]);
        // HDMI
        translate([OX + 24, -0.1, PCB_TOP - 2]) cube([17, WALL+0.2, 8]);
        // 3.5-mm-Klinke
        translate([OX + 49, -0.1, PCB_TOP - 2]) cube([9,  WALL+0.2, 8]);

        // ── Anschlüsse RECHTS (X = 85-Kante): 4×USB + LAN ───── (*)
        // großes Fenster über die ganze Anschluss-Zone
        translate([OUTER_W - WALL - 0.1, OY + 2, PCB_TOP - 2])
            cube([WALL + 0.2, PI_D - 4, 14]);

        // ── microSD LINKS (X = 0-Kante) ──────────────────────── (*)
        translate([-0.1, OY + 21, FLOOR + 1])
            cube([WALL + 0.2, 14, 4]);

        // ── Lüftungsschlitze hintere Wand ────────────────────
        for (i = [0:4])
            translate([OUTER_W/2 - 30 + i*13, OUTER_D - WALL - 0.1, OUTER_H - 13])
                cube([7, WALL + 0.2, 9]);
    }

    // ── Abstandshalter (0.5 mm in den Boden, sauberer Union) ──
    sz = FLOOR - 0.5;
    sh = STAND_H + 0.5;
    translate([OX + PI_HX1, OY + PI_HY1, sz]) standoff(sh);
    translate([OX + PI_HX2, OY + PI_HY1, sz]) standoff(sh);
    translate([OX + PI_HX1, OY + PI_HY2, sz]) standoff(sh);
    translate([OX + PI_HX2, OY + PI_HY2, sz]) standoff(sh);
}


// ── DECKEL ───────────────────────────────────────────────────
//  Aufbau von unten nach oben:
//    z 0 … SKIRT_H            Rock (greift über das Unterteil)
//    z SKIRT_H … +SHELF       Zwischenboden (Reader ruht darauf)
//    z … +RDR_POCKET          Lese-Mulde (Reader liegt drin, Antenne oben)
//    z … +TOP                 Dach (NFC liest durch 1.5 mm PLA)
//
//      ┌───── Karte drauflegen ─────┐  z = LID_H
//      │   Dach 1.5 mm              │
//      │ ┌───────────────────────┐ │  Lese-Mulde
//      │ │   ACR1252U (face up)  │ │
//      │ └───────────────────────┘ │  Zwischenboden
//    ┌─┘                         └─┐
//    │ Rock                       │  z = 0
//    └─────────────────────────────┘
//
module lid() {
    skirt_cav_w = OUTER_W + 2*GAP;   // Unterteil rutscht hier hinein
    skirt_cav_d = OUTER_D + 2*GAP;

    pocket_w = RDR_W + 1;            // Reader-Mulde (etwas Spiel)
    pocket_d = RDR_D + 1;
    px = (LID_W - pocket_w) / 2;     // zentriert
    py = (LID_D - pocket_d) / 2;

    pocket_z0 = SKIRT_H + SHELF;     // Boden der Mulde (Reader-Auflage)

    difference() {
        rbox(LID_W, LID_D, LID_H, r = 5);

        // 1) Rock-Hohlraum: Unterteil schiebt sich hinein (von unten)
        translate([SKIRT_T, SKIRT_T, -0.1])
            cube([skirt_cav_w, skirt_cav_d, SKIRT_H + 0.1]);

        // 2) Lese-Mulde für den Reader (Dach von TOP bleibt stehen)
        //    Höhe = RDR_POCKET → endet TOP (1.5 mm) unter der Deckeloberseite
        translate([px, py, pocket_z0])
            rbox(pocket_w, pocket_d, RDR_POCKET + 0.01, r = RDR_R);

        // 3) Kabel-Durchführung: Reader-USB nach unten zum Pi
        translate([LID_W/2 - 8, py + 4, SKIRT_H - 0.1])
            cube([16, 10, SHELF + 0.2]);

        // 4) Karten-Griffmulde: Daumen-Aussparung am Rand der Mulde
        translate([LID_W/2 - 12, py - 0.1, LID_H - 4])
            cube([24, 8, 4.1]);
    }
}


// ── Ausgabe ──────────────────────────────────────────────────
if (PART == "bottom") {
    bottom();
} else if (PART == "lid") {
    lid();
} else {
    color("SteelBlue", 0.9) bottom();
    // Deckel daneben legen (nicht gedreht – so wird er gedruckt)
    translate([LID_W + 20, 0, 0])
        color("LightSkyBlue", 0.9) lid();
}
