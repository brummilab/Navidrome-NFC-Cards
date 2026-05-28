# Druckanleitung – Navidrome NFC Box

Gehäuse für **Raspberry Pi 3 Model B** + **ACR1252U NFC-Reader**, ausgelegt für den **Bambu Lab P1S**.

Diese Anleitung ist für jemanden gedacht, der nur die Teile drucken soll – kein Vorwissen zum Projekt nötig.

---

## 1. Was wird gedruckt?

Zwei Teile aus einer Datei:

| Teil | Beschreibung | ca. Maße | ca. Druckzeit* |
|------|--------------|----------|----------------|
| **Unterteil** (`bottom`) | Wanne, hält den Raspberry Pi | 107 × 75 × 24 mm | ~3 h |
| **Deckel** (`lid`) | Aufnahme für den NFC-Reader, Karte wird oben aufgelegt | 112 × 80 × 25 mm | ~3,5 h |

\* grobe Schätzung bei 0,2 mm / 20 % Infill – Bambu Studio zeigt den genauen Wert.

Beide Teile passen einzeln locker aufs Druckbett (256 × 256 mm).

---

## 2. STL-Dateien erzeugen (falls noch nicht vorhanden)

Wer nur fertige STLs bekommt, überspringt diesen Schritt.

1. [OpenSCAD](https://openscad.org/) installieren und `design/gehaeuse.scad` öffnen.
2. Oben im Code `PART` setzen und mit **F6** rendern, dann **Datei → Exportieren → STL**:
   - `PART = "bottom";` → `unterteil.stl`
   - `PART = "lid";` → `deckel.stl`

---

## 3. Bambu Studio – Einstellungen

| Einstellung | Wert |
|-------------|------|
| Drucker | Bambu Lab P1S |
| Filament | **PLA Basic** (einfach) – oder **PETG HF** (stabiler, wärmebeständiger) |
| Profil | **0.20 mm Standard** |
| Wandlinien (Wall loops) | **3** |
| Infill | **20 %**, Muster **Gyroid** |
| Support | **AUS** – wird nicht gebraucht |
| Brim | nur bei Haftproblemen (5 mm) |
| Platte | Textured PEI / Engineering Plate |

> Tipp PLA vs. PETG: Wenn die Box im Kinderzimmer auf dem Schreibtisch steht, reicht PLA. Steht sie am sonnigen Fenster oder nahe der Heizung → **PETG**, sonst kann sich PLA verziehen.

---

## 4. Ausrichtung auf dem Druckbett

Beide Teile werden **ohne Drehung** und **ohne Support** gedruckt:

```
UNTERTEIL                         DECKEL
┌───────────────┐                 Lese-Mulde zeigt nach OBEN
│   offen oben  │                 ┌───────────────┐
│               │                 │   Mulde       │  ← Reader + Karte
│   Boden unten │                 │               │
└───────────────┘                 └───────────────┘
  ↑ Boden aufs Bett                 ↑ Rock-Rand aufs Bett
```

- **Unterteil**: flacher Boden liegt auf dem Druckbett, die offene Seite zeigt nach oben.
- **Deckel**: der untere Rand (der „Rock") liegt auf dem Druckbett, die Mulde für den Reader zeigt nach oben.

Der Deckel hat einen 8 mm hohen Überhang am Rock – das druckt der P1S problemlos ohne Support (steile Innenwand).

---

## 5. Drucken

1. STLs in Bambu Studio laden (beide auf eine Platte oder nacheinander).
2. Profil wie in Schritt 3 wählen.
3. **Slicen** → Vorschau prüfen → an den Drucker senden.

---

## 6. Nach dem Druck

- Stützmaterial gibt es keins, nur ggf. Brim entfernen.
- **Passt der Deckel nicht** (zu stramm oder zu locker)? In `gehaeuse.scad` den Parameter `GAP` anpassen:
  - zu stramm → `GAP` erhöhen (z. B. 0.2 → 0.3)
  - zu locker → `GAP` verringern (z. B. 0.2 → 0.1)
  - neu rendern, neu drucken.

Fertig. 🎉
