#!/usr/bin/env python3
"""Extract the approved title badge into static and wind-moved layers."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


SOURCE_SIZE = (1672, 941)
RUNTIME_SIZE = (1920, 1080)
LANYARD_RUNTIME_CROP = (880, 900, 1175, 1030)


def scale_point(point: tuple[int, int]) -> tuple[int, int]:
    sx = RUNTIME_SIZE[0] / SOURCE_SIZE[0]
    sy = RUNTIME_SIZE[1] / SOURCE_SIZE[1]
    return round(point[0] * sx), round(point[1] * sy)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: compose_title_badge.py <approved-title-png> <output-dir>")
        return 2

    source_path = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)

    source = Image.open(source_path).convert("RGBA")
    if source.size != SOURCE_SIZE:
        raise ValueError(f"expected {SOURCE_SIZE}, got {source.size}")

    # The sleeve, reel and connector stay fixed against the wet rock.
    static_mask = Image.new("L", SOURCE_SIZE, 0)
    draw = ImageDraw.Draw(static_mask)
    draw.polygon([(796, 827), (808, 823), (858, 833), (849, 878), (794, 868)], fill=255)
    draw.ellipse((847, 810, 873, 837), fill=255)
    draw.polygon([(818, 828), (851, 820), (858, 833), (823, 843)], fill=255)
    static_mask = static_mask.filter(ImageFilter.MaxFilter(3)).filter(
        ImageFilter.GaussianBlur(0.55)
    )

    # Trace the approved loop itself. A color key also picked up blue-black wet
    # rock, so the narrow path is deliberately explicit and reproducible.
    lanyard_mask = Image.new("L", SOURCE_SIZE, 0)
    lanyard_draw = ImageDraw.Draw(lanyard_mask)
    lanyard_path = [
        (860, 828),
        (885, 817),
        (930, 819),
        (962, 826),
        (980, 835),
        (983, 844),
        (974, 853),
        (946, 859),
        (910, 858),
        (880, 850),
        (860, 839),
        (860, 828),
    ]
    lanyard_draw.line(lanyard_path, fill=255, width=11, joint="curve")
    for x, y in lanyard_path:
        lanyard_draw.ellipse((x - 5, y - 5, x + 5, y + 5), fill=255)
    lanyard_draw.ellipse((846, 809, 874, 839), fill=0)
    lanyard_mask = lanyard_mask.filter(ImageFilter.GaussianBlur(0.40))

    static_layer = source.copy()
    static_layer.putalpha(static_mask)
    lanyard_layer = source.copy()
    lanyard_layer.putalpha(lanyard_mask)

    static_runtime = static_layer.resize(RUNTIME_SIZE, Image.Resampling.LANCZOS)
    lanyard_runtime = lanyard_layer.resize(RUNTIME_SIZE, Image.Resampling.LANCZOS)
    lanyard_crop = lanyard_runtime.crop(LANYARD_RUNTIME_CROP)

    static_path = output_dir / "title-badge-static-v6.png"
    lanyard_path = output_dir / "title-badge-lanyard-v6.png"
    mask_path = output_dir / "title-badge-lanyard-mask-v6.png"
    static_runtime.save(static_path)
    lanyard_crop.save(lanyard_path)
    lanyard_mask.resize(RUNTIME_SIZE, Image.Resampling.LANCZOS).save(mask_path)

    metadata = {
        "source": str(source_path),
        "runtime_size": RUNTIME_SIZE,
        "lanyard_overlay": {
            "x": LANYARD_RUNTIME_CROP[0],
            "y": LANYARD_RUNTIME_CROP[1],
            "width": LANYARD_RUNTIME_CROP[2] - LANYARD_RUNTIME_CROP[0],
            "height": LANYARD_RUNTIME_CROP[3] - LANYARD_RUNTIME_CROP[1],
        },
        "wind_motion": {
            "rotation_radians": "0.006*sin(2*PI*t/8)+0.002*sin(2*PI*t/3)",
            "intent": "subordinate 1-2 px lift; sleeve remains fixed",
        },
    }
    (output_dir / "title-badge-layer-v6.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(metadata, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
