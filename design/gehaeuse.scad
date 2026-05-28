// ============================================================
//  Navidrome NFC Box  ·  v6
//  Raspberry Pi 3 Model B (v1.2)  +  ACR1252U NFC-Reader
// ============================================================
//  Konzept (Toniebox-Stil):
//    · Unterteil : SCHMAL, exakt für den Pi. Alle Anschlüsse
//                  liegen bündig an den Wänden (auch SD links mittig).
//    · Deckel    : BREITER, hält den ACR1252U face-up. Stülpt sich
//                  mit Rock über das Unterteil und überlappt es leicht.
//                  Karte oben auflegen → NFC liest durch 1.5 mm Dach.
//
//  Reader-Halterung:
//    Der Reader liegt in einer Mulde und ruht auf einer umlaufenden
//    Auflage-Leiste (Innenraum verengt sich unter der Mulde). Nach
//    oben hält ihn das Dach. Eingelegt wird er von unten, bevor der
//    Deckel aufs Unterteil kommt.
//
//  ── Bambu Lab P1S – Druckeinstellungen ──────────────────────
//    Filament : PLA Basic  oder  PETG HF (steifer/wärmefester)
//    Profil   : 0.20 mm Standard · 3 Wände · 20 % Gyroid
//    Support  : KEINER nötig
//
//  Druck-Ausrichtung (wichtig, sonst Support nötig!):
//    · Unterteil : Boden aufs Druckbett (offene Seite nach oben)
//    · Deckel    : DACH (glatte Oberseite) aufs Druckbett,
//                  Rock zeigt nach OBEN  →  keine Brücken, kein Support
//
//  STL-Export: PART = "bottom" bzw. "lid" → F6 → als STL exportieren.
//
//  ►►  Mit (*) markierte Port-Maße am eigenen Pi prüfen!  ◄◄
// ============================================================

$fn = 64;
PART = "both";          // "bottom" | "lid" | "both"


// ── Wandstärken / Spiel ──────────────────────────────────────
WALL  = 2.5;
FLOOR = 2.5;
TOP   = 1.5;            // Deckel-Dach (NFC liest hindurch!)
GAP   = 0.2;            // Spiel Deckel ↔ Unterteil (P1S sehr präzise)


// ── Raspberry Pi 3 Model B ───────────────────────────────────
PI_W   = 85;
PI_D   = 56;
PI_PCB = 1.4;

// Montagelöcher: Rechteck 58 × 49 mm, 3.5 mm vom Rand (*)
PI_HX1 = 3.5;   PI_HX2 = 61.5;
PI_HY1 = 3.5;   PI_HY2 = 52.5;

STAND_H  = 4.0;
STAND_OD = 6.0;
STAND_ID = 2.3;        // M2.5 selbstschneidend


// ── ACR1252U NFC-Reader ──────────────────────────────────────
RDR_W = 98;
RDR_D = 65;
RDR_H = 12.8;          // lt. Datenblatt
RDR_R = 5;


// ── UNTERTEIL (schmal, nur für den Pi) ───────────────────────
INNER_W = 89;          // Pi 85 + 2 mm Spiel je Seite
INNER_D = 60;          // Pi 56 + 2 mm Spiel je Seite
INNER_H = 21;          // Platz für höchste Bauteile (USB/LAN ~13.5)

OUTER_W = INNER_W + 2*WALL;     // 94
OUTER_D = INNER_D + 2*WALL;     // 65
OUTER_H = FLOOR + INNER_H;      // 23.5

PI_X = (INNER_W - PI_W) / 2;    // 2  (Pi zentriert)
PI_Y = (INNER_D - PI_D) / 2;    // 2
OX = WALL + PI_X;               // 4.5  Pi-Ursprung in Welt-Koord.
OY = WALL + PI_Y;               // 4.5
PCB_TOP = FLOOR + STAND_H + PI_PCB;   // 7.9


// ── DECKEL (breiter, hält den Reader) ────────────────────────
SKIRT_H    = 8.0;              // Rock greift 8 mm über das Unterteil
POCKET_WALL = 2.5;            // Wand um die Reader-Mulde
RDR_POCKET = RDR_H + 0.5;     // Muldentiefe (Reader + bisschen Luft)

pocket_w   = RDR_W + 1;        // 99  Reader-Mulde (etwas Spiel)
pocket_d   = RDR_D + 1;        // 66
skirt_cav_w = OUTER_W + 2*GAP; // 94.4  Unterteil rutscht hier hinein
skirt_cav_d = OUTER_D + 2*GAP; // 65.4

LID_W = pocket_w + 2*POCKET_WALL;   // 104
LID_D = pocket_d + 2*POCKET_WALL;   // 71
LID_H = SKIRT_H + RDR_POCKET + TOP; // 8 + 13.3 + 1.5 = 22.8

// Auflage-Leiste für den Reader = Differenz Mulde ↔ Rock-Hohlraum:
//   X: (99 - 94.4)/2 = 2.3 mm je Seite  → Reader ruht auf 2 Leisten
//   (Y-Leiste ist schmal; Reader liegt sicher auf den X-Leisten)


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
        rbox(OUTER_W, OUTER_D, OUTER_H, r = 4);

        // Innenraum
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // ── VORNE (Y=0): micro-USB · HDMI · Audio ──────────── (*)
        translate([OX + 5.6,  -0.1, PCB_TOP - 2]) cube([10, WALL+0.2, 8]); // Power
        translate([OX + 23.5, -0.1, PCB_TOP - 2]) cube([17, WALL+0.2, 8]); // HDMI
        translate([OX + 49,   -0.1, PCB_TOP - 2]) cube([9,  WALL+0.2, 8]); // Klinke

        // ── RECHTS (X=85-Kante): 4×USB + Ethernet ──────────── (*)
        translate([OUTER_W - WALL - 0.1, OY + 4, PCB_TOP - 2])
            cube([WALL + 0.2, PI_D - 8, 14]);

        // ── LINKS (X=0-Kante): microSD mittig (Rückseite) ──── (*)
        translate([-0.1, OY + 21, FLOOR + 1.5])
            cube([WALL + 0.2, 14, 5]);

        // ── Lüftungsschlitze hintere Wand (unter dem Rock) ───
        for (i = [0:3])
            translate([OUTER_W/2 - 22 + i*13, OUTER_D - WALL - 0.1, PCB_TOP])
                cube([7, WALL + 0.2, 6]);
    }

    // Abstandshalter (0.5 mm in den Boden → sauberer Union)
    sz = FLOOR - 0.5;
    sh = STAND_H + 0.5;
    translate([OX + PI_HX1, OY + PI_HY1, sz]) standoff(sh);
    translate([OX + PI_HX2, OY + PI_HY1, sz]) standoff(sh);
    translate([OX + PI_HX1, OY + PI_HY2, sz]) standoff(sh);
    translate([OX + PI_HX2, OY + PI_HY2, sz]) standoff(sh);
}


// ── DECKEL ───────────────────────────────────────────────────
//  Querschnitt (Einbaulage – Dach oben, Rock unten):
//
//      ┌──────── Karte drauflegen ────────┐  z = LID_H (22.8)
//      │  Dach 1.5 mm  (NFC liest durch)  │
//      │ ┌──────────────────────────────┐ │  Reader-Mulde
//      │ │      ACR1252U  (face up)      │ │  (RDR_POCKET tief)
//      │ ╞══╡ Auflage-Leiste 2.3 mm  ╞══╡ │  z = SKIRT_H (8)
//      │ │     Rock-Hohlraum            │ │  ← Unterteil rutscht hier rein
//    ──┘ └──────────────────────────────┘ └──  z = 0  (Rock-Unterkante)
//
module lid() {
    px = (LID_W - pocket_w) / 2;          // 2.5  Mulde zentriert
    py = (LID_D - pocket_d) / 2;          // 2.5
    sx = (LID_W - skirt_cav_w) / 2;       // 4.8  Rock-Hohlraum zentriert
    sy = (LID_D - skirt_cav_d) / 2;       // 2.8

    difference() {
        rbox(LID_W, LID_D, LID_H, r = 5);

        // 1) Rock-Hohlraum (von unten): Unterteil schiebt sich hinein
        translate([sx, sy, -0.1])
            cube([skirt_cav_w, skirt_cav_d, SKIRT_H + 0.1]);

        // 2) Reader-Mulde (über der Auflage-Leiste, Dach bleibt stehen)
        translate([px, py, SKIRT_H])
            rbox(pocket_w, pocket_d, RDR_POCKET + 0.01, r = RDR_R);

        // 3) Kabel-Aussparung: Reader-USB nach unten ins Unterteil
        translate([LID_W/2 - 8, py - 0.1, SKIRT_H - 4])
            cube([16, POCKET_WALL + 0.2, 4 + 0.2]);

        // 4) Karten-Griffmulde im Dach (Daumen-Aussparung vorne)
        translate([LID_W/2 - 13, -0.1, LID_H - 3])
            cube([26, 11, 3.1]);
    }
}


// ── Ausgabe ──────────────────────────────────────────────────
if (PART == "bottom") {
    bottom();
} else if (PART == "lid") {
    lid();
} else {
    color("SteelBlue",     0.9) bottom();
    translate([LID_W + 20, 0, 0])
        color("LightSkyBlue", 0.9) lid();
}
