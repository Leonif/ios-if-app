#!/usr/bin/env python3
"""Прочитати статус релізу з App Store Connect — тільки читання, нічого не змінює.

Версію бере з аргументу (`status.py 1.5.1`), інакше — найвища MARKETING_VERSION
з project.pbxproj (тобто версія, яку зараз збирають). Друкує стан версії людською
мовою плюс прикріплений білд і його processingState.
"""
from __future__ import annotations

import re
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from asc import ASC  # noqa: E402

PBXPROJ = Path(__file__).resolve().parent.parent / "IFApp.xcodeproj" / "project.pbxproj"

# App Store Connect appStoreState -> (людський стан, чи щось треба від власника)
STATES = {
    "PREPARE_FOR_SUBMISSION": "чернетка — ще не подано на ревʼю",
    "WAITING_FOR_REVIEW": "у черзі на ревʼю Apple",
    "IN_REVIEW": "на ревʼю в Apple зараз",
    "PENDING_DEVELOPER_RELEASE": "апрувнута ✅ — чекає, поки натиснеш Release",
    "PENDING_APPLE_RELEASE": "апрувнута ✅ — чекає авто-релізу від Apple у призначену дату",
    "PROCESSING_FOR_APP_STORE": "релізиться — Apple готує до продажу",
    "READY_FOR_SALE": "у релізі 🎉 — розкочується в App Store",
    "REPLACED_WITH_NEW_VERSION": "замінена новішою версією",
    "REJECTED": "відхилено Apple ⚠️ — дивись Resolution Center",
    "METADATA_REJECTED": "відхилено по метаданих ⚠️ — правки в описі/скрінах",
    "DEVELOPER_REJECTED": "знято тобою з ревʼю",
    "INVALID_BINARY": "битий білд ⚠️ — треба перезалити",
    "DEVELOPER_REMOVED_FROM_SALE": "знято з продажу",
}


def current_marketing_version() -> str | None:
    if not PBXPROJ.exists():
        return None
    vers = re.findall(r"MARKETING_VERSION = ([\d.]+);", PBXPROJ.read_text())
    if not vers:
        return None
    return max(vers, key=lambda v: [int(x) for x in v.split(".")])


def main() -> int:
    version = sys.argv[1] if len(sys.argv) > 1 else current_marketing_version()
    if not version:
        print("Не визначив версію: передай її аргументом, напр. status.py 1.5.1")
        return 2

    a = ASC()
    v = a.find_version(version)
    if not v:
        print(f"Версії {version} нема в App Store Connect (ще не створена).")
        return 1

    attr = v["attributes"]
    state = attr.get("appStoreState", "?")
    human = STATES.get(state, "невідомий стан")
    print(f"Версія {version}")
    print(f"Стан:  {state} — {human}")

    try:
        b = a.version_build(v["id"])
        if b:
            ba = b["attributes"]
            print(f"Білд:  #{ba.get('version')} · {ba.get('processingState')}")
        else:
            print("Білд:  не прикріплений")
    except Exception as e:  # noqa: BLE001
        print(f"Білд:  не дістав ({e})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
