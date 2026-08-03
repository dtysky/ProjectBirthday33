import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const gameDir = path.resolve(toolDir, "..");
const projectDir = path.resolve(gameDir, "..");
const scenePath = path.join(projectDir, "design", "game-scenes.md");
const assetPath = path.join(projectDir, "art", "asset-list.md");
const contentDir = path.join(gameDir, "content");

const sceneSource = fs.readFileSync(scenePath, "utf8");
const assetSource = fs.readFileSync(assetPath, "utf8");

const voiceoverUnits = new Set([
  "G1-01",
  "G3-03",
  "G4-02",
  "G4-03",
  "G4-04",
  "G4-05",
  "G5-05",
]);
const sceneMonologueUnits = new Set([
  "G1-06",
  "G2-01",
  "G2-02",
  "G5-01",
  "G5-02",
  "G5-03",
  "G5-04",
]);
const narrationSpeakers = new Set(["我", "我／旅途记录", "少女 H"]);

function deliveryFor(unitId, speaker) {
  if (
    speaker === "屏幕文字" ||
    speaker === "屏幕消息" ||
    speaker === "旧作原文"
  ) {
    return "screen_text";
  }
  if (speaker.includes("旁白")) {
    return "voiceover";
  }
  if (voiceoverUnits.has(unitId) && narrationSpeakers.has(speaker)) {
    return "voiceover";
  }
  if (sceneMonologueUnits.has(unitId) && speaker === "我") {
    return "scene_monologue";
  }
  return "dialogue";
}

function presentationFor(delivery) {
  if (delivery === "screen_text") {
    return "center";
  }
  if (delivery === "voiceover") {
    return "caption";
  }
  return "bubble";
}

const mapping = new Map();
for (const match of assetSource.matchAll(
  /^\| (G[1-5]-\d{2}) \| ([^|]+) \| ([^|]+) \|$/gm,
)) {
  const refs = match[2]
    .split("、")
    .map((item) => item.trim())
    .filter(Boolean);
  mapping.set(match[1], {
    refs,
    shot: refs.find((item) => /^SHOT-\d{2}$/.test(item)) ?? "",
    production: match[3].trim(),
  });
}

const headers = [...sceneSource.matchAll(/^## (G[1-5]-\d{2})：(.+)$/gm)];
const units = headers.map((header, index) => {
  const start = header.index + header[0].length;
  const end = index + 1 < headers.length ? headers[index + 1].index : sceneSource.length;
  const section = sceneSource.slice(start, end);
  const lines = [...section.matchAll(/^> \*\*([^*]+)：\*\*\s*(.+)$/gm)].map(
    (line, lineIndex) => {
      const speaker = line[1].trim();
      const delivery = deliveryFor(header[1], speaker);
      return {
        id: `${header[1]}-${String(lineIndex + 1).padStart(2, "0")}`,
        speaker,
        text: line[2].trim(),
        delivery,
        presentation: presentationFor(delivery),
      };
    },
  );
  const assets = mapping.get(header[1]);

  if (!assets) {
    throw new Error(`Missing asset mapping for ${header[1]}`);
  }
  if (lines.length === 0) {
    throw new Error(`Scene ${header[1]} has no dialogue lines`);
  }

  return {
    id: header[1],
    chapter: Number(header[1][1]),
    title: header[2].trim(),
    shot: assets.shot,
    assets: assets.refs,
    production: assets.production,
    lines,
  };
});

const lineCount = units.reduce((total, unit) => total + unit.lines.length, 0);
if (units.length !== 28) {
  throw new Error(`Expected 28 units, got ${units.length}`);
}
if (lineCount === 0) {
  throw new Error("Story has no dialogue lines.");
}

const shotVariants = {
  "SHOT-01": {
    wake: "res://assets/shots/shot-01/g0-wake.webp",
    wash: "res://assets/shots/shot-01/g0-wash.webp",
    cats: "res://assets/shots/shot-01/g0-cats-goodbye.webp",
    board: "res://assets/shots/shot-01/g0-board-dawn.webp",
    drive: "res://assets/shots/shot-01/g0-driving.webp",
    arrive: "res://assets/shots/shot-01/g0-company-arrival.webp",
  },
  "SHOT-03": {
    point: "res://assets/shots/shot-03/point.webp",
    thumb: "res://assets/shots/shot-03/thumb.webp",
  },
  "SHOT-04": {
    closed: "res://assets/shots/shot-04/closed.webp",
    open: "res://assets/shots/shot-04/open.webp",
  },
  "SHOT-19": {
    base: "res://assets/shots/shot-19/base.webp",
    reflection: "res://assets/shots/shot-19/reflection.webp",
  },
};
const shotMasters = {
  "SHOT-01": "res://assets/shots/shot-01/g0-wake.webp",
  "SHOT-03": "res://assets/shots/shot-03/point.webp",
  "SHOT-04": "res://assets/shots/shot-04/closed.webp",
  "SHOT-19": "res://assets/shots/shot-19/base.webp",
};

const shots = {};
for (const match of assetSource.matchAll(
  /^\| (SHOT-\d{2}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$/gm,
)) {
  const id = match[1];
  const folder = id.toLowerCase();
  shots[id] = {
    units: match[2].trim(),
    composition: match[3].trim(),
    characters: match[4].trim(),
    deliverables: match[5].trim(),
    motion: match[6].trim(),
    master:
      shotMasters[id] ?? `res://assets/shots/${folder}/master.webp`,
    variants: shotVariants[id] ?? {},
  };
}

if (Object.keys(shots).length !== 19) {
  throw new Error(`Expected 19 shot packages, got ${Object.keys(shots).length}`);
}

fs.mkdirSync(contentDir, { recursive: true });
fs.writeFileSync(
  path.join(contentDir, "story.json"),
  `${JSON.stringify(
    {
      version: 2,
      title: "三十三",
      unit_count: units.length,
      line_count: lineCount,
      units,
    },
    null,
    2,
  )}\n`,
);
fs.writeFileSync(
  path.join(contentDir, "asset_manifest.json"),
  `${JSON.stringify({ version: 2, shots }, null, 2)}\n`,
);

console.log(`Generated ${units.length} units, ${lineCount} lines, ${Object.keys(shots).length} shots.`);
