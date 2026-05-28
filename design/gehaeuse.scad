// ============================================================
//  Navidrome NFC Box
//  Gehäuse für Raspberry Pi 3 Model B + ACR1252U NFC Reader
// ============================================================
//  Zwei Teile: Unterteil (bottom) + Deckel (lid)
//  Drucken ohne Support, flach auf dem Druckbett
//  Empfohlen: PLA, 0.2 mm Schicht, 3 Perimeter, 20 % Infill
//
//  ┌─────────────────────────┐  ← Deckel:  NFC-Reader eingelassen
//  │  ┌─────────────────┐    │
//  │  │  ACR1252U       │    │    Karte drauflegen = Musik startet
//  │  └─────────────────┘    │
//  └─────────────────────────┘
//  ┌─────────────────────────┐  ← Unterteil: Raspberry Pi 3B
//  │  [Pi3B]  Abstandshalter │
//  │  USB │ ETH    PWR │ AUD │
//  └─────────────────────────┘
//
//  Hinweis: Maße vor dem Druck mit Messschieber am eigenen Pi prüfen!
// ============================================================

$fn = 48;


// ============================================================
//  PARAMETER – hier anpassen wenn nötig
// ============================================================

// Wandstärke & Spielraum
WALL   = 2.5;   // Wandstärke
FLOOR  = 2.5;   // Bodenstärke
GAP    = 0.3;   // Spiel Pi ↔ Wand / Deckel ↔ Unterteil

// Raspberry Pi 3B  (PCB = 85 × 56 mm)
PI_W  = 85;
PI_D  = 56;
PI_STANDOFF_H = 5;    // Abstandshalter-Höhe (Pi hebt über Boden)
PI_BODY_H     = 22;   // Bauraum für Pi + Kühlkörper + Kabel

// Pi Montagelöcher M2.5 (Position von PCB-Ecke, USB-Seite hinten)
// ! mit Messschieber am eigenen Board prüfen !
PI_HOLES = [ [3.5, 3.0], [3.5, 52.5], [61.5, 3.0], [61.5, 52.5] ];

// ACR1252U NFC Reader  (ca. 98 × 65 × 8.5 mm)
NFC_W = 98;
NFC_D = 65;
NFC_H = 8.5;   // Höhe (ohne USB-Stecker-Überhang)
NFC_R = 5;     // Eckenradius

// Innenmaß Box (Pi + Kabelpuffer)
INNER_W = PI_W + 15;   // = 100 mm
INNER_D = PI_D + 14;   // =  70 mm

// Pi zentriert in Box
PI_X = (INNER_W - PI_W) / 2;
PI_Y = (INNER_D - PI_D) / 2;

// Außenmaß
OUTER_W = INNER_W + 2*WALL;   // ≈ 105 mm
OUTER_D = INNER_D + 2*WALL;   // ≈  75 mm
OUTER_H = FLOOR + PI_STANDOFF_H + PI_BODY_H;  // ≈  30 mm

// Deckel-Gesamthöhe
LID_H = NFC_H + WALL + 1;     // ≈  12 mm

// Reibschluss-Rand (Deckel sitzt 4 mm tief im Unterteil)
SNAP_DEPTH = 4;


// ============================================================
//  HILFSFUNKTIONEN
// ============================================================

module rbox(w, d, h, r=4) {
    // Abgerundete Box
    hull()
        for (x = [r, w-r], y = [r, d-r])
            translate([x, y, 0]) cylinder(r=r, h=h);
}

module standoff(h, od=6, id=2.8) {
    // Zylindrischer Abstandshalter mit M2.5-Bohrung
    difference() {
        cylinder(d=od, h=h);
        cylinder(d=id, h=h+0.1);
    }
}

module port_slot(w, h, depth=WALL+2) {
    // Einfacher rechteckiger Port-Ausschnitt
    cube([w, depth, h]);
}


// ============================================================
//  UNTERTEIL
// ============================================================
// USB-Ports zeigen nach HINTEN  (+Y)
// Power/HDMI/Audio zeigen nach VORNE (-Y)
// SD-Karte zeigt nach RECHTS (+X)

module bottom() {
    difference() {
        // ── Außenkörper ──────────────────────────────────────
        rbox(OUTER_W, OUTER_D, OUTER_H);

        // ── Innenraum ────────────────────────────────────────
        translate([WALL, WALL, FLOOR])
            cube([INNER_W, INNER_D, OUTER_H]);

        // ── Port-Ausschnitte ─────────────────────────────────
        port_z = FLOOR + PI_STANDOFF_H + 0.5;   // Unterkante Ports
        px = WALL + PI_X;                        // Pi-Offset X
        py = WALL + PI_Y;                        // Pi-Offset Y

        // VORNE (Y=0): Micro-USB Power, HDMI, 3.5mm Audio
        // Micro USB Power  (≈ x=6..17 vom Pi-Rand, 4 mm hoch)
        translate([px + 6,  -0.1, port_z])
            port_slot(11, 5);

        // HDMI  (≈ x=29..45, 7.5 mm hoch)
        translate([px + 29, -0.1, port_z])
            port_slot(16, 8);

        // 3.5 mm Audio  (≈ x=50..59, 8 mm hoch)
        translate([px + 50, -0.1, port_z + 1])
            port_slot(8, 8);

        // HINTEN (Y=OUTER_D): 4× USB + Ethernet  (volle Breite)
        translate([px - 1, OUTER_D - WALL - 0.1, port_z])
            port_slot(PI_W + 2, 17);

        // RECHTS (X=OUTER_W): SD-Karte (sitzt tief, Höhe ~3 mm)
        translate([OUTER_W - WALL - 0.1, py + 38, 0])
            rotate([0, 0, 0])
            port_slot(16, FLOOR + 4, WALL+2);

        // ── Lüftungsschlitze (Boden) ─────────────────────────
        for (i = [0:4])
            translate([WALL + 8 + i*13, WALL + 10, -0.1])
                cube([7, INNER_D - 20, FLOOR + 0.2]);

        // ── Reibschluss-Nut für Deckelrand ───────────────────
        // Deckel sitzt mit SNAP_DEPTH mm Rand INNEN im Unterteil
        // → keine weitere Nut nötig, Rand ist schon da
    }

    // ── Abstandshalter für Pi ─────────────────────────────────
    translate([WALL + PI_X, WALL + PI_Y, FLOOR])
        for (h = PI_HOLES)
            translate(h) standoff(PI_STANDOFF_H);
}


// ============================================================
//  DECKEL
// ============================================================
// Liegt umgedreht auf dem Druckbett (Außenfläche unten).
// Der NFC-Reader wird von oben eingesetzt.
// USB-Kabel vom NFC-Reader läuft durch Schlitz auf Pi-USB-Port.

module lid() {
    difference() {
        union() {
            // ── Deckfläche ────────────────────────────────────
            rbox(OUTER_W, OUTER_D, LID_H);

            // ── Einführrand (sitzt in Unterteil-Innenraum) ────
            // Außenmaß = INNER_W - 2*GAP, Tiefe = SNAP_DEPTH
            translate([WALL - GAP, WALL - GAP, 0])
                difference() {
                    rbox(INNER_W + 2*GAP, INNER_D + 2*GAP, SNAP_DEPTH + WALL, r=3);
                    translate([WALL + GAP, WALL + GAP, -0.1])
                        rbox(INNER_W - 2*WALL, INNER_D - 2*WALL, SNAP_DEPTH + WALL + 0.2, r=2);
                }
        }

        // ── NFC-Reader Einlass (zentriert auf Deckel) ─────────
        nfc_x = (OUTER_W - NFC_W) / 2;
        nfc_y = (OUTER_D - NFC_D) / 2;
        translate([nfc_x, nfc_y, WALL])
            rbox(NFC_W, NFC_D, NFC_H + 1, r=NFC_R);

        // ── Kabelschlitz: USB-Kabel NFC → Pi ──────────────────
        // Liegt an der Hinterkante des NFC-Readers
        translate([OUTER_W/2 - 6, OUTER_D - WALL - SNAP_DEPTH - 16, WALL - 0.1])
            cube([12, 15, NFC_H + 0.2]);

        // ── Lüftungsschlitze (Deckel, seitlich) ───────────────
        for (i = [0:3])
            translate([WALL + 6, WALL + 8 + i*14, LID_H - 1])
                cube([OUTER_W - 2*WALL - 12, 8, 2]);
    }

    // ── NFC-Reader Rahmen / Einfassung ────────────────────────
    nfc_x = (OUTER_W - NFC_W) / 2;
    nfc_y = (OUTER_D - NFC_D) / 2;
    translate([nfc_x - 1.5, nfc_y - 1.5, WALL + NFC_H])
        difference() {
            rbox(NFC_W + 3, NFC_D + 3, 1.5, r=NFC_R + 1.5);
            translate([1.5, 1.5, -0.1])
                rbox(NFC_W, NFC_D, 2, r=NFC_R);
        }
}


// ============================================================
//  AUSGABE
// ============================================================
// Beide Teile nebeneinander – zum Slicen in richtige Lage drehen!
//   Unterteil: steht aufrecht (Boden unten)  ✓
//   Deckel:    umdrehen! (Außenfläche = Druckbett)

color("SteelBlue",  0.9) bottom();

translate([OUTER_W + 20, 0, LID_H])
    rotate([180, 0, 0])
        color("LightSkyBlue", 0.9) lid();
