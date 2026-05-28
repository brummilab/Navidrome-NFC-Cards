// ============================================================
//  Navidrome NFC Box  v2
//  Gehäuse: Raspberry Pi 3 Model B  +  ACR1252U NFC Reader
// ============================================================
//  2 Druckteile – kein Support nötig, flach auf Druckbett
//  PLA · 0.2 mm Schicht · 3 Perimeter · 20 % Infill
//
//  Unterteil: Pi auf Abstandshaltern, Port-Ausschnitte
//  Deckel   : ACR1252U liegt oben eingelassen → Karte drauflegen
//
//  ! Pi-Montagelöcher und Port-Positionen mit Messschieber prüfen !
// ============================================================

$fn = 48;

// ── Wandstärken ──────────────────────────────────────────────
WALL  = 2.5;   // Wandstärke
FLOOR = 2.5;   // Bodenstärke
GAP   = 0.3;   // Spiel Deckel ↔ Unterteil

// ── Raspberry Pi 3B  (PCB 85 × 56 mm) ───────────────────────
PI_W = 85;
PI_D = 56;
PI_SH = 5;     // Abstandshalter-Höhe (Standoff)
PI_BH = 22;    // Bauraum Pi + Kabel

// Montagelöcher M2.5 (von PCB-Ecke, USB-Seite = hinten)
PI_HOLES = [ [3.5,3.0], [3.5,52.5], [61.5,3.0], [61.5,52.5] ];

// ── ACR1252U  (≈ 98 × 65 × 8.5 mm) ─────────────────────────
NFC_W = 98;
NFC_D = 65;
NFC_H = 8.5;   // Tiefe des Einlasses
NFC_R = 5;     // Eckenradius

// ── Box-Innenmaß ─────────────────────────────────────────────
INNER_W = PI_W + 15;   // 100 mm  (Pi + Kabelpuffer)
INNER_D = PI_D + 14;   //  70 mm

PI_X = (INNER_W - PI_W) / 2;   // Pi zentriert
PI_Y = (INNER_D - PI_D) / 2;

OUTER_W = INNER_W + 2*WALL;    // 105 mm
OUTER_D = INNER_D + 2*WALL;    //  75 mm
OUTER_H = FLOOR + PI_SH + PI_BH;  // ≈ 30 mm

// ── Deckel ───────────────────────────────────────────────────
// Plattendicke muss >= NFC_H + 2 sein damit Einlass Boden hat
LID_PLATE = NFC_H + 2;   // 10.5 mm  (2 mm Material unter NFC)
LIP_W     = 1.8;          // Lippendicke
LIP_D     = 5.0;          // Lippentiefe (greift in Unterteil)


// ============================================================
//  Hilfsfunktionen
// ============================================================

module rbox(w, d, h, r=4) {
    // Abgerundete Box – manifold, alle Ecken ≥ r
    r_ = min(r, w/2-0.01, d/2-0.01);
    hull()
        for (x=[r_, w-r_], y=[r_, d-r_])
            translate([x, y, 0]) cylinder(r=r_, h=h);
}

module standoff(h, od=6, id=2.8) {
    difference() {
        cylinder(d=od, h=h);
        cylinder(d=id, h=h+0.1);
    }
}


// ============================================================
//  UNTERTEIL
// ============================================================
module bottom() {
    // Basis-Z für Port-Ausschnitte (Unterkante der Pi-Ports)
    pz = FLOOR + PI_SH;
    px = WALL + PI_X;
    py = WALL + PI_Y;

    difference() {
        rbox(OUTER_W, OUTER_D, OUTER_H, r=4);

        // Innenraum
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // ── Ports VORNE (y=0): Power · HDMI · Audio ──────────
        // Micro-USB Power  (~x=6, b=11, h=5)
        translate([px+5,   -0.1, pz+0.5]) cube([11, WALL+0.2, 5.5]);
        // HDMI             (~x=29, b=15, h=8)
        translate([px+28,  -0.1, pz    ]) cube([15, WALL+0.2, 8.5]);
        // 3.5 mm Audio     (~x=49, b=8,  h=8)
        translate([px+49,  -0.1, pz+1  ]) cube([9,  WALL+0.2, 8  ]);

        // ── Ports HINTEN (y=OUTER_D): 4×USB + Ethernet ───────
        translate([px-1, OUTER_D-WALL-0.1, pz])
            cube([PI_W+2, WALL+0.2, 18]);

        // ── SD-Karte RECHTS (x=OUTER_W) ──────────────────────
        translate([OUTER_W-WALL-0.1, py+37, 0])
            cube([WALL+0.2, 16, FLOOR+4]);

        // ── Lüftungsschlitze Boden ────────────────────────────
        for (i=[0:4])
            translate([WALL+8+i*13, WALL+10, -0.1])
                cube([7, INNER_D-20, FLOOR+0.2]);
    }

    // Abstandshalter Pi
    translate([WALL+PI_X, WALL+PI_Y, FLOOR])
        for (h=PI_HOLES)
            translate(h) standoff(PI_SH);
}


// ============================================================
//  DECKEL
// ============================================================
module lid() {
    // NFC-Einlass: zentriert auf Deckplatte
    nx = (OUTER_W - NFC_W) / 2;
    ny = (OUTER_D - NFC_D) / 2;

    // Innen-Lippe: passt in Unterteil-Hohlraum
    lw = INNER_W - 2*GAP;
    ld = INNER_D - 2*GAP;

    difference() {
        union() {
            // Deckplatte
            rbox(OUTER_W, OUTER_D, LID_PLATE, r=4);

            // Zentrierlippe nach unten  (geht in Unterteil)
            translate([WALL+GAP, WALL+GAP, -LIP_D])
                difference() {
                    rbox(lw, ld, LIP_D, r=3);
                    translate([LIP_W, LIP_W, -0.1])
                        rbox(lw-2*LIP_W, ld-2*LIP_W, LIP_D+0.2, r=2);
                }
        }

        // NFC-Reader Einlass von oben
        // Boden des Einlasses liegt 2 mm über Plattenunterkante → manifold
        translate([nx, ny, LID_PLATE-NFC_H])
            rbox(NFC_W, NFC_D, NFC_H+0.1, r=NFC_R);

        // Kabelschlitz (USB-Kabel vom NFC-Reader nach unten)
        // Liegt an der HINTEREN Kante des NFC-Einlasses, geht durch Platte+Lippe
        translate([OUTER_W/2-6, ny+NFC_D-1, -LIP_D-0.1])
            cube([12, WALL+2, LID_PLATE+LIP_D+0.2]);

        // Lüftungsschlitze (flache Nuten in Deckfläche, 1 mm tief)
        for (i=[0:3])
            translate([WALL+8, WALL+8+i*13, LID_PLATE-1.1])
                cube([OUTER_W-2*WALL-16, 7, 1.2]);
    }
}


// ============================================================
//  AUSGABE  (beide Teile nebeneinander)
// ============================================================
// Unterteil: steht aufrecht, Boden = Druckbett  ✓
// Deckel:    muss beim Slicen um 180° gedreht werden (Außenfläche unten)

color("SteelBlue",  0.9) bottom();

translate([OUTER_W+20, 0, LID_PLATE+LIP_D])
    rotate([180,0,0])
        color("LightSkyBlue", 0.9) lid();
