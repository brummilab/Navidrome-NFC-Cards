# Druckanleitung – Navidrome NFC Box

Gehäuse für **Raspberry Pi 3 Model B** + **ACR1252U NFC-Reader**, ausgelegt für den **Bambu Lab P1S**.

Diese Anleitung ist für jemanden gedacht, der nur die Teile drucken soll – kein Vorwissen zum Projekt nötig.

---

## 1. Was wird gedruckt?

Zwei Teile – die fertigen STL-Dateien liegen direkt im Ordner `design/`:

| Datei | Beschreibung | Maße | ca. Druckzeit* |
|-------|--------------|------|----------------|
| [`unterteil.stl`](unterteil.stl) | Wanne, hält den Raspberry Pi | 94 × 65 × 24 mm | ~3 h |
| [`deckel.stl`](deckel.stl) | Aufnahme für den NFC-Reader, Karte wird oben aufgelegt | 104 × 71 × 23 mm | ~3,5 h |

\* grobe Schätzung bei 0,2 mm / 20 % Infill – Bambu Studio zeigt den genauen Wert.

Beide Teile passen einzeln locker aufs Druckbett (256 × 256 mm).

---

## 2. STL-Dateien (schon fertig im Repo)

Die beiden `.stl` liegen bereits in `design/` – einfach in Bambu Studio laden, fertig.

**Selbst neu erzeugen** (nur falls Maße angepasst wurden):

- Per Python (kein OpenSCAD nötig):
  ```bash
  pip install numpy scipy trimesh manifold3d
  python3 design/build_stl.py
  ```
- Oder per [OpenSCAD](https://openscad.org/): `design/gehaeuse.scad` öffnen,
  `PART = "bottom";` bzw. `PART = "lid";` setzen → **F6** → **Datei → Exportieren → STL**.

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

Beide Teile werden **ohne Support** gedruckt – aber auf die Ausrichtung achten:

```
UNTERTEIL  (Boden unten)          DECKEL  (Dach UNTEN aufs Bett!)
┌───────────────┐                   ↑ Rock-Öffnung zeigt nach OBEN
│   offen oben  │                 ┌───────────────┐
│               │                 │   Rock        │
│   Boden unten │                 ├───────────────┤
└───────────────┘                 │   Dach        │  ← glatte Seite
  ↑ Boden aufs Bett               └───────────────┘  liegt auf dem Bett
```

- **Unterteil**: flacher Boden auf dem Druckbett, offene Seite nach oben. (Standard, keine Drehung.)
- **Deckel**: um **180° kippen**, sodass das **Dach (die glatte Oberseite, auf die später die Karte kommt) flach auf dem Druckbett liegt** und die Rock-Öffnung nach oben zeigt.

> **Warum gekippt?** Läge der Deckel mit dem Rock auf dem Bett, müsste der Drucker das Dach als ~100 mm breite Brücke in der Luft drucken → braucht Support. Mit dem Dach nach unten gibt es nur eine winzige 2,3-mm-Auflage-Leiste als Überhang – die druckt der P1S problemlos ohne Support.
>
> Die Dach-Oberseite bekommt dadurch die Struktur des Druckbetts (bei Textured PEI eine schöne matte Optik). Die NFC-Lesefunktion stört das nicht.

In Bambu Studio: Teil markieren → Taste **R** (Rotieren) → um die X-Achse 180° → „auf Platte legen" (Taste **P** / Drop to bed).

---

## 5. Drucken

1. STLs in Bambu Studio laden (beide auf eine Platte oder nacheinander).
2. Deckel wie oben um 180° kippen, Unterteil bleibt wie es ist.
3. Profil wie in Schritt 3 wählen.
4. **Slicen** → Vorschau prüfen → an den Drucker senden.

---

## 6. Zusammenbau

1. **Pi einsetzen**: Raspberry Pi mit 4× M2.5-Schrauben auf die Abstandshalter im Unterteil schrauben. Anschlüsse zeigen zu den passenden Wandausschnitten (USB/LAN rechts, Power/HDMI/Audio vorne, SD-Karte links mittig).
2. **Reader einlegen**: ACR1252U von unten in die Deckel-Mulde legen (Geräteoberseite Richtung Dach). Er ruht auf der umlaufenden Auflage-Leiste, das Dach hält ihn nach oben.
3. **Kabel**: USB-Kabel des Readers durch die Kabel-Aussparung nach unten führen und am Pi einstecken.
4. **Schließen**: Deckel über das Unterteil stülpen – der Rock greift 8 mm über die Wände und zentriert alles.

**Karte abspielen:** NFC-Karte einfach oben auf den Deckel legen – der Reader liest durch das 1,5 mm dünne Dach.

---

## 7. Nach dem Druck / Feintuning

- Kein Stützmaterial, höchstens Brim abziehen.
- **Deckel zu stramm / zu locker?** In `design/gehaeuse.scad` den Parameter `GAP` anpassen
  (zu stramm → erhöhen, z. B. 0.2 → 0.3; zu locker → verringern), dann STL neu erzeugen
  (`python3 design/build_stl.py`) und neu drucken.
- **Port-Ausschnitt trifft nicht?** Die mit `(*)` markierten Maße in der `.scad` an den
  eigenen Pi anpassen.

Fertig. 🎉
