// ============================================================
//  Navidrome NFC Box  v4
//  Raspberry Pi 3 Model B  +  ACR1252U NFC Reader
// ============================================================
//  PLA · 0.2 mm · 3 Perimeter · 20 % Infill · kein Support
//
//  STL-Export: PART auf "bottom" oder "lid" setzen,
//  F6 rendern → Datei → Als STL exportieren
//
//  Deckel beim Slicen um 180° drehen (Außenseite = Druckbett)!
// ============================================================

$fn = 48;
PART = "both";   // "bottom" | "lid" | "both"


// ── Parameter ────────────────────────────────────────────────

WALL  = 2.5;
FLOOR = 2.5;
GAP   = 0.3;

PI_W  = 85;   PI_D  = 56;
PI_SH = 5;    PI_BH = 22;
// M2.5 Montagelöcher – mit Messschieber prüfen!
PI_HX1 = 3.5;  PI_HX2 = 61.5;
PI_HY1 = 3.0;  PI_HY2 = 52.5;

NFC_W = 98;  NFC_D = 65;  NFC_H = 8.5;  NFC_R = 5;

INNER_W = PI_W + 15;   // 100
INNER_D = PI_D + 14;   //  70
PI_X = (INNER_W - PI_W) / 2;   // 7.5
PI_Y = (INNER_D - PI_D) / 2;   // 7.0

OUTER_W = INNER_W + 2*WALL;   // 105
OUTER_D = INNER_D + 2*WALL;   //  75
OUTER_H = FLOOR + PI_SH + PI_BH;   // 29.5

// Deckel: Platte + Außenrock
LID_PLATE = NFC_H + 2;   // 10.5 mm (2 mm Boden unter NFC-Einlass)
SKIRT_T   = 2.0;          // Rockwandstärke
SKIRT_H   = 5.0;          // Rockhöhe (greift über Außenwand)

// Deckel-Außenmaß (Rock liegt ÜBER der Box)
LID_W = OUTER_W + 2*(SKIRT_T + GAP);   // 110.6
LID_D = OUTER_D + 2*(SKIRT_T + GAP);   //  80.6


// ── Hilfsfunktionen ──────────────────────────────────────────

// 2D-hull + linear_extrude: robusteste manifold-Methode
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

module standoff(h, od = 6, id = 2.8) {
    difference() {
        cylinder(d = od, h = h);
        cylinder(d = id, h = h + 0.1);
    }
}


// ── UNTERTEIL ────────────────────────────────────────────────
module bottom() {
    pz = FLOOR + PI_SH;         // z-Unterkante Pi-Ports
    px = WALL + PI_X;           // Pi x-Offset in Box
    py = WALL + PI_Y;           // Pi y-Offset in Box

    difference() {
        rbox(OUTER_W, OUTER_D, OUTER_H, r = 4);

        // Innenraum
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // Ports VORNE (y=0): Micro-USB · HDMI · 3.5mm Audio
        translate([px+5,   -0.1, pz+0.5]) cube([11, WALL+0.2, 5.5]);
        translate([px+28,  -0.1, pz    ]) cube([15, WALL+0.2, 8.5]);
        translate([px+49,  -0.1, pz+1  ]) cube([ 9, WALL+0.2, 8  ]);

        // Ports HINTEN (y=OUTER_D): 4×USB + Ethernet
        translate([px-1, OUTER_D-WALL-0.1, pz])
            cube([PI_W+2, WALL+0.2, 18]);

        // SD-Karte RECHTS (x=OUTER_W)
        translate([OUTER_W-WALL-0.1, py+37, 0])
            cube([WALL+0.2, 16, FLOOR+4]);

        // Lüftungsschlitze rechte Seitenwand (über SD-Slot)
        for (i = [0:3])
            translate([OUTER_W-WALL-0.1, WALL+10+i*13, OUTER_H-16])
                cube([WALL+0.2, 8, 11]);
    }

    // Abstandshalter – 0.5 mm in Boden eingesenkt (sauberer Union)
    sx = WALL + PI_X;
    sy = WALL + PI_Y;
    sz = FLOOR - 0.5;
    sh = PI_SH + 0.5;
    translate([sx + PI_HX1, sy + PI_HY1, sz]) standoff(sh);
    translate([sx + PI_HX1, sy + PI_HY2, sz]) standoff(sh);
    translate([sx + PI_HX2, sy + PI_HY1, sz]) standoff(sh);
    translate([sx + PI_HX2, sy + PI_HY2, sz]) standoff(sh);
}


// ── DECKEL ───────────────────────────────────────────────────
//  Aufbau: Deckplatte + Außenrock (greift über Außenwand der Box)
//  Rock-Innenseite = OUTER_W+2*GAP × OUTER_D+2*GAP
//
//    ┌─────────────────────┐  z = LID_PLATE  (Deckelplatte oben)
//    │   NFC-Einlass       │
//    │   (Einlasstiefe =   │
//    │    NFC_H = 8.5 mm)  │
//    └─────────────────────┘  z = 0           (Plattenunterseite)
//  ┌─┐                   ┌─┐
//  │R│                   │R│  z = -SKIRT_H   (Rockunterkante)
//  └─┘                   └─┘
//  Rock liegt ÜBER den Außenwänden der Box (passt mit GAP = 0.3 mm)

module lid() {
    nx = (LID_W - NFC_W) / 2;   // NFC x-Offset in Deckel (5.8 mm)
    ny = (LID_D - NFC_D) / 2;   // NFC y-Offset in Deckel (7.8 mm)

    difference() {
        union() {
            // Deckplatte  (z = 0 … LID_PLATE)
            rbox(LID_W, LID_D, LID_PLATE, r = 5);

            // Außenrock  (z = -(SKIRT_H-0.5) … 0.5)
            // 0.5 mm Überlappung mit Platte → sicherer Union
            translate([0, 0, -(SKIRT_H - 0.5)])
                difference() {
                    rbox(LID_W, LID_D, SKIRT_H, r = 5);
                    // Rock innen aushöhlen mit cube → einfacher, manifold-sicher
                    translate([SKIRT_T, SKIRT_T, -0.1])
                        cube([LID_W - 2*SKIRT_T,
                              LID_D - 2*SKIRT_T,
                              SKIRT_H + 0.2]);
                }
        }

        // NFC-Reader Einlass von oben
        // Boden des Einlasses bei z = LID_PLATE - NFC_H = 2 mm → manifold
        translate([nx, ny, LID_PLATE - NFC_H])
            rbox(NFC_W, NFC_D, NFC_H + 0.1, r = NFC_R);

        // Kabelkerbe: USB-Kabel vom NFC-Reader durch hintere Rockwand
        translate([LID_W/2 - 7, LID_D - SKIRT_T - 0.1, -(SKIRT_H - 0.5) - 0.1])
            cube([14, SKIRT_T + 0.2, SKIRT_H + LID_PLATE + 0.3]);

        // Lüftungskerben (1 mm tief in Deckfläche)
        for (i = [0:3])
            translate([SKIRT_T + 8, SKIRT_T + 8 + i*13, LID_PLATE - 1.1])
                cube([LID_W - 2*SKIRT_T - 16, 7, 1.2]);
    }
}


// ── Ausgabe ──────────────────────────────────────────────────
if (PART == "bottom") {
    bottom();
} else if (PART == "lid") {
    lid();
} else {
    color("SteelBlue",     0.9) bottom();
    translate([LID_W + 20, -(SKIRT_T + GAP), LID_PLATE + SKIRT_H - 0.5])
        rotate([180, 0, 0])
            color("LightSkyBlue", 0.9) lid();
}
