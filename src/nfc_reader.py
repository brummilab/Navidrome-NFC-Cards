import time
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

_GET_UID_APDU = [0xFF, 0xCA, 0x00, 0x00, 0x00]
_READ_PAGE    = lambda page: [0xFF, 0xB0, 0x00, page, 0x04]


# ---------------------------------------------------------------------------
# Low-level helpers
# ---------------------------------------------------------------------------

def _get_uid(connection) -> Optional[str]:
    from smartcard.util import toHexString
    data, sw1, sw2 = connection.transmit(_GET_UID_APDU)
    if sw1 == 0x90 and sw2 == 0x00:
        return toHexString(data).replace(" ", ":")
    return None


def _read_ndef_text(connection) -> Optional[str]:
    """
    Read NDEF from NTAG213 (NFC Forum Type 2) and return the first Text
    record's content, e.g. "album:abc123".  Returns None on any error.
    """
    try:
        # Capability Container at page 3
        data, sw1, _ = connection.transmit(_READ_PAGE(3))
        if sw1 != 0x90 or data[0] != 0xE1:
            return None

        # NDEF TLV starts at page 4
        data, sw1, _ = connection.transmit(_READ_PAGE(4))
        if sw1 != 0x90 or data[0] != 0x03:
            return None

        # Parse TLV length (1-byte or 3-byte form)
        if data[1] < 0xFF:
            ndef_len = data[1]
            ndef_data = bytes(data[2:])
            next_page = 5
        else:
            ndef_len = (data[2] << 8) | data[3]
            ndef_data = b""
            next_page = 5

        if ndef_len == 0:
            return None

        page = next_page
        while len(ndef_data) < ndef_len and page < 45:  # NTAG213 pages 0-44
            chunk, sw1, _ = connection.transmit(_READ_PAGE(page))
            if sw1 != 0x90:
                break
            ndef_data += bytes(chunk)
            page += 1

        import ndef
        for record in ndef.message_decoder(bytes(ndef_data[:ndef_len])):
            if isinstance(record, ndef.TextRecord):
                return record.text

    except Exception as e:
        logger.debug(f"NDEF read error: {e}")
    return None


def _parse_text(text: str) -> Optional[Tuple[str, str]]:
    """Parse "type:id" into (item_type, item_id). Returns None if invalid."""
    if ":" not in text:
        return None
    item_type, _, item_id = text.partition(":")
    item_type = item_type.strip().lower()
    if item_type in ("album", "track", "playlist", "artist") and item_id.strip():
        return item_type, item_id.strip()
    return None


# ---------------------------------------------------------------------------
# Public polling helper (used by Flask /api/card)
# ---------------------------------------------------------------------------

def get_card_uid(reader_index: int = 0) -> Optional[str]:
    """Return UID of currently present card, or None. Used for web UI polling."""
    try:
        from smartcard.System import readers
        reader_list = readers()
        if not reader_list or reader_index >= len(reader_list):
            return None
        conn = reader_list[reader_index].createConnection()
        conn.connect()
        uid = _get_uid(conn)
        conn.disconnect()
        return uid
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Daemon
# ---------------------------------------------------------------------------

def run_daemon(config: dict, mappings, player) -> None:
    """
    Event-driven NFC daemon using pyscard CardMonitor (SCardGetStatusChange).

    Card resolution order:
      1. NDEF Text on card  → play directly (self-contained, written via card_writer)
      2. UID in DB          → play via mapping
      3. Unknown            → log and skip
    """
    from smartcard.CardMonitor import CardMonitor, CardObserver
    from smartcard.System import readers

    nfc_cfg       = config.get("nfc", {})
    reader_index  = nfc_cfg.get("reader_index", 0)
    debounce_secs = nfc_cfg.get("debounce_seconds", 5)

    reader_list = readers()
    if not reader_list:
        raise RuntimeError(
            "No NFC readers found. Is pcscd running?\n"
            "  sudo systemctl enable --now pcscd"
        )
    if reader_index >= len(reader_list):
        raise RuntimeError(
            f"Reader index {reader_index} not found "
            f"({len(reader_list)} reader(s) available)"
        )
    logger.info(f"NFC daemon started – using: {reader_list[reader_index]}")

    state = {"last_uid": None, "last_time": 0.0}

    def _handle_card(card):
        try:
            conn = card.createConnection()
            conn.connect()
            uid  = _get_uid(conn)
            text = _read_ndef_text(conn)
            conn.disconnect()
        except Exception as e:
            logger.error(f"Card connect error: {e}")
            return

        if uid is None:
            return

        now = time.time()
        if uid == state["last_uid"] and (now - state["last_time"]) < debounce_secs:
            return
        state["last_uid"]  = uid
        state["last_time"] = now

        # Priority 1: NDEF text on card
        if text:
            parsed = _parse_text(text)
            if parsed:
                item_type, item_id = parsed
                logger.info(f"Card {uid}: NDEF '{text}' → playing {item_type}")
                player.play(item_type, item_id)
            else:
                logger.warning(f"Card {uid}: unrecognised NDEF text '{text}'")
            return

        # Priority 2: UID in DB
        mapping = mappings.get_mapping(uid)
        if mapping:
            logger.info(
                f"Card {uid}: DB mapping '{mapping['name']}' → "
                f"playing {mapping['item_type']}"
            )
            player.play(mapping["item_type"], mapping["item_id"])
            return

        logger.info(f"Card {uid}: no NDEF and no DB mapping")

    class _Observer(CardObserver):
        def update(self, observable, actions):
            added, removed = actions
            if removed:
                state["last_uid"] = None
            for card in added:
                _handle_card(card)

    observer = _Observer()
    monitor  = CardMonitor()
    monitor.addObserver(observer)
    logger.info("Waiting for NFC cards…")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("NFC daemon stopping…")
    finally:
        monitor.deleteObserver(observer)
