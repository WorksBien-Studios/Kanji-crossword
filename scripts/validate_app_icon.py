#!/usr/bin/env python3
"""Fail closed when the Kanji Crossword app icon is corrupt or inconsistent."""

from __future__ import annotations

import argparse
import hashlib
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
ROOT = Path(__file__).resolve().parents[1]
CANONICAL_ICON = ROOT / "assets/app-icon/AppIcon-1024.png"
CATALOG_ICON = (
    ROOT
    / "app/KanjiCrossword/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
)


class ValidationError(ValueError):
    pass


def validate_png(path: Path, expected_width: int, expected_height: int) -> bytes:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValidationError(f"{path}: invalid PNG signature")

    offset = len(PNG_SIGNATURE)
    chunks: list[bytes] = []
    idat = bytearray()
    ihdr: bytes | None = None
    saw_iend = False

    while offset < len(data):
        if offset + 12 > len(data):
            raise ValidationError(f"{path}: truncated PNG chunk header")

        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_end = offset + 12 + length
        if chunk_end > len(data):
            name = chunk_type.decode("ascii", errors="replace")
            raise ValidationError(f"{path}: truncated {name} chunk")

        payload = data[offset + 8 : offset + 8 + length]
        stored_crc = struct.unpack(">I", data[offset + 8 + length : chunk_end])[0]
        calculated_crc = zlib.crc32(chunk_type + payload) & 0xFFFFFFFF
        if stored_crc != calculated_crc:
            name = chunk_type.decode("ascii", errors="replace")
            raise ValidationError(f"{path}: invalid {name} checksum")

        chunks.append(chunk_type)
        if chunk_type == b"IHDR":
            if ihdr is not None or len(payload) != 13:
                raise ValidationError(f"{path}: invalid IHDR chunk")
            ihdr = payload
        elif chunk_type == b"IDAT":
            idat.extend(payload)
        elif chunk_type == b"IEND":
            if length != 0:
                raise ValidationError(f"{path}: invalid IEND chunk")
            saw_iend = True
            offset = chunk_end
            break

        offset = chunk_end

    if chunks[:1] != [b"IHDR"] or ihdr is None:
        raise ValidationError(f"{path}: IHDR must be the first chunk")
    if not idat:
        raise ValidationError(f"{path}: missing IDAT data")
    if not saw_iend:
        raise ValidationError(f"{path}: missing IEND chunk")
    if offset != len(data):
        raise ValidationError(f"{path}: unexpected data after IEND")
    if b"tRNS" in chunks:
        raise ValidationError(f"{path}: transparency is not allowed")

    width, height, bit_depth, color_type, compression, filtering, interlace = (
        struct.unpack(">IIBBBBB", ihdr)
    )
    if (width, height) != (expected_width, expected_height):
        raise ValidationError(
            f"{path}: expected {expected_width}x{expected_height}, got {width}x{height}"
        )
    if (bit_depth, color_type) != (8, 2):
        raise ValidationError(
            f"{path}: expected opaque 8-bit RGB, got bit depth {bit_depth}, "
            f"color type {color_type}"
        )
    if (compression, filtering, interlace) != (0, 0, 0):
        raise ValidationError(f"{path}: unsupported PNG encoding")

    try:
        raster = zlib.decompress(bytes(idat))
    except zlib.error as error:
        raise ValidationError(f"{path}: corrupt IDAT stream: {error}") from error

    row_size = 1 + width * 3
    expected_size = height * row_size
    if len(raster) != expected_size:
        raise ValidationError(
            f"{path}: decoded raster is {len(raster)} bytes; expected {expected_size}"
        )

    invalid_filters = [
        row for row in range(height) if raster[row * row_size] not in range(5)
    ]
    if invalid_filters:
        raise ValidationError(
            f"{path}: invalid PNG filter on row {invalid_filters[0]}"
        )

    return data


def validate_sources() -> None:
    canonical = validate_png(CANONICAL_ICON, 1024, 1024)
    catalog = validate_png(CATALOG_ICON, 1024, 1024)
    if canonical != catalog:
        raise ValidationError(
            "The canonical icon and Xcode asset-catalog icon are not byte-identical"
        )

    digest = hashlib.sha256(canonical).hexdigest()
    print(f"Validated both 1024x1024 opaque RGB app icons; SHA-256 {digest}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--png", type=Path, help="Validate one decoded PNG")
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.png:
            if args.width is None or args.height is None:
                raise ValidationError("--png requires --width and --height")
            data = validate_png(args.png, args.width, args.height)
            digest = hashlib.sha256(data).hexdigest()
            print(
                f"Validated {args.png}: {args.width}x{args.height} opaque RGB; "
                f"SHA-256 {digest}"
            )
        elif args.width is not None or args.height is not None:
            raise ValidationError("--width and --height require --png")
        else:
            validate_sources()
    except (OSError, ValidationError) as error:
        print(f"App icon validation failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
