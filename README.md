# Navidrome NFC Cards

Selbstgebaute Toniebox für Erwachsene (und Kinder). NFC-Karten antippen → Musik aus dem eigenen [Navidrome](https://www.navidrome.org/)-Server läuft.

Inspiriert von [diesem Reddit-Post](https://www.reddit.com/r/navidrome/) und [gelly-nfc](https://github.com/Fingel/gelly-nfc), aber direkt gegen die Subsonic-API gebaut – kein Gelly, keine Abhängigkeit von einem Desktop-Player.

---

## Architektur

```
┌─────────────────────┐        Subsonic API        ┌──────────────────┐
│   Raspberry Pi      │ ◄────────────────────────► │  Navidrome       │
│                     │                             │  (TrueNAS o.ä.) │
│  ┌───────────────┐  │                             └──────────────────┘
│  │ ACR1252U      │  │
│  │ NFC-Reader    │  │
│  └───────┬───────┘  │
│          │ Karte    │
│          ▼          │
│  ┌───────────────┐  │
│  │ NFC-Daemon    │──┼──► mpv ──► Lautsprecher
│  └───────────────┘  │
│  ┌───────────────┐  │
│  │ Web-UI :8080  │  │   (für Karten-Verwaltung)
│  └───────────────┘  │
└─────────────────────┘
```

---

## Hardware

| Teil | Modell |
|------|--------|
| NFC-Reader | [ACR1252U](https://www.acs.com.hk/en/products/342/acr1252u-usb-nfc-reader-iii-nfc-forum-certified-reader/) USB NFC Reader III |
| NFC-Karten | NTAG213 (ISO 14443-3A, 144 Byte) |
| Wiedergabe | Raspberry Pi + Lautsprecher (3,5 mm / USB) |
| Musik-Server | Navidrome (auf TrueNAS, NAS, VPS, …) |

---

## Funktionsweise

Eine Karte kann auf **zwei Arten** einem Album/Track zugewiesen werden:

### A) Karte direkt beschreiben *(empfohlen)*
```
NTAG213-Chip enthält: album:abc123def456
```
Die Karte ist **self-contained** – funktioniert ohne Datenbank, sogar auf anderen Geräten. Format kompatibel mit [gelly-nfc](https://github.com/Fingel/gelly-nfc).

### B) UID-Mapping via Web-UI
```
Lokale SQLite-DB: UID AA:BB:CC:DD → album:abc123def456
```
Karte muss nicht beschrieben werden – die UID wird als Schlüssel genutzt.

**Beim Antippen wird zuerst A versucht, dann B.**

---

## Installation (Raspberry Pi)

### 1. System-Pakete

```bash
sudo apt update
sudo apt install pcscd libpcsclite-dev mpv git python3-pip python3-venv
sudo systemctl enable --now pcscd
```

### 2. User-Rechte für NFC-Reader

```bash
sudo usermod -aG plugdev $USER
# danach neu einloggen oder: newgrp plugdev
```

### 3. Projekt einrichten

```bash
git clone https://github.com/brummilab/navidrome-nfc-cards.git
cd navidrome-nfc-cards

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
```

### 4. Konfiguration

```bash
cp config.example.yaml config.yaml
nano config.yaml
```

Mindest-Konfiguration:

```yaml
navidrome:
  url: http://192.168.1.100:4533   # IP des Navidrome-Servers
  username: dein-user
  password: dein-passwort
```

### 5. Starten

```bash
# Web-UI (http://raspberrypi:8080)
python -m src.web.app

# NFC-Daemon (separates Terminal)
python -m src.run_daemon
```

---

## Karten beschreiben

### Reader prüfen
```bash
python -m src.card_writer list-readers
# [0] ACS ACR1252 Dual Reader PICC 0
```

### Karte tippen & UID anzeigen
```bash
python -m src.card_writer scan
# UID: AA:BB:CC:DD
```

### Navidrome-ID ermitteln
Die Album-ID findest du in der Navidrome-Weboberfläche in der URL:
`http://navidrome:4533/app/#/album/abc123def456`

Oder über die Subsonic-API:
```
GET /rest/search3?query=albumname&albumCount=5&...
```

### Text auf Karte schreiben
```bash
python -m src.card_writer write "album:abc123def456"
python -m src.card_writer write "track:song789xyz"
python -m src.card_writer write "playlist:myplaylist"
python -m src.card_writer write "artist:artistid"
```

### Inhalt einer Karte lesen
```bash
python -m src.card_writer read-ndef
# UID:  AA:BB:CC:DD
# NDEF: album:abc123def456
```

---

## Web-UI

`http://raspberrypi:8080`

| Seite | Funktion |
|-------|----------|
| **Karten** | Übersicht aller UID-Mappings |
| **Scannen** | Karte antippen → UID anzeigen |
| **Musik** | Navidrome durchsuchen, UID per Klick zuweisen |

---

## Autostart mit systemd

```bash
sudo nano /etc/systemd/system/navidrome-nfc-daemon.service
```

```ini
[Unit]
Description=Navidrome NFC Daemon
After=network.target pcscd.service

[Service]
User=pi
WorkingDirectory=/home/pi/navidrome-nfc-cards
ExecStart=/home/pi/navidrome-nfc-cards/.venv/bin/python -m src.run_daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo nano /etc/systemd/system/navidrome-nfc-web.service
```

```ini
[Unit]
Description=Navidrome NFC Web-UI
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/navidrome-nfc-cards
ExecStart=/home/pi/navidrome-nfc-cards/.venv/bin/python -m src.web.app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now navidrome-nfc-daemon
sudo systemctl enable --now navidrome-nfc-web
```

---

## Docker (alternativ)

```bash
cp config.example.yaml config.yaml
docker compose up -d
```

> Der `reader`-Service benötigt Zugriff auf USB-Geräte (`privileged: true` in `docker-compose.yml`). Auf dem Raspberry Pi ist das native Setup einfacher.

---

## Konfigurationsreferenz

| Option | Standard | Beschreibung |
|--------|----------|--------------|
| `navidrome.url` | – | URL des Navidrome-Servers |
| `navidrome.username` | – | Benutzername |
| `navidrome.password` | – | Passwort |
| `playback.mode` | `mpv` | `mpv` = lokal auf Pi, `jukebox` = serverseitig |
| `playback.mpv_options` | `[]` | z. B. `["--volume=80"]` |
| `nfc.reader_index` | `0` | Index des Readers (`list-readers` anzeigen) |
| `nfc.debounce_seconds` | `5` | Cooldown: selbe Karte nicht öfter triggern |
| `web.port` | `8080` | Port der Web-UI |
| `data.db_path` | `data/mappings.db` | Pfad zur SQLite-Datenbank |

Umgebungsvariablen überschreiben `config.yaml`:
`NAVIDROME_URL`, `NAVIDROME_USERNAME`, `NAVIDROME_PASSWORD`, `WEB_SECRET_KEY`

---

## Projektstruktur

```
src/
  config.py          Config-Loader (YAML + Env-Vars)
  navidrome.py       Subsonic API Client
  mappings.py        SQLite UID-Mapping
  player.py          Wiedergabe via mpv oder Jukebox
  nfc_reader.py      NFC-Daemon (CardMonitor, event-driven)
  card_writer.py     CLI: UIDs lesen, NDEF schreiben/lesen
  run_daemon.py      Entry Point Daemon
  web/
    app.py           Flask Web-UI
    templates/       Jinja2 Templates (Bootstrap 5)
```

---

## Abhängigkeiten

- Python 3.10+
- `pyscard` – PC/SC Zugriff auf den NFC-Reader
- `ndeflib` – NDEF Record Encoding/Decoding
- `flask` – Web-UI
- `requests`, `pyyaml` – API-Client und Config
- `mpv` – lokale Audio-Wiedergabe
- `pcscd` – PC/SC Daemon (System-Paket)
