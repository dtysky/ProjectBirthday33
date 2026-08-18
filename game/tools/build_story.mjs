import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const gameDir = path.resolve(toolDir, "..");
const projectDir = path.resolve(gameDir, "..");
const scenePath = path.join(projectDir, "design", "game-scenes.md");
const dialoguePacingPath = path.join(
  projectDir,
  "design",
  "dialogue-line-break-review-20260813.md",
);
const assetPath = path.join(projectDir, "art", "asset-list.md");
const contentDir = path.join(gameDir, "content");

const sceneSource = fs.readFileSync(scenePath, "utf8");
const dialoguePacingSource = fs.readFileSync(dialoguePacingPath, "utf8");
const assetSource = fs.readFileSync(assetPath, "utf8");

const voiceoverUnits = new Set([
  "G1-01",
  "G1-06",
  "G3-03",
  "G4-01",
  "G4-02",
  "G4-03",
  "G4-04",
  "G4-05",
  "G5-01",
  "G5-02",
  "G5-03",
  "G5-04",
  "G5-05",
]);
const sceneMonologueUnits = new Set([
  "G2-01",
  "G2-02",
]);
const narrationSpeakers = new Set([
  "我",
  "我／旅途记录",
  "少女 H",
  "三十一岁的我",
]);
const g0DreamSceneMonologueIds = new Set([
  "G1-01-D01",
  "G1-01-D02",
  "G1-01-D03",
  "G1-01-D04",
  "G1-01-D05",
  "G1-01-D06",
  "G1-01-D11",
  "G1-01-D18",
]);

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

function deliveryForShot(unitId, speaker, shotId) {
  if (unitId === "G3-03") {
    return shotId === "SHOT-09" ? "dialogue" : "voiceover";
  }
  return deliveryFor(unitId, speaker);
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

function deliveryForLine(unitId, speaker, shotId, lineId) {
  if (lineId.startsWith("G1-01-D")) {
    return g0DreamSceneMonologueIds.has(lineId)
      ? "scene_monologue"
      : "dialogue";
  }
  return deliveryForShot(unitId, speaker, shotId);
}

function presentationForLine(lineId, delivery) {
  if (lineId === "G1-01-D18") {
    return "center";
  }
  if (lineId.startsWith("G1-01-D")) {
    return "caption";
  }
  return presentationFor(delivery);
}

function parseDialoguePacing(source) {
  const pacing = new Map();
  let currentLineId = "";

  for (const sourceLine of source.split(/\r?\n/)) {
    const lineHeader = sourceLine.match(
      /^- \[[ x]\] `(G[1-5]-\d{2}-(?:D\d{2}|\d{2}))`/,
    );
    if (lineHeader) {
      currentLineId = lineHeader[1];
      continue;
    }

    const revised = sourceLine.match(/^  - 修改后断句：(.*)$/);
    if (!revised) {
      continue;
    }
    if (!currentLineId) {
      throw new Error("Dialogue pacing entry has no line id.");
    }
    if (pacing.has(currentLineId)) {
      throw new Error(`Duplicate dialogue pacing entry for ${currentLineId}`);
    }

    const segments = revised[1]
      .split(/\s*◆\s*/)
      .map((page) => page.replace(/\s*↵\s*/g, "\n"));
    if (segments.length === 0 || segments.some((page) => page.length === 0)) {
      throw new Error(`Dialogue pacing entry ${currentLineId} has an empty page.`);
    }
    pacing.set(currentLineId, segments);
  }

  return pacing;
}

const dialoguePacing = parseDialoguePacing(dialoguePacingSource);

const stableLineIds = {
  "G1-01": [
    ...Array.from({ length: 18 }, (_, index) =>
      `G1-01-D${String(index + 1).padStart(2, "0")}`,
    ),
    ...Array.from({ length: 23 }, (_, index) =>
      `G1-01-${String(index + 2).padStart(2, "0")}`,
    ),
  ],
};

function lineIdFor(unitId, lineIndex) {
  const stableIds = stableLineIds[unitId];
  if (stableIds) {
    const id = stableIds[lineIndex];
    if (!id) {
      throw new Error(`Missing stable line id for ${unitId} line ${lineIndex + 1}`);
    }
    return id;
  }
  return `${unitId}-${String(lineIndex + 1).padStart(2, "0")}`;
}

function parseSceneLines(section, unitId, defaultShot) {
  const lines = [];
  let currentShot = defaultShot;

  for (const sourceLine of section.split(/\r?\n/)) {
    const shotMarker = sourceLine.match(/^独立美术资源：`(SHOT-\d{2})`。$/);
    if (shotMarker) {
      currentShot = shotMarker[1];
      continue;
    }

    const dialogue = sourceLine.match(/^> \*\*([^*]+)：\*\*\s*(.+)$/);
    if (!dialogue) {
      continue;
    }

    const id = lineIdFor(unitId, lines.length);
    const speaker = dialogue[1].trim();
    const delivery = deliveryForLine(unitId, speaker, currentShot, id);
    const text = dialogue[2].trim();
    const segments = dialoguePacing.get(id);
    if (!segments) {
      throw new Error(`Missing reviewed dialogue pacing for ${id}`);
    }
    const reconstructedText = segments.join("").replaceAll("\n", "");
    if (reconstructedText !== text) {
      throw new Error(
        `Dialogue pacing text mismatch for ${id}:\n` +
          `script: ${text}\n` +
          `review: ${reconstructedText}`,
      );
    }
    lines.push({
      id,
      speaker,
      text,
      segments,
      delivery,
      presentation: presentationForLine(id, delivery),
      shot: currentShot,
    });
  }

  return lines;
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
  const assets = mapping.get(header[1]);

  if (!assets) {
    throw new Error(`Missing asset mapping for ${header[1]}`);
  }
  const lines = parseSceneLines(section, header[1], assets.shot);
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
if (dialoguePacing.size !== lineCount) {
  throw new Error(
    `Dialogue pacing has ${dialoguePacing.size} entries for ${lineCount} lines.`,
  );
}

const shotVariants = {
  "SHOT-01": {
    dream_pov_wake: "res://assets/shots/shot-01/dream-pov-wake-restyled.webp",
    dream_wake: "res://assets/shots/shot-01/dream-wake-restyled.webp",
    dream_loss: "res://assets/shots/shot-01/dream-loss-restyled.webp",
    dream_shadow: "res://assets/shots/shot-01/dream-shadow-restyled.webp",
    dream_reveal: "res://assets/shots/shot-01/dream-reveal-restyled.webp",
    dream_youth_close: "res://assets/shots/shot-01/dream-youth-close-restyled.webp",
    dream_adult_reaction: "res://assets/shots/shot-01/dream-adult-reaction-restyled.webp",
    dream_confrontation: "res://assets/shots/shot-01/dream-confrontation-restyled.webp",
    dream_train_approach: "res://assets/shots/shot-01/dream-train-approach-restyled.webp",
    dream_train_stop: "res://assets/shots/shot-01/dream-train-stop-restyled.webp",
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
  "SHOT-16": {
    sunset: "res://assets/shots/shot-16/sunset.webp",
    blue: "res://assets/shots/shot-16/blue.webp",
    stars: "res://assets/shots/shot-16/stars.webp",
    moonrise: "res://assets/shots/shot-16/moonrise.webp",
  },
  "SHOT-12": {
    outward: "res://assets/shots/shot-12/outward.webp",
    mountains: "res://assets/shots/shot-12/mountains.webp",
    pleasure: "res://assets/shots/shot-12/pleasure.webp",
    return: "res://assets/shots/shot-12/return.webp",
  },
  "SHOT-17": {
    fog: "res://assets/shots/shot-17/fog.webp",
    wide: "res://assets/shots/shot-17/wide.webp",
    sunrise_back: "res://assets/shots/shot-17/sunrise-back.webp",
  },
  "SHOT-70": {
    wide: "res://assets/shots/shot-70/master.webp",
    glass: "res://assets/shots/shot-70/glass.webp",
  },
  "SHOT-74": {
    lantern: "res://assets/shots/shot-74/master.webp",
    empty: "res://assets/shots/shot-74/empty.webp",
    "walk-step-01": "res://assets/shots/shot-74/master.webp",
    "walk-step-02": "res://assets/shots/shot-74/walk-step-02.png",
    "walk-step-03": "res://assets/shots/shot-74/walk-step-03.png",
    "identity-close": "res://assets/shots/shot-74/identity-close.png",
  },
};
const shotMasters = {
  "SHOT-01": "res://assets/shots/shot-01/g0-wake.webp",
  "SHOT-03": "res://assets/shots/shot-03/point.webp",
  "SHOT-04": "res://assets/shots/shot-04/closed.webp",
  "SHOT-19": "res://assets/shots/shot-19/base.webp",
  "SHOT-12": "res://assets/shots/shot-12/outward.webp",
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

if (Object.keys(shots).length !== 71) {
  throw new Error(`Expected 71 shot packages, got ${Object.keys(shots).length}`);
}

fs.mkdirSync(contentDir, { recursive: true });
fs.writeFileSync(
  path.join(contentDir, "story.json"),
  `${JSON.stringify(
    {
      version: 3,
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
