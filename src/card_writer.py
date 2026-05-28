#!/usr/bin/env python3
"""CLI to read NFC card UIDs, read NDEF text, and write NDEF Text records to NTAG213 cards.

Card format (compatible with gelly-nfc):
  album:<navidrome-album-id>
  track:<navidrome-track-id>
  playlist:<navidrome-playlist-id>
  artist:<navidrome-artist-id>
"""

import sys
import time
import logging
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

_GET_UID_APDU  = [0xFF, 0xCA, 0x00, 0x00, 0x00]
_READ_PAGE     = lambda page: [0xFF, 0xB0, 0x00, page, 0x04]
_WRITE_PAGE    = lambda page, data: [0xFF, 0xD6, 0x00, page, 0x04] + list(data)


# ---------------------------------------------------------------------------
# NDEF helpers
# ---------------------------------------------------------------------------

def _encode_text_record(text: str) -> bytes:
    """Encode text as a NDEF Text record using ndeflib."""
    import ndef
    return b"".join(ndef.message_encoder([ndef.TextRecord(text)]))


def _decode_text_record(ndef_bytes: bytes) -> Optional[str]:
    """Decode NDEF bytes and return the first Text record's text, or None."""
    try:
        import ndef
        for record in ndef.message_decoder(ndef_bytes):
            if isinstance(record, ndef.TextRecord):
                return record.text
    except Exception as e:
        logger.debug(f"NDEF decode error: {e}")
    return None


# ---------------------------------------------------------------------------
# Low-level NTAG213 (NFC Forum Type 2) read / write via PC/SC
# ---------------------------------------------------------------------------

def read_ntag213_ndef(connection) -> Optional[bytes]:
    """Read raw NDEF bytes from an NTAG213 card. Returns None if no valid NDEF."""
    # Read Capability Container at page 3
    data, sw1, sw2 = connection.transmit(_READ_PAGE(3))
    if sw1 != 0x90 or len(data) < 4 or data[0] != 0xE1:
        return None

    data_area_size = data[2] * 8  # e.g. 0x12 * 8 = 144 bytes for NTAG213

    # Read first 4 bytes of NDEF TLV at page 4
    data, sw1, sw2 = connection.transmit(_READ_PAGE(4))
    if sw1 != 0x90 or data[0] != 0x03:
        return None  # No NDEF TLV

    # Parse TLV length (1-byte or 3-byte form)
    if data[1] < 0xFF:
        ndef_len = data[1]
        ndef_data = bytes(data[2:])   # up to 2 bytes of NDEF already read
        next_page = 5
    else:
        ndef_len = (data[2] << 8) | data[3]
        ndef_data = b""
        next_page = 5

    if ndef_len == 0:
        return None

    # Read remaining pages until we have ndef_len bytes
    page = next_page
    while len(ndef_data) < ndef_len and page < 48:  # NTAG213 has pages 0-44
        chunk, sw1, sw2 = connection.transmit(_READ_PAGE(page))
        if sw1 != 0x90:
            break
        ndef_data += bytes(chunk)
        page += 1

    return bytes(ndef_data[:ndef_len])


def write_ntag213_ndef(connection, ndef_bytes: bytes) -> bool:
    """Write raw NDEF bytes to an NFC Forum Type 2 tag (NTAG213/215/216).
    Reads actual capacity from the Capability Container on the card.
    """
    ndef_len = len(ndef_bytes)

    # Read Capability Container to get actual card capacity
    cc, sw1, _ = connection.transmit(_READ_PAGE(3))
    if sw1 == 0x90 and cc[0] == 0xE1:
        max_user_bytes = cc[2] * 8  # e.g. 0x12*8=144 (213), 0x3E*8=496 (215)
    else:
        max_user_bytes = 144  # fallback: assume NTAG213

    # Build NDEF TLV
    if ndef_len < 0xFF:
        tlv = bytes([0x03, ndef_len]) + ndef_bytes + bytes([0xFE])
    else:
        tlv = bytes([0x03, 0xFF, ndef_len >> 8, ndef_len & 0xFF]) + ndef_bytes + bytes([0xFE])

    if len(tlv) > max_user_bytes:
        logger.error(f"NDEF too large: {len(tlv)} bytes (card max {max_user_bytes})")
        return False

    # Pad to multiple of 4 bytes
    remainder = len(tlv) % 4
    if remainder:
        tlv += bytes(4 - remainder)

    # Write Capability Container at page 3: NDEF 1.0, 144 bytes writable
    _, sw1, sw2 = connection.transmit(_WRITE_PAGE(3, [0xE1, 0x10, 0x12, 0x00]))
    if sw1 != 0x90:
        logger.error(f"CC write failed: SW={sw1:02X}{sw2:02X}")
        return False

    # Write NDEF TLV pages starting at page 4
    for i in range(0, len(tlv), 4):
        page = 4 + i // 4
        chunk = tlv[i:i + 4]
        _, sw1, sw2 = connection.transmit(_WRITE_PAGE(page, chunk))
        if sw1 != 0x90:
            logger.error(f"Page {page} write failed: SW={sw1:02X}{sw2:02X}")
            return False

    return True


# ---------------------------------------------------------------------------
# Higher-level helpers
# ---------------------------------------------------------------------------

def _get_uid(connection) -> Optional[str]:
    from smartcard.util import toHexString
    data, sw1, sw2 = connection.transmit(_GET_UID_APDU)
    if sw1 == 0x90:
        return toHexString(data).replace(" ", ":")
    return None


def _open_connection(reader_index: int):
    """Return an open pyscard connection or raise RuntimeError."""
    from smartcard.System import readers
    reader_list = readers()
    if not reader_list:
        raise RuntimeError("No NFC readers found. Is pcscd running?")
    if reader_index >= len(reader_list):
        raise RuntimeError(f"Reader index {reader_index} out of range ({len(reader_list)} available)")
    conn = reader_list[reader_index].createConnection()
    conn.connect()
    return conn


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list_readers():
    from smartcard.System import readers
    reader_list = readers()
    if not reader_list:
        print("No NFC readers found.")
    else:
        for i, r in enumerate(reader_list):
            print(f"[{i}] {r}")


def cmd_scan(reader_index: int, loop: bool):
    """Wait for a card and print its UID."""
    print("Tap a card to read its UID. Press Ctrl+C to stop.")
    last_uid = None
    while True:
        try:
            conn = _open_connection(reader_index)
            uid = _get_uid(conn)
            conn.disconnect()
            if uid and uid != last_uid:
                print(f"UID: {uid}")
                last_uid = uid
                if not loop:
                    break
            elif not uid:
                last_uid = None
        except Exception:
            last_uid = None
        time.sleep(0.2)


def cmd_read_ndef(reader_index: int):
    """Wait for a card and print its NDEF text content."""
    print("Tap a card to read its NDEF content. Press Ctrl+C to stop.")
    last_uid = None
    while True:
        try:
            conn = _open_connection(reader_index)
            uid = _get_uid(conn)
            if uid and uid != last_uid:
                last_uid = uid
                ndef_bytes = read_ntag213_ndef(conn)
                if ndef_bytes:
                    text = _decode_text_record(ndef_bytes)
                    if text:
                        print(f"UID:  {uid}")
                        print(f"NDEF: {text}")
                    else:
                        print(f"UID: {uid} – NDEF found but not a Text record")
                else:
                    print(f"UID: {uid} – no NDEF data on card")
            elif not uid:
                last_uid = None
            conn.disconnect()
        except Exception:
            last_uid = None
        time.sleep(0.2)


def cmd_write(reader_index: int, text: str):
    """Write a Text NDEF record to an NTAG213 card."""
    ndef_bytes = _encode_text_record(text)
    print(f"Tap an NTAG213 card to write: {text!r}  ({len(ndef_bytes)} NDEF bytes)")
    print("Press Ctrl+C to cancel.")
    while True:
        try:
            conn = _open_connection(reader_index)
            if write_ntag213_ndef(conn, ndef_bytes):
                uid = _get_uid(conn) or "unknown"
                print(f"Written to card UID: {uid}")
                conn.disconnect()
                break
            conn.disconnect()
            print("Write failed.", file=sys.stderr)
            sys.exit(1)
        except Exception:
            pass
        time.sleep(0.2)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="NFC card tool for Navidrome-NFC-Cards",
        epilog="Card text format: album:<id>  track:<id>  playlist:<id>  artist:<id>",
    )
    parser.add_argument("--reader", type=int, default=0, metavar="INDEX",
                        help="Reader index (default: 0, see list-readers)")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list-readers", help="List available NFC readers")

    scan = sub.add_parser("scan", help="Wait for a card and print its UID")
    scan.add_argument("--loop", action="store_true", help="Keep scanning continuously")

    sub.add_parser("read-ndef", help="Read and display NDEF text from a card")

    write = sub.add_parser("write", help="Write text as NDEF Text record to NTAG213")
    write.add_argument("text", help='Text to write, e.g. "album:abc123def456"')

    args = parser.parse_args()

    if args.command == "list-readers":
        cmd_list_readers()
    elif args.command == "scan":
        cmd_scan(args.reader, args.loop)
    elif args.command == "read-ndef":
        cmd_read_ndef(args.reader)
    elif args.command == "write":
        cmd_write(args.reader, args.text)


if __name__ == "__main__":
    main()
