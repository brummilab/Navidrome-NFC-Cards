# Navidrome NFC Cards

NFC-Karten zum Abspielen von Musik auf einem selbst gehosteten [Navidrome](https://www.navidrome.org/)-Server.
Inspiriert vom Reddit-Post [r/navidrome](https://reddit.com/r/navidrome) – ähnlich wie Yoto, aber selbst gebaut.

## Hardware

- **NFC-Reader:** ACR1252U USB NFC Card Reader/Writer
- **Karten:** NTAG213 (oder andere ISO 14443-3A Karten)

## Funktionsweise

1. **Karte scannen** → UID der Karte wird gelesen
2. **Zuweisen** → Album, Track, Playlist oder Künstler in der Web-UI verknüpfen
3. **Abspielen** → Karte antippen → Musik startet automatisch via mpv oder Navidrome Jukebox

## Schnellstart

```bash
cp config.example.yaml config.yaml
# config.yaml bearbeiten: Navidrome URL, Username, Passwort

pip install -r requirements.txt

# Web-UI starten (http://localhost:8080)
python -m src.web.app

# NFC-Daemon starten (in separatem Terminal)
python -m src.run_daemon
```

## Docker

```bash
cp config.example.yaml config.yaml
# config.yaml anpassen
docker compose up -d
```

> **Hinweis:** Der `reader`-Service benötigt USB-Zugriff auf den NFC-Reader.
> Unter Linux muss der User in der `plugdev`-Gruppe sein (oder `privileged: true` in docker-compose.yml).

## Karten-Tool (CLI)

```bash
# Verfügbare Reader anzeigen
python -m src.card_writer list-readers

# UID der nächsten Karte anzeigen
python -m src.card_writer scan

# URI auf NTAG213 schreiben (optional)
python -m src.card_writer write "navidrome://album/abc123"
```

## Konfiguration

Alle Optionen in `config.yaml` (Vorlage: `config.example.yaml`):

| Option | Bedeutung |
|--------|-----------|
| `navidrome.url` | URL des Navidrome-Servers |
| `navidrome.username` | Benutzername |
| `navidrome.password` | Passwort |
| `playback.mode` | `mpv` (lokal) oder `jukebox` (Navidrome serverseitig) |
| `nfc.reader_index` | Index des USB-Readers (0 = erster) |
| `nfc.debounce_seconds` | Cooldown nach Karten-Trigger in Sekunden |

Alternativ können `NAVIDROME_URL`, `NAVIDROME_USERNAME`, `NAVIDROME_PASSWORD` und `WEB_SECRET_KEY` als Umgebungsvariablen gesetzt werden.

## Abhängigkeiten

- Python 3.10+
- `pyscard` (PC/SC Treiber für NFC-Reader)
- `flask`, `requests`, `pyyaml`
- `mpv` (für lokale Wiedergabe)
- `pcscd` läuft auf dem System (Paket: `pcscd`)

```bash
# Debian/Ubuntu/Raspberry Pi OS
sudo apt install pcscd libpcsclite-dev mpv
```
