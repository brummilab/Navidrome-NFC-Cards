import time
import logging
from typing import Optional

logger = logging.getLogger(__name__)

_GET_UID_APDU = [0xFF, 0xCA, 0x00, 0x00, 0x00]


def get_card_uid(reader_index: int = 0) -> Optional[str]:
    """Return colon-separated UID hex string of currently present card, or None."""
    try:
        from smartcard.System import readers
        from smartcard.util import toHexString

        reader_list = readers()
        if not reader_list or reader_index >= len(reader_list):
            return None

        connection = reader_list[reader_index].createConnection()
        connection.connect()
        data, sw1, sw2 = connection.transmit(_GET_UID_APDU)
        connection.disconnect()

        if sw1 == 0x90 and sw2 == 0x00:
            return toHexString(data).replace(" ", ":")
        return None
    except Exception:
        return None


def run_daemon(config: dict, mappings, player) -> None:
    nfc_cfg = config.get("nfc", {})
    reader_index = nfc_cfg.get("reader_index", 0)
    poll_interval = nfc_cfg.get("poll_interval", 0.2)
    debounce_seconds = nfc_cfg.get("debounce_seconds", 5)

    logger.info(f"NFC daemon started (reader index {reader_index})")

    last_uid: Optional[str] = None
    last_time: float = 0

    while True:
        uid = get_card_uid(reader_index)
        now = time.time()

        if uid is not None:
            if uid != last_uid or (now - last_time) > debounce_seconds:
                last_uid = uid
                last_time = now
                mapping = mappings.get_mapping(uid)
                if mapping:
                    logger.info(f"Card {uid}: playing {mapping['item_type']} '{mapping['name']}'")
                    player.play(mapping["item_type"], mapping["item_id"])
                else:
                    logger.info(f"Card {uid}: no mapping found")
        else:
            last_uid = None

        time.sleep(poll_interval)
