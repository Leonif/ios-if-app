"""Read What's New and Promotional Text out of a marketing store pack.

The pack is a wiki page written for people, not a data file, so this parser is
deliberately strict: it takes only the two shapes marketing actually uses and
refuses anything it does not recognise rather than guessing. A store pack that
half-parses would push nine locales and leave the tenth showing the previous
release's text, which nobody would notice until the listing was live.

  Promotional text: a markdown table, one row per locale, text in backticks.
  What's New:       `### <locale> - N симв.` followed by a fenced block.
"""

from __future__ import annotations

import re
from pathlib import Path

LIMIT_WHATS_NEW = 4000
LIMIT_PROMO = 170

_HEADING = re.compile(r"^###\s+([A-Za-z-]+(?:-[A-Za-z]+)?)\s*[-–—]\s*\d+", re.M)


def _section(text: str, title_re: str) -> str:
    """The slice of the document under one `## ...` heading."""
    m = re.search(rf"^##\s+{title_re}.*?$", text, re.M)
    if not m:
        raise ValueError(f"store pack has no section matching {title_re!r}")
    rest = text[m.end():]
    nxt = re.search(r"^##\s+", rest, re.M)
    return rest[:nxt.start()] if nxt else rest


def parse_promotional(text: str) -> dict[str, str]:
    body = _section(text, r"Promotional Text")
    out = {}
    for line in body.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < 2:
            continue
        locale, value = cells[0], cells[1]
        if not (value.startswith("`") and value.endswith("`")):
            continue          # header row, separator row, anything unquoted
        out[locale] = value[1:-1].strip()
    if not out:
        raise ValueError("Promotional Text section parsed to zero locales")
    return out


def parse_whats_new(text: str) -> dict[str, str]:
    body = _section(text, r"What.s New")
    out = {}
    for m in _HEADING.finditer(body):
        locale = m.group(1)
        rest = body[m.end():]
        fence = re.search(r"^```\s*$(.*?)^```\s*$", rest, re.M | re.S)
        if not fence:
            raise ValueError(f"locale {locale}: heading found but no fenced block")
        nxt = _HEADING.search(rest)
        if nxt and nxt.start() < fence.start():
            raise ValueError(f"locale {locale}: next locale starts before its text block")
        out[locale] = fence.group(1).strip()
    if not out:
        raise ValueError("What's New section parsed to zero locales")
    return out


def load(path: str | Path) -> dict[str, dict[str, str]]:
    """-> {pack_locale: {"whatsNew": ..., "promotionalText": ...}}

    Length is checked here rather than at push time. App Store Connect rejects an
    over-long field with a 409 in the middle of the loop, which leaves some
    locales written and some not; failing before the first write keeps the draft
    in one state or the other, never in between.
    """
    text = Path(path).read_text(encoding="utf-8")
    whats_new = parse_whats_new(text)
    promo = parse_promotional(text)

    problems = []
    for loc, v in whats_new.items():
        if len(v) > LIMIT_WHATS_NEW:
            problems.append(f"{loc}: What's New is {len(v)} chars, limit {LIMIT_WHATS_NEW}")
    for loc, v in promo.items():
        if len(v) > LIMIT_PROMO:
            problems.append(f"{loc}: promotional text is {len(v)} chars, limit {LIMIT_PROMO}")
    missing = set(whats_new) ^ set(promo)
    if missing:
        problems.append("locales present in one section but not the other: "
                        + ", ".join(sorted(missing)))
    if problems:
        raise ValueError("store pack rejected:\n  " + "\n  ".join(problems))

    return {loc: {"whatsNew": whats_new[loc], "promotionalText": promo[loc]}
            for loc in whats_new}


if __name__ == "__main__":
    import sys
    for loc, v in load(sys.argv[1]).items():
        print(f"{loc:<10} whatsNew={len(v['whatsNew']):>5}  promo={len(v['promotionalText']):>4}")
