// ============================================================
//  Navidrome NFC Box  ·  v7
//  Raspberry Pi 3 Model B (v1.2)  +  ACR1252U NFC-Reader
// ============================================================
//  Konzept (Toniebox-Stil):
//    · Unterteil : Breite = Reader-Breite → gleichmäßige Optik.
//                  Pi zentriert auf Abstandshaltern, Anschlüsse
//                  liegen bündig an den Wänden.
//    · Deckel    : Gleich breit wie Unterteil (nur kleiner Rand-
//                  Überstand wie ein klassischer Deckel). Hält den
//                  ACR1252U face-up in einer Mulde. Reader ruht auf
//                  einer umlaufenden Auflage-Leiste (Hals enger als
//                  Reader); Dach hält ihn nach oben.
//                  Karte oben auflegen → NFC liest durch 1.5 mm Dach.
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
PI_HX1 = 23.5;  PI_HX2 = 81.5;   // 180° flip: HX gespiegelt
PI_HY1 = 3.5;   PI_HY2 = 52.5;

STAND_H  = 4.0;
STAND_OD = 6.0;
STAND_ID = 2.3;        // M2.5 selbstschneidend


// ── ACR1252U NFC-Reader ──────────────────────────────────────
RDR_W = 98;
RDR_D = 65;
RDR_H = 12.8;          // lt. Datenblatt
RDR_R = 5;


// ── UNTERTEIL (reader-breit, Pi zentriert) ───────────────────
INNER_W = 98;          // = Reader-Breite → gleichmäßige Optik
INNER_D = 62;          // Pi 56 + ~3 mm Spiel je Seite
INNER_H = 20;          // Platz für höchste Bauteile (USB/LAN ~13.5)

OUTER_W = INNER_W + 2*WALL;     // 103
OUTER_D = INNER_D + 2*WALL;     // 67
OUTER_H = FLOOR + INNER_H;      // 22.5

PI_X = 2.0;                         // USB-Ports 2 mm von linker Wand (Pi 180° gedreht)
PI_Y = 1.0;                         // Stecker zeigen jetzt nach hinten → Luft dort nötig
OX = WALL + PI_X;                   // 4.5
OY = WALL + PI_Y;                   // 3.5
PCB_TOP = FLOOR + STAND_H + PI_PCB;   // 7.9


// ── DECKEL (gleichmäßiger Kasten mit Neck-Auflage) ───────────
SKIRT_H   = 10.0;     // Höhe bis Mulden-/Leistenboden
NECK_H    = 1.0;      // dünnes Band der Auflage-Leiste
ENGAGE    = SKIRT_H - NECK_H;   // 9 mm: so tief greift der Rock über die Box
SKIRT_T   = 2.5;
RDR_POCKET = RDR_H + 0.5;       // 13.3  Muldentiefe (Reader + Luft)

pocket_w    = RDR_W + 1;                        // 99  Reader-Mulde (Spiel)
pocket_d    = RDR_D + 1;                        // 66
skirt_cav_w = OUTER_W + 2*GAP;                  // 103.4  Unterteil rutscht rein
skirt_cav_d = OUTER_D + 2*GAP;                  // 67.4
neck_w      = RDR_W - 5;                        // 93  < Reader → Leiste
neck_d      = RDR_D - 5;                        // 60

LID_W = skirt_cav_w + 2*SKIRT_T;               // 108.4
LID_D = skirt_cav_d + 2*SKIRT_T;               // 72.4
LID_H = SKIRT_H + RDR_POCKET + TOP;            // 24.8

// Querschnitt Deckel (Einbaulage – Dach oben, Rock unten):
//
//   ┌──────── Karte drauflegen ────────┐  z = LID_H (24.8)
//   │  Dach 1.5 mm  (NFC liest durch)  │
//   │ ┌──────────────────────────────┐ │  Reader-Mulde
//   │ │      ACR1252U  (face up)     │ │  (RDR_POCKET tief)
//   │ ╞══╡ Auflage-Leiste (Neck) ╞══╡ │  z = SKIRT_H (10)
//   │ │     Rock-Hohlraum            │ │  ← Unterteil rutscht hier rein
// ──┘ └──────────────────────────────┘ └──  z = 0  (Rock-Unterkante)


// ── Hilfsfunktionen ──────────────────────────────────────────

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

        // ── HINTEN (Y=OUTER_D): Stromanschluss (Pi 180° gedreht) ──
        translate([OX + PI_W - 15.6, OUTER_D - WALL - 0.1, PCB_TOP - 2])
            cube([10, WALL + 0.2, 8]);

        // ── Lüftungsschlitze linke + rechte Wand ─────────────
        for (i = [0:3]) {
            translate([-0.1, OUTER_D/2 - 20 + i*13, PCB_TOP])
                cube([WALL + 0.2, 7, 6]);
            translate([OUTER_W - WALL - 0.1, OUTER_D/2 - 20 + i*13, PCB_TOP])
                cube([WALL + 0.2, 7, 6]);
        }
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
module lid() {
    px = (LID_W - pocket_w) / 2;       // Mulde zentriert
    py = (LID_D - pocket_d) / 2;
    sx = (LID_W - skirt_cav_w) / 2;    // Rock-Hohlraum zentriert
    sy = (LID_D - skirt_cav_d) / 2;
    nx = (LID_W - neck_w) / 2;         // Hals (Auflage-Leiste)
    ny = (LID_D - neck_d) / 2;

    difference() {
        rbox(LID_W, LID_D, LID_H, r = 5);

        // 1) Rock-Hohlraum (von unten): Unterteil schiebt sich hinein
        translate([sx, sy, -0.1])
            cube([skirt_cav_w, skirt_cav_d, ENGAGE + 0.1]);

        // 2) Hals-Aussparung (Auflage-Leiste bleibt stehen)
        translate([nx, ny, ENGAGE])
            cube([neck_w, neck_d, NECK_H + 0.01]);

        // 3) Reader-Mulde (über der Auflage-Leiste, Dach bleibt stehen)
        translate([px, py, SKIRT_H])
            rbox(pocket_w, pocket_d, RDR_POCKET + 0.01, r = RDR_R);

        // 4) Kabel-Slot: USB-Kabel links, direkt über den USB-Ports des Pi
        translate([5, ny + neck_d - 0.1, ENGAGE])
            cube([16, (py + pocket_d) - (ny + neck_d) + 0.2, SKIRT_H + 6 - ENGAGE]);

        // 5) Karten-Griffmulde im Dach (Daumen-Aussparung vorne, 0.1 mm vor Dach-Oberkante)
        translate([LID_W/2 - 13, -0.1, LID_H - 3])
            cube([26, 11, 2.9]);
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
