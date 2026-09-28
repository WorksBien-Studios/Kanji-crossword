# -*- coding: utf-8 -*-
"""Canonical schema helpers for shipped Kanji Nankuro puzzle content."""
from __future__ import annotations

import hashlib
import json

SCHEMA_VERSION = 2
ID_PREFIX = "nankuro-v2-"
GAMEPLAY_KEYS = (
    "schemaVersion",
    "mode",
    "rows",
    "columns",
    "cellLayout",
    "cellNumbers",
    "solution",
    "starterCells",
    "wordSpans",
)

ALLOWED_MODES = {"kanjiNankuro", "kanjiNankuroLarge"}
ALLOWED_DIFFICULTIES = {"easy", "standard", "hard", "expert"}


def canonical_json(value) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def gameplay_payload(record: dict) -> dict:
    return {key: record[key] for key in GAMEPLAY_KEYS}


def content_hash(record: dict) -> str:
    payload = canonical_json(gameplay_payload(record)).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def content_id(record: dict) -> str:
    return ID_PREFIX + content_hash(record)[:20]


def validation_digest(record: dict) -> str:
    payload = dict(record)
    payload.pop("validationDigest", None)
    return hashlib.sha256(canonical_json(payload).encode("utf-8")).hexdigest()


def mode_for_word_count(word_count: int) -> str:
    return "kanjiNankuro" if word_count < 24 else "kanjiNankuroLarge"


def assign_difficulty_bands(records: list[dict]) -> None:
    """Assign four deterministic percentile bands from solver-derived scores."""
    ordered = sorted(records, key=lambda rec: (rec["difficultyScore"], rec["id"]))
    total = len(ordered)
    for rank, rec in enumerate(ordered):
        percentile = (rank + 0.5) / max(1, total)
        if percentile <= 0.25:
            band = "easy"
        elif percentile <= 0.50:
            band = "standard"
        elif percentile <= 0.75:
            band = "hard"
        else:
            band = "expert"
        rec["difficulty"] = band
