# Druckanleitung – Navidrome NFC Box

Gehäuse für **Raspberry Pi 3 Model B** + **ACR1252U NFC-Reader**, ausgelegt für den **Bambu Lab P1S**.

Hier sind alle Infos, die du zum Drucken brauchst. Kein Vorwissen nötig.

---

## 1. Was wird gedruckt?

Zwei Teile – die STL-Dateien liegen im Ordner `design/`:

| Datei | Beschreibung | Maße | ca. Druckzeit* |
|-------|--------------|------|----------------|
| [`unterteil.stl`](unterteil.stl) | Wanne für den Raspberry Pi | 103 × 67 × 22,5 mm | ~3 h |
| [`deckel.stl`](deckel.stl) | Deckel mit Aufnahme für den NFC-Reader | 108 × 72 × 25 mm | ~3,5 h |

\* bei 0,2 mm Schichthöhe / 20 % Infill – Bambu Studio zeigt den genauen Wert.

Beide Teile passen einzeln problemlos aufs Druckbett (256 × 256 mm).

---

## 2. Bambu Studio – Einstellungen

| Einstellung | Wert |
|-------------|------|
| Drucker | Bambu Lab P1S |
| Filament | **PLA Basic** reicht – oder **PETG HF** (stabiler, wärmebeständiger) |
| Profil | **0.20 mm Standard** |
| Wandlinien (Wall loops) | **3** |
| Infill | **20 %**, Muster **Gyroid** |
| Support | **AUS** – wird nicht gebraucht |
| Brim | nur bei Haftproblemen (5 mm) |
| Platte | Textured PEI oder Engineering Plate |

---

## 3. Ausrichtung auf dem Druckbett ← wichtig!

```
UNTERTEIL  → normal, Boden unten    DECKEL  → um 180° kippen, Dach unten!

┌───────────────┐                   ↑ Öffnung zeigt nach OBEN
│   offen oben  │                 ┌───────────────┐
│               │                 │   Rock/Rand   │
│   Boden unten │                 ├───────────────┤
└───────────────┘                 │   Dach        │  ← liegt auf dem Bett
  ↑ Boden aufs Bett               └───────────────┘
```

- **Unterteil**: einfach so laden, nichts drehen – flacher Boden liegt automatisch unten.
- **Deckel**: **um 180° kippen**, sodass die **glatte Oberseite (auf die später die NFC-Karte gelegt wird) auf dem Druckbett liegt** und die Öffnung nach oben zeigt.

> **Warum muss der Deckel gekippt werden?** Normal stehend wäre das Dach eine ~108 mm breite hängende Fläche → Support nötig. Gekippt gibt es nur einen kleinen inneren Überstand, den der P1S problemlos ohne Support überbrückt.
>
> Bonus: Die Dach-Oberfläche bekommt die schöne matte Textur des Druckbetts. Die NFC-Funktion wird dadurch nicht beeinträchtigt (das Dach ist nur 1,5 mm dick).

In Bambu Studio: Teil markieren → **R** (Rotieren) → X-Achse 180° → **P** (Drop to bed / auf Platte legen).

---

## 4. Drucken

1. Beide STLs in Bambu Studio laden (auf eine Platte oder nacheinander).
2. Deckel wie oben um 180° kippen, Unterteil bleibt wie es ist.
3. Einstellungen aus Schritt 2 wählen.
4. **Slicen** → Vorschau kurz prüfen → an den Drucker senden.

---

## 5. Nach dem Druck

- Kein Stützmaterial vorhanden – höchstens einen Brim-Rand abziehen, falls gesetzt.
- Deckel sollte sich mit leichtem Widerstand auf das Unterteil stülpen lassen. Falls er zu stramm oder zu locker sitzt, kurze Rückmeldung → ich passe die Toleranz an und schicke neue STLs.

> **Hinweis Reader-Einbau** (falls du auch zusammenbaust): Der NFC-Reader wird von unten in die Deckel-Mulde gelegt, das **feste USB-Kabel zeigt dabei nach hinten** (weg von der Daumen-Griffmulde vorne) – nur dort sitzt der Kabel-Slot.

Danke! 🙏
