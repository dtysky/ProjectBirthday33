#!/usr/bin/env python3
"""Create an original, editable solo-piano draft for Birthday 33 G0."""

from __future__ import annotations

import random
import struct
import sys
from pathlib import Path


TPB = 480
BEATS_PER_BAR = 4
TEMPO_BPM = 82
TOTAL_BARS = 36


def variable_length(value: int) -> bytes:
    data = [value & 0x7F]
    value >>= 7
    while value:
        data.append((value & 0x7F) | 0x80)
        value >>= 7
    return bytes(reversed(data))


def midi_note(name: str) -> int:
    pitch_classes = {
        "C": 0,
        "C#": 1,
        "Db": 1,
        "D": 2,
        "D#": 3,
        "Eb": 3,
        "E": 4,
        "F": 5,
        "F#": 6,
        "Gb": 6,
        "G": 7,
        "G#": 8,
        "Ab": 8,
        "A": 9,
        "A#": 10,
        "Bb": 10,
        "B": 11,
    }
    pitch = name[:-1]
    octave = int(name[-1])
    return 12 * (octave + 1) + pitch_classes[pitch]


class Track:
    def __init__(self) -> None:
        self.events: list[tuple[int, int, bytes]] = []

    def add(self, tick: int, priority: int, payload: bytes) -> None:
        self.events.append((max(0, tick), priority, payload))

    def meta(self, tick: int, meta_type: int, payload: bytes, priority: int = 0) -> None:
        self.add(tick, priority, bytes([0xFF, meta_type]) + variable_length(len(payload)) + payload)

    def compile(self, end_tick: int) -> bytes:
        self.meta(end_tick, 0x2F, b"", priority=99)
        out = bytearray()
        previous = 0
        for tick, _, payload in sorted(self.events, key=lambda item: (item[0], item[1])):
            out.extend(variable_length(tick - previous))
            out.extend(payload)
            previous = tick
        return b"MTrk" + struct.pack(">I", len(out)) + bytes(out)


def beat_tick(bar: int, beat: float) -> int:
    return round(((bar - 1) * BEATS_PER_BAR + beat) * TPB)


def add_note(
    track: Track,
    bar: int,
    beat: float,
    duration: float,
    note: str | int,
    velocity: int,
    rng: random.Random,
    humanize: bool = True,
) -> None:
    number = midi_note(note) if isinstance(note, str) else note
    jitter = rng.randint(-5, 5) if humanize else 0
    start = max(0, beat_tick(bar, beat) + jitter)
    end = max(start + 24, beat_tick(bar, beat + duration) + jitter - rng.randint(4, 12))
    shaped_velocity = max(1, min(100, velocity + (rng.randint(-3, 3) if humanize else 0)))
    track.add(start, 20, bytes([0x90, number, shaped_velocity]))
    track.add(end, 10, bytes([0x80, number, 0]))


CHORDS: dict[str, tuple[int, tuple[int, ...], int]] = {
    "C": (36, (52, 55), 43),
    "C/E": (40, (48, 55), 43),
    "F": (41, (48, 57), 48),
    "Fm": (41, (48, 56), 48),
    "G": (43, (50, 59), 50),
    "G7": (43, (50, 53, 59), 50),
    "Gsus": (43, (50, 55, 60), 50),
    "Am": (45, (52, 57), 52),
    "Dm": (38, (50, 57), 45),
}


HARMONY = [
    "C", "C", "F", "G", "C", "F", "G", "C",
    "C/E", "F", "C", "G", "Am", "F", "G", "C",
    "F", "C/E", "Dm", "G", "C", "Fm", "C", "C",
    "C", "F", "C/E", "G", "Am", "F", "G", "G",
    "C", "F", "G7", "C",
]


MELODY: dict[int, list[tuple[float, float, str]]] = {
    1: [(0.5, 0.5, "E4"), (1, 1, "G4"), (2, 0.5, "A4"), (2.5, 0.5, "G4"), (3, 1, "E4")],
    2: [(0, 1, "D4"), (1, 1, "E4"), (2, 1.5, "G4")],
    3: [(0, 1, "A4"), (1, 0.5, "G4"), (1.5, 0.5, "F4"), (2, 1, "A4"), (3, 1, "C5")],
    4: [(0, 1.5, "B4"), (1.5, 0.5, "A4"), (2, 1.5, "G4"), (3.5, 0.5, "D4")],
    5: [(0.5, 0.5, "E4"), (1, 1, "G4"), (2, 1, "A4"), (3, 1, "C5")],
    6: [(0, 1.5, "A4"), (1.5, 0.5, "G4"), (2, 1, "F4"), (3, 1, "E4")],
    7: [(0, 1, "D4"), (1, 1, "G4"), (2, 0.5, "A4"), (2.5, 0.5, "B4"), (3, 1, "D5")],
    8: [(0, 2, "C5"), (2, 1, "G4"), (3, 0.75, "E4")],
    9: [(0.5, 0.5, "G4"), (1, 1, "A4"), (2, 1, "C5"), (3, 1, "B4")],
    10: [(0, 1, "A4"), (1, 1, "G4"), (2, 2, "F4")],
    11: [(0, 1, "E4"), (1, 0.5, "G4"), (1.5, 0.5, "A4"), (2, 1, "G4"), (3, 1, "E4")],
    12: [(0, 1.5, "D4"), (1.5, 0.5, "G4"), (2, 1, "B4"), (3, 1, "A4")],
    13: [(0, 1, "E4"), (1, 1, "A4"), (2, 1, "C5"), (3, 1, "B4")],
    14: [(0, 1.5, "A4"), (1.5, 0.5, "G4"), (2, 1, "F4"), (3, 1, "A4")],
    15: [(0, 1, "G4"), (1, 0.5, "A4"), (1.5, 0.5, "B4"), (2, 1, "D5"), (3, 1, "B4")],
    16: [(0, 2.5, "C5"), (2.5, 0.5, "G4"), (3, 0.75, "E4")],
    17: [(0, 1, "A4"), (1, 1, "C5"), (2, 1.5, "D5"), (3.5, 0.5, "C5")],
    18: [(0, 1, "G4"), (1, 1, "A4"), (2, 1, "C5"), (3, 1, "G4")],
    19: [(0, 1, "F4"), (1, 1, "A4"), (2, 1, "D5"), (3, 1, "C5")],
    20: [(0, 1.5, "B4"), (1.5, 0.5, "A4"), (2, 2, "G4")],
    21: [(0, 1, "E4"), (1, 1, "G4"), (2, 1.5, "C5"), (3.5, 0.5, "B4")],
    22: [(0, 1.5, "Ab4"), (1.5, 0.5, "G4"), (2, 1, "F4"), (3, 1, "C5")],
    23: [(0, 1, "G4"), (1, 1, "E4"), (2, 1, "D4"), (3, 1, "G4")],
    24: [(0, 1, "E4"), (1, 1, "D4"), (2, 2, "C4")],
    25: [(0.5, 0.5, "E4"), (1, 1, "G4"), (2, 0.5, "A4"), (2.5, 0.5, "G4"), (3, 1, "C5")],
    26: [(0, 1, "A4"), (1, 1, "G4"), (2, 1, "F4"), (3, 1, "A4")],
    27: [(0, 1, "G4"), (1, 1, "E4"), (2, 1, "D4"), (3, 1, "E4")],
    28: [(0, 1, "G4"), (1, 1, "B4"), (2, 1, "A4"), (3, 1, "G4")],
    29: [(0, 1, "A4"), (1, 1, "C5"), (2, 1, "E5"), (3, 1, "C5")],
    30: [(0, 1.5, "A4"), (1.5, 0.5, "G4"), (2, 1, "F4"), (3, 1, "E4")],
    31: [(0, 1, "D4"), (1, 1, "G4"), (2, 1, "A4"), (3, 1, "B4")],
    32: [(0, 2, "G4"), (2, 1, "D4")],
    33: [(0, 1, "E4"), (1, 1, "G4"), (2, 2, "C5")],
    34: [(0, 1, "A4"), (1, 1, "G4"), (2, 2, "F4")],
    35: [(0, 1, "D4"), (1, 1, "G4"), (2, 1, "B4"), (3, 1, "D5")],
    36: [(0, 3.6, "C5")],
}


def expression_for_bar(bar: int) -> int:
    anchors = {
        1: 78,
        5: 84,
        9: 76,
        13: 82,
        17: 87,
        21: 77,
        25: 82,
        29: 88,
        33: 70,
        36: 58,
    }
    previous_bar = max(candidate for candidate in anchors if candidate <= bar)
    next_bars = [candidate for candidate in anchors if candidate > bar]
    if not next_bars:
        return anchors[previous_bar]
    next_bar = min(next_bars)
    ratio = (bar - previous_bar) / (next_bar - previous_bar)
    return round(anchors[previous_bar] + (anchors[next_bar] - anchors[previous_bar]) * ratio)


def create_midi(output_path: Path) -> None:
    rng = random.Random(330082)
    meta = Track()
    piano = Track()

    meta.meta(0, 0x03, b"Birthday 33 - G0 local piano draft")
    microseconds = round(60_000_000 / TEMPO_BPM)
    meta.meta(0, 0x51, microseconds.to_bytes(3, "big"))
    meta.meta(0, 0x58, bytes([4, 2, 24, 8]))
    meta.meta(0, 0x59, bytes([0, 0]))

    piano.meta(0, 0x03, b"Solo Grand Piano")
    piano.add(0, 0, bytes([0xC0, 0]))
    piano.add(0, 1, bytes([0xB0, 7, 104]))
    piano.add(0, 1, bytes([0xB0, 10, 64]))
    piano.add(0, 1, bytes([0xB0, 91, 22]))

    for bar, chord_name in enumerate(HARMONY, start=1):
        expression = expression_for_bar(bar)
        piano.add(beat_tick(bar, 0), 1, bytes([0xB0, 11, expression]))

        bass, upper, middle_bass = CHORDS[chord_name]
        accompaniment_velocity = 39 + round((expression - 70) * 0.28)
        melody_velocity = 55 + round((expression - 70) * 0.34)

        piano.add(beat_tick(bar, 0), 2, bytes([0xB0, 64, 84]))
        piano.add(beat_tick(bar, 3.88), 2, bytes([0xB0, 64, 0]))

        if bar == TOTAL_BARS:
            add_note(piano, bar, 0, 3.75, bass, accompaniment_velocity - 4, rng)
            for note in upper:
                add_note(piano, bar, 0.04, 3.65, note, accompaniment_velocity, rng)
        else:
            add_note(piano, bar, 0, 1.72, bass, accompaniment_velocity - 3, rng)
            for note in upper:
                add_note(piano, bar, 1, 0.88, note, accompaniment_velocity, rng)
            add_note(piano, bar, 2, 1.68, middle_bass, accompaniment_velocity - 5, rng)
            for note in upper:
                add_note(piano, bar, 3, 0.84, note, accompaniment_velocity - 1, rng)

        for beat, duration, note in MELODY[bar]:
            add_note(piano, bar, beat, duration, note, melody_velocity, rng)

    end_tick = beat_tick(TOTAL_BARS + 1, 0)
    header = b"MThd" + struct.pack(">IHHH", 6, 1, 2, TPB)
    payload = header + meta.compile(end_tick) + piano.compile(end_tick)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(payload)
    print(f"wrote {output_path} ({len(payload)} bytes, {TOTAL_BARS} bars at {TEMPO_BPM} BPM)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit(f"usage: {Path(sys.argv[0]).name} OUTPUT.mid")
    create_midi(Path(sys.argv[1]).expanduser().resolve())
