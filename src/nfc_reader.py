import time
import logging
from typing import Optional, Callable

logger = logging.getLogger(__name__)

_GET_UID_APDU = [0xFF, 0xCA, 0x00, 0x00, 0x00]


def _read_uid(card) -> Optional[str]:
    """Read UID from a smartcard.Card object. Returns colon-separated hex or None."""
    try:
        from smartcard.util import toHexString
        conn = card.createConnection()
        conn.connect()
        data, sw1, sw2 = conn.transmit(_GET_UID_APDU)
        conn.disconnect()
        if sw1 == 0x90 and sw2 == 0x00:
            return toHexString(data).replace(" ", ":")
        return None
    except Exception as e:
        logger.debug(f"UID read error: {e}")
        return None


def get_card_uid(reader_index: int = 0) -> Optional[str]:
    """Return UID of currently present card (for web UI polling). Returns None if no card."""
    try:
        from smartcard.System import readers
        reader_list = readers()
        if not reader_list or reader_index >= len(reader_list):
            return None
        conn = reader_list[reader_index].createConnection()
        conn.connect()
        from smartcard.util import toHexString
        data, sw1, sw2 = conn.transmit(_GET_UID_APDU)
        conn.disconnect()
        if sw1 == 0x90 and sw2 == 0x00:
            return toHexString(data).replace(" ", ":")
        return None
    except Exception:
        return None


def run_daemon(config: dict, mappings, player) -> None:
    """
    Run the NFC reader daemon using pyscard CardMonitor (event-driven via
    SCardGetStatusChange – more efficient than sleep-polling).
    """
    from smartcard.CardMonitor import CardMonitor, CardObserver
    from smartcard.System import readers

    nfc_cfg = config.get("nfc", {})
    reader_index = nfc_cfg.get("reader_index", 0)
    debounce_seconds = nfc_cfg.get("debounce_seconds", 5)

    # Verify reader is present before starting
    reader_list = readers()
    if not reader_list:
        raise RuntimeError("No NFC readers found. Is pcscd running? (sudo systemctl start pcscd)")
    if reader_index >= len(reader_list):
        raise RuntimeError(f"Reader index {reader_index} not found ({len(reader_list)} reader(s) available)")
    logger.info(f"NFC daemon started – using: {reader_list[reader_index]}")

    last_uid: Optional[str] = None
    last_time: float = 0

    class _Observer(CardObserver):
        def update(self, observable, actions):
            nonlocal last_uid, last_time
            added, _ = actions
            for card in added:
                uid = _read_uid(card)
                if uid is None:
                    continue
                now = time.time()
                if uid != last_uid or (now - last_time) > debounce_seconds:
                    last_uid = uid
                    last_time = now
                    mapping = mappings.get_mapping(uid)
                    if mapping:
                        logger.info(f"Card {uid}: playing {mapping['item_type']} '{mapping['name']}'")
                        player.play(mapping["item_type"], mapping["item_id"])
                    else:
                        logger.info(f"Card {uid}: no mapping found (use web UI to assign)")

        def update_removed(self, observable, actions):
            nonlocal last_uid
            _, removed = actions
            if removed:
                last_uid = None

    observer = _Observer()
    monitor = CardMonitor()
    monitor.addObserver(observer)
    logger.info("Waiting for NFC cards…")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("NFC daemon stopping…")
    finally:
        monitor.deleteObserver(observer)
