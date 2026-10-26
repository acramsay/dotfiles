# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Render a week of weather as aligned low/high range bars.

Reads a JSON array on stdin, one object per day:
    [{"day": "Mon", "cond": "partly", "low": 41, "high": 62}, ...]

Condition keywords map to double-width emoji. The axis is shared across all
days, so the whole week must be passed in a single call.

Run with:  uv run week_chart.py
"""

import json
import sys

# Keyword -> emoji. U+FE0F forces emoji (double-width) presentation so every
# row's condition column is the same number of terminal cells.
GLYPHS = {
    "sunny": "\u2600\ufe0f",
    "partly": "\u26c5\ufe0f",
    "cloudy": "\u2601\ufe0f",
    "fog": "\U0001f32b\ufe0f",
    "rain": "\U0001f327\ufe0f",
    "showers": "\U0001f326\ufe0f",
    "snow": "\u2744\ufe0f",
    "storm": "\u26c8\ufe0f",
    "sleet": "\U0001f328\ufe0f",
}

EMOJI_CELLS = 2  # every glyph above is padded as two cells
DEGREES_PER_CELL = 2
MARK_EVERY = 5  # cells between axis labels (5 cells = 10 degrees)

# Column layout: day(4) glyph(2) gap(4) low(3)+degree gap(2)
BAR_COL = 4 + EMOJI_CELLS + 4 + 3 + 1 + 2


def round_down(value, step):
    return int(value // step * step)


def round_up(value, step):
    return int(-(-value // step) * step)


def cell(temp, axis_min):
    return int(round((temp - axis_min) / DEGREES_PER_CELL))


def bar_for(low, high, axis_min, width):
    start, end = cell(low, axis_min), cell(high, axis_min)
    cells = ["\u00b7"] * (width + 1)
    cells[start] = "\u25cf"
    cells[end] = "\u25cf"
    for i in range(start + 1, end):
        cells[i] = "\u2501"
    return "".join(cells)


def axis_for(axis_min, width):
    buf = [" "] * (width + 6)
    for i in range(0, width + 1, MARK_EVERY):
        label = f"{axis_min + i * DEGREES_PER_CELL}\u00b0"
        for offset, ch in enumerate(label):
            if i + offset < len(buf):
                buf[i + offset] = ch
    return " " * BAR_COL + "".join(buf).rstrip()


def render(rows):
    axis_min = round_down(min(r["low"] for r in rows), 5)
    axis_max = round_up(max(r["high"] for r in rows), 5)
    width = cell(axis_max, axis_min)

    lines = []
    for r in rows:
        glyph = GLYPHS[r["cond"]]
        gap = " " * (EMOJI_CELLS + 2)
        bar = bar_for(r["low"], r["high"], axis_min, width)
        lines.append(
            f"{r['day']:<4}{glyph}{gap}"
            f"{r['low']:>3}\u00b0  {bar}  {r['high']:>3}\u00b0"
        )
    lines.append(axis_for(axis_min, width))
    return "\n".join(lines)


def main():
    print(render(json.load(sys.stdin)))


if __name__ == "__main__":
    main()
