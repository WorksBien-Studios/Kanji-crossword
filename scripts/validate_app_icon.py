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


def paeth_predictor(left: int, above: int, upper_left: int) -> int:
    prediction = left + above - upper_left
    left_distance = abs(prediction - left)
    above_distance = abs(prediction - above)
    upper_left_distance = abs(prediction - upper_left)
    if left_distance <= above_distance and left_distance <= upper_left_distance:
        return left
    if above_distance <= upper_left_distance:
        return above
    return upper_left


def reconstruct_rows(
    path: Path, raster: bytes, width: int, height: int, bytes_per_pixel: int
) -> list[bytearray]:
    pixel_bytes = width * bytes_per_pixel
    row_size = 1 + pixel_bytes
    rows: list[bytearray] = []

    for row_index in range(height):
        start = row_index * row_size
        filter_type = raster[start]
        if filter_type not in range(5):
            raise ValidationError(
                f"{path}: invalid PNG filter on row {row_index}"
            )

        encoded = raster[start + 1 : start + row_size]
        previous = rows[-1] if rows else bytearray(pixel_bytes)
        decoded = bytearray(pixel_bytes)
        for index, value in enumerate(encoded):
            left = decoded[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            above = previous[index]
            upper_left = (
                previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            )
            if filter_type == 0:
                predictor = 0
            elif filter_type == 1:
                predictor = left
            elif filter_type == 2:
                predictor = above
            elif filter_type == 3:
                predictor = (left + above) // 2
            else:
                predictor = paeth_predictor(left, above, upper_left)
            decoded[index] = (value + predictor) & 0xFF
        rows.append(decoded)

    return rows


def validate_png(
    path: Path,
    expected_width: int,
    expected_height: int,
    *,
    allow_opaque_alpha: bool = False,
    require_kanji_palette: bool = False,
) -> bytes:
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
    allowed_color_types = {2, 6} if allow_opaque_alpha else {2}
    if bit_depth != 8 or color_type not in allowed_color_types:
        raise ValidationError(
            f"{path}: expected opaque 8-bit "
            f"{'RGB or RGBA' if allow_opaque_alpha else 'RGB'}, got bit depth "
            f"{bit_depth}, color type {color_type}"
        )
    if (compression, filtering, interlace) != (0, 0, 0):
        raise ValidationError(f"{path}: unsupported PNG encoding")

    try:
        raster = zlib.decompress(bytes(idat))
    except zlib.error as error:
        raise ValidationError(f"{path}: corrupt IDAT stream: {error}") from error

    bytes_per_pixel = 3 if color_type == 2 else 4
    row_size = 1 + width * bytes_per_pixel
    expected_size = height * row_size
    if len(raster) != expected_size:
        raise ValidationError(
            f"{path}: decoded raster is {len(raster)} bytes; expected {expected_size}"
        )

    rows = reconstruct_rows(path, raster, width, height, bytes_per_pixel)
    if color_type == 6 and any(
        alpha != 255 for row in rows for alpha in row[3::4]
    ):
        raise ValidationError(f"{path}: compiled icon contains non-opaque pixels")

    if require_kanji_palette:
        pixels = (
            tuple(row[index : index + 3])
            for row in rows
            for index in range(0, len(row), bytes_per_pixel)
        )
        counts = {"dark": 0, "ivory": 0, "vermilion": 0}
        total = width * height
        for red, green, blue in pixels:
            counts["dark"] += max(red, green, blue) < 65
            counts["ivory"] += (
                min(red, green, blue) > 180
                and max(red, green, blue) - min(red, green, blue) < 70
            )
            counts["vermilion"] += (
                red > 140 and red > green * 1.45 and red > blue * 1.35
            )

        shares = {name: count / total for name, count in counts.items()}
        minimums = {"dark": 0.20, "ivory": 0.15, "vermilion": 0.08}
        missing = [
            name for name, minimum in minimums.items() if shares[name] < minimum
        ]
        if missing:
            details = ", ".join(
                f"{name}={shares[name]:.1%}" for name in counts
            )
            raise ValidationError(
                f"{path}: processed icon does not match the Kanji Crossword "
                f"palette ({details}); missing {', '.join(missing)}"
            )
        print(
            "Kanji palette present: "
            + ", ".join(f"{name}={shares[name]:.1%}" for name in counts)
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
    parser.add_argument(
        "--allow-opaque-alpha",
        action="store_true",
        help="Permit RGBA only when every alpha value is 255",
    )
    parser.add_argument(
        "--require-kanji-palette",
        action="store_true",
        help="Require the dark, ivory, and vermilion signature of the app icon",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    try:
        if args.png:
            if args.width is None or args.height is None:
                raise ValidationError("--png requires --width and --height")
            data = validate_png(
                args.png,
                args.width,
                args.height,
                allow_opaque_alpha=args.allow_opaque_alpha,
                require_kanji_palette=args.require_kanji_palette,
            )
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
