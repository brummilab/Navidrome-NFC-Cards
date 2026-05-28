// ============================================================
//  Navidrome NFC Box  v3
//  Gehäuse: Raspberry Pi 3 Model B  +  ACR1252U NFC Reader
// ============================================================
//  2 Druckteile ohne Support, flach auf Druckbett
//  PLA · 0.2 mm Schicht · 3 Perimeter · 20 % Infill
//
//  Zum Exportieren: PART = "bottom" oder PART = "lid" setzen,
//  dann F6 rendern und als STL speichern.
// ============================================================

$fn = 48;

// "bottom" | "lid" | "both"
PART = "both";


// ── Parameter ────────────────────────────────────────────────

WALL  = 2.5;
FLOOR = 2.5;
GAP   = 0.3;   // Spiel Deckel-Lippe ↔ Innenraum

// Raspberry Pi 3B  (PCB 85 × 56 mm)
PI_W    = 85;
PI_D    = 56;
PI_SH   = 5;    // Standoff-Höhe
PI_BH   = 22;   // Bauraum Pi + Kabel
// Montagelöcher M2.5 – mit Messschieber am Board prüfen!
PI_HOLES = [ [3.5,3.0], [3.5,52.5], [61.5,3.0], [61.5,52.5] ];

// ACR1252U  (≈ 98 × 65 × 8.5 mm)
NFC_W = 98;
NFC_D = 65;
NFC_H = 8.5;
NFC_R = 5;

// Innenmaß Box
INNER_W = PI_W + 15;   // 100 mm
INNER_D = PI_D + 14;   //  70 mm
PI_X    = (INNER_W - PI_W) / 2;
PI_Y    = (INNER_D - PI_D) / 2;

// Außenmaß
OUTER_W = INNER_W + 2*WALL;   // 105 mm
OUTER_D = INNER_D + 2*WALL;   //  75 mm
OUTER_H = FLOOR + PI_SH + PI_BH;   // ≈ 30 mm

// Deckel
LID_PLATE  = NFC_H + 2;   // 10.5 mm (2 mm Boden unter NFC-Einlass)
LIP_THICK  = 1.8;
LIP_DEPTH  = 5.0;


// ── Hilfsfunktionen ──────────────────────────────────────────

// Abgerundete Box: 2D-hull + linear_extrude = garantiert manifold
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

// Abstandshalter M2.5
module standoff(h, od = 6, id = 2.8) {
    difference() {
        cylinder(d = od, h = h);
        cylinder(d = id, h = h + 0.1);
    }
}


// ── UNTERTEIL ────────────────────────────────────────────────
module bottom() {
    pz = FLOOR + PI_SH;       // Unterkante Pi-Ports
    px = WALL + PI_X;         // Pi-Offset X in Box
    py = WALL + PI_Y;         // Pi-Offset Y in Box

    difference() {
        rbox(OUTER_W, OUTER_D, OUTER_H, r = 4);

        // Innenraum
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // Ports VORNE (y = 0): Power · HDMI · Audio
        translate([px+5,   -0.1, pz+0.5]) cube([11, WALL+0.2, 5.5]); // Micro-USB
        translate([px+28,  -0.1, pz    ]) cube([15, WALL+0.2, 8.5]); // HDMI
        translate([px+49,  -0.1, pz+1  ]) cube([9,  WALL+0.2, 8  ]); // 3.5mm Audio

        // Ports HINTEN (y = OUTER_D): 4×USB + Ethernet
        translate([px-1, OUTER_D-WALL-0.1, pz])
            cube([PI_W+2, WALL+0.2, 18]);

        // SD-Karte RECHTS (x = OUTER_W)
        translate([OUTER_W-WALL-0.1, py+37, 0])
            cube([WALL+0.2, 16, FLOOR+4]);

        // Lüftungsschlitze Boden
        for (i = [0:4])
            translate([WALL+8+i*13, WALL+10, -0.1])
                cube([7, INNER_D-20, FLOOR+0.2]);
    }

    // Abstandshalter: -0.1 in Boden eingesenkt → saubere Union
    translate([WALL+PI_X, WALL+PI_Y, FLOOR-0.1])
        for (h = PI_HOLES)
            translate(h) standoff(PI_SH + 0.1);
}


// ── DECKEL ───────────────────────────────────────────────────
module lid() {
    nx = (OUTER_W - NFC_W) / 2;   // NFC x-Offset (3.5 mm)
    ny = (OUTER_D - NFC_D) / 2;   // NFC y-Offset (5.0 mm)

    lw = INNER_W - 2*GAP;   // Lippenbreite
    ld = INNER_D - 2*GAP;   // Lippentiefe

    difference() {
        union() {
            // Deckplatte
            rbox(OUTER_W, OUTER_D, LID_PLATE, r = 4);

            // Zentrierlippe nach unten: +0.1 in Platte eingesenkt → saubere Union
            translate([WALL+GAP, WALL+GAP, -(LIP_DEPTH - 0.1)])
                difference() {
                    rbox(lw, ld, LIP_DEPTH, r = 3);
                    // Innen aussparen: 0.1 über Anfang und Ende hinaus schneiden
                    translate([LIP_THICK, LIP_THICK, -0.1])
                        rbox(lw-2*LIP_THICK, ld-2*LIP_THICK, LIP_DEPTH+0.2, r = 2);
                }
        }

        // NFC-Reader Einlass (von oben, zentriert)
        // Boden liegt bei z = LID_PLATE - NFC_H = 2 mm → manifold
        translate([nx, ny, LID_PLATE - NFC_H])
            rbox(NFC_W, NFC_D, NFC_H + 0.1, r = NFC_R);

        // Kabelaustritt: Kerbe in der hinteren Außenwand
        // USB-Kabel vom NFC-Reader geht hier durch die Wand nach unten
        translate([OUTER_W/2-7, OUTER_D-WALL-0.1, LID_PLATE-NFC_H-0.1])
            cube([14, WALL+0.2, NFC_H+0.2]);

        // Lüftungskerben (1 mm tief in Deckfläche)
        for (i = [0:3])
            translate([WALL+8, WALL+8+i*13, LID_PLATE-1.1])
                cube([OUTER_W-2*WALL-16, 7, 1.2]);
    }
}


// ── Ausgabe ──────────────────────────────────────────────────
if (PART == "bottom") {
    bottom();
} else if (PART == "lid") {
    lid();
} else {
    // Vorschau: beide Teile nebeneinander
    // Deckel ist umgedreht (Außenfläche = Druckbett beim Slicen!)
    color("SteelBlue",     0.9) bottom();
    translate([OUTER_W+20, 0, LID_PLATE+LIP_DEPTH])
        rotate([180, 0, 0])
            color("LightSkyBlue", 0.9) lid();
}
