# Navidrome NFC Cards

Selbstgebaute Toniebox: NFC-Karte antippen → Musik vom eigenen [Navidrome](https://www.navidrome.org/)-Server läuft sofort.

Inspiriert von [gelly-nfc](https://github.com/Fingel/gelly-nfc), aber direkt gegen die Subsonic-API gebaut – ohne Desktop-Player, läuft headless auf dem Raspberry Pi.

---

## Architektur

```
┌──────────────────────────┐        Subsonic API        ┌─────────────────────┐
│      Raspberry Pi        │ ◄────────────────────────► │  Navidrome          │
│                          │                             │  (TrueNAS, NAS, …)  │
│  ┌────────────────────┐  │                             └─────────────────────┘
│  │  ACR1252U          │  │
│  │  NFC-Reader (USB)  │  │
│  └─────────┬──────────┘  │
│            │ Karte tippen │
│            ▼             │
│  ┌─────────────────────┐ │
│  │  NFC-Daemon         │─┼──► mpv ──► Lautsprecher
│  └─────────────────────┘ │
│  ┌─────────────────────┐ │
│  │  Web-UI  :8080      │ │  ← Karten verwalten
│  └─────────────────────┘ │
└──────────────────────────┘
```

---

## Hardware

| Teil | Modell |
|------|--------|
| Einplatinen-Computer | Raspberry Pi 3 Model B (oder neuer) |
| NFC-Reader | [ACR1252U](https://www.acs.com.hk/en/products/342/acr1252u-usb-nfc-reader-iii-nfc-forum-certified-reader/) USB NFC Reader III |
| NFC-Karten | NTAG215 oder NTAG213 (ISO 14443-3A) |
| Lautsprecher | 3,5-mm-Klinke oder USB am Pi |
| Musik-Server | Navidrome (separat, z. B. auf TrueNAS) |

---

## Funktionsweise

Eine Karte kann auf zwei Arten einem Album / Track zugewiesen werden:

### A) Karte direkt beschreiben *(empfohlen)*

Der Text `album:abc123` wird als NDEF-Record direkt auf den Chip geschrieben.  
→ Karte ist **selbst-beschreibend**, kein DB-Eintrag nötig, kompatibel mit [gelly-nfc](https://github.com/Fingel/gelly-nfc).

### B) UID-Mapping via Web-UI

Die Karten-UID wird in einer lokalen SQLite-Datenbank einem Navidrome-Eintrag zugeordnet.  
→ Karte muss **nicht** beschrieben werden.

Beim Antippen wird immer zuerst **A** versucht, dann **B**.

---

## Installation

### 1. System-Pakete

```bash
sudo apt update
sudo apt install pcscd libpcsclite-dev mpv git python3-pip python3-venv
sudo systemctl enable --now pcscd
```

### 2. User-Rechte für NFC-Reader

```bash
sudo usermod -aG plugdev $USER
newgrp plugdev   # oder neu einloggen
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
# Terminal 1 – Web-UI  →  http://raspberrypi:8080
python -m src.web.app

# Terminal 2 – NFC-Daemon
python -m src.run_daemon
```

---

## Erste Karte beschreiben

```bash
# 1. Reader prüfen
python -m src.card_writer list-readers
# [0] ACS ACR1252 Dual Reader PICC 0

# 2. Navidrome-Album-ID herausfinden
#    → Navidrome Web-UI öffnen → Album anklicken → URL ablesen:
#    http://navidrome:4533/app/#/album/abc123def456
#                                        ^^^^^^^^^^^^^ das ist die ID

# 3. Karte beschreiben (Reader anschließen, Karte drauflegen)
python -m src.card_writer write "album:abc123def456"

# 4. Inhalt prüfen
python -m src.card_writer read-ndef
# UID:  AA:BB:CC:DD
# NDEF: album:abc123def456
```

Unterstützte Typen:

```bash
python -m src.card_writer write "album:<id>"
python -m src.card_writer write "track:<id>"
python -m src.card_writer write "playlist:<id>"
python -m src.card_writer write "artist:<id>"
```

---

## Web-UI

`http://raspberrypi:8080`

| Seite | Funktion |
|-------|----------|
| **Karten** | Übersicht aller UID-Mappings mit Cover |
| **Scannen** | Karte antippen → UID anzeigen |
| **Musik** | Navidrome durchsuchen, UID per Klick zuweisen |

---

## Autostart (systemd)

```bash
# Daemon-Service
sudo tee /etc/systemd/system/navidrome-nfc-daemon.service > /dev/null << 'EOF'
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
EOF

# Web-UI-Service
sudo tee /etc/systemd/system/navidrome-nfc-web.service > /dev/null << 'EOF'
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
EOF

sudo systemctl enable --now navidrome-nfc-daemon
sudo systemctl enable --now navidrome-nfc-web
```

---

## Gehäuse (3D-Druck)

Im Ordner `design/` liegt eine parametrische [OpenSCAD](https://openscad.org/)-Datei für ein Gehäuse:

- **Unterteil**: Raspberry Pi 3B auf Abstandshaltern, Port-Ausschnitte für Power / HDMI / Audio / USB / SD
- **Deckel**: ACR1252U liegt oben eingelassen → Karten einfach drauflegen

```
design/gehaeuse.scad  →  in OpenSCAD öffnen → F6 rendern → als STL exportieren
```

> Maße vor dem Druck mit Messschieber am eigenen Pi prüfen – steht als Kommentar in der Datei.

---

## Docker (alternativ)

```bash
cp config.example.yaml config.yaml
docker compose up -d
```

> Der `reader`-Service benötigt USB-Zugriff (`privileged: true` in `docker-compose.yml`).  
> Auf dem Raspberry Pi ist das native Setup unkomplizierter.

---

## Konfigurationsreferenz

| Option | Standard | Beschreibung |
|--------|----------|--------------|
| `navidrome.url` | – | URL des Navidrome-Servers |
| `navidrome.username` | – | Benutzername |
| `navidrome.password` | – | Passwort |
| `playback.mode` | `mpv` | `mpv` = lokal auf Pi · `jukebox` = serverseitig |
| `playback.mpv_options` | `[]` | z. B. `["--volume=80"]` |
| `nfc.reader_index` | `0` | Index des Readers (siehe `list-readers`) |
| `nfc.debounce_seconds` | `5` | Selbe Karte nicht öfter als alle X Sekunden triggern |
| `web.port` | `8080` | Port der Web-UI |
| `data.db_path` | `data/mappings.db` | Pfad zur SQLite-Datenbank |

Umgebungsvariablen überschreiben `config.yaml`:  
`NAVIDROME_URL` · `NAVIDROME_USERNAME` · `NAVIDROME_PASSWORD` · `WEB_SECRET_KEY`

---

## Projektstruktur

```
src/
  config.py        Config-Loader (YAML + Env-Vars)
  navidrome.py     Subsonic API Client
  mappings.py      SQLite UID-Mapping
  player.py        Wiedergabe via mpv oder Jukebox
  nfc_reader.py    NFC-Daemon (CardMonitor, event-driven)
  card_writer.py   CLI: UIDs lesen, NDEF schreiben/lesen
  run_daemon.py    Entry Point Daemon
  web/
    app.py         Flask Web-UI
    templates/     Jinja2 Templates (Bootstrap 5)
design/
  gehaeuse.scad    3D-Druck Gehäuse (OpenSCAD)
```

---

## Abhängigkeiten

| Paket | Zweck |
|-------|-------|
| `pyscard` | PC/SC Zugriff auf den NFC-Reader |
| `ndeflib` | NDEF Record Encoding/Decoding |
| `flask` | Web-UI |
| `requests` | Navidrome Subsonic API |
| `pyyaml` | Konfigurationsdatei |
| `mpv` *(System)* | Lokale Audio-Wiedergabe |
| `pcscd` *(System)* | PC/SC Daemon |
