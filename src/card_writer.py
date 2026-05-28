#!/usr/bin/env python3
"""CLI to read NFC card UIDs and write NDEF URI records to NTAG213 cards."""

import sys
import time
import logging
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

_GET_UID_APDU = [0xFF, 0xCA, 0x00, 0x00, 0x00]


def _build_ndef_uri_tlv(uri: str) -> bytes:
    uri_bytes = uri.encode("utf-8")
    # NDEF record: TNF=0x01 Well-Known, MB=ME=SR=1, type='U', prefix=0x00 (no prefix)
    record = bytes([0xD1, 0x01, len(uri_bytes) + 1, 0x55, 0x00]) + uri_bytes
    length = len(record)
    # TLV wrapper
    if length < 0xFF:
        tlv = bytes([0x03, length]) + record + bytes([0xFE])
    else:
        tlv = bytes([0x03, 0xFF, length >> 8, length & 0xFF]) + record + bytes([0xFE])
    # Pad to multiple of 4 bytes
    remainder = len(tlv) % 4
    if remainder:
        tlv += bytes(4 - remainder)
    return tlv


def write_ntag213_uri(connection, uri: str) -> bool:
    """Write a URI NDEF record to an NTAG213 card via PC/SC APDU commands."""
    tlv = _build_ndef_uri_tlv(uri)
    if len(tlv) > 168:  # NTAG213 user memory: 42 pages × 4 bytes = 168 bytes
        logger.error(f"URI too long: {len(tlv)} bytes (max 168)")
        return False

    # Write Capability Container at page 3: NDEF 1.0, 72-byte writable memory
    cc_apdu = [0xFF, 0xD6, 0x00, 0x03, 0x04, 0xE1, 0x10, 0x12, 0x00]
    _, sw1, sw2 = connection.transmit(cc_apdu)
    if sw1 != 0x90:
        logger.error(f"CC write failed: SW={sw1:02X}{sw2:02X}")
        return False

    # Write NDEF data pages starting at page 4
    for i in range(0, len(tlv), 4):
        page = 4 + i // 4
        chunk = list(tlv[i:i + 4])
        if len(chunk) < 4:
            chunk += [0x00] * (4 - len(chunk))
        _, sw1, sw2 = connection.transmit([0xFF, 0xD6, 0x00, page, 0x04] + chunk)
        if sw1 != 0x90:
            logger.error(f"Page {page} write failed: SW={sw1:02X}{sw2:02X}")
            return False

    return True


def _get_uid(connection) -> Optional[str]:
    from smartcard.util import toHexString
    data, sw1, sw2 = connection.transmit(_GET_UID_APDU)
    if sw1 == 0x90:
        return toHexString(data).replace(" ", ":")
    return None


def cmd_list_readers():
    from smartcard.System import readers
    reader_list = readers()
    if not reader_list:
        print("No NFC readers found.")
    else:
        for i, r in enumerate(reader_list):
            print(f"[{i}] {r}")


def cmd_scan(reader_index: int, loop: bool):
    from smartcard.System import readers as get_readers

    print("Tap a card to read its UID. Press Ctrl+C to stop.")
    last_uid = None

    while True:
        try:
            reader_list = get_readers()
            if not reader_list or reader_index >= len(reader_list):
                print("Reader not found.", file=sys.stderr)
                sys.exit(1)
            conn = reader_list[reader_index].createConnection()
            conn.connect()
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


def cmd_write(reader_index: int, uri: str):
    from smartcard.System import readers as get_readers

    print(f"Tap an NTAG213 card to write: {uri}")
    print("Press Ctrl+C to cancel.")

    while True:
        try:
            reader_list = get_readers()
            if not reader_list or reader_index >= len(reader_list):
                print("Reader not found.", file=sys.stderr)
                sys.exit(1)
            conn = reader_list[reader_index].createConnection()
            conn.connect()
            if write_ntag213_uri(conn, uri):
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


def main():
    import argparse

    parser = argparse.ArgumentParser(description="NFC card tool for Navidrome-NFC-Cards")
    parser.add_argument("--reader", type=int, default=0, metavar="INDEX")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("list-readers", help="List available NFC readers")

    scan = sub.add_parser("scan", help="Wait for a card and print its UID")
    scan.add_argument("--loop", action="store_true", help="Keep scanning continuously")

    write = sub.add_parser("write", help="Write a URI to an NTAG213 card")
    write.add_argument("uri", help="URI to write, e.g. navidrome://album/abc123")

    args = parser.parse_args()

    if args.command == "list-readers":
        cmd_list_readers()
    elif args.command == "scan":
        cmd_scan(args.reader, args.loop)
    elif args.command == "write":
        cmd_write(args.reader, args.uri)


if __name__ == "__main__":
    main()
