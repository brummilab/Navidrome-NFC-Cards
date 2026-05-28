#!/usr/bin/env python3
"""Entry point for the NFC reader daemon."""

import logging
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from src.config import load_config
from src.navidrome import NavidromeClient
from src.mappings import MappingDB
from src.player import Player
from src.nfc_reader import run_daemon

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)

if __name__ == "__main__":
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    cfg = load_config(config_path)

    navidrome = NavidromeClient(
        cfg["navidrome"]["url"],
        cfg["navidrome"]["username"],
        cfg["navidrome"]["password"],
    )

    if not navidrome.ping():
        logging.error("Navidrome nicht erreichbar – bitte config.yaml prüfen")
        sys.exit(1)

    db = MappingDB(cfg["data"]["db_path"])
    playback_cfg = cfg.get("playback", {})
    player = Player(
        navidrome,
        mode=playback_cfg.get("mode", "mpv"),
        mpv_options=playback_cfg.get("mpv_options", []),
    )

    run_daemon(cfg, db, player)
