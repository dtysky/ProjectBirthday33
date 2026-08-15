import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const gameDir = path.resolve(toolDir, "..");

const cues = [
  {
    id: "MUS-01",
    source: "mus-01-dream-residue-source-v01-a.mp3",
    output: "mus-01-dream-residue",
    start: 5.5,
    end: 53.23,
    crossfade: 4.0,
    loop: true,
    targetLufs: -23.0,
  },
  {
    id: "MUS-02",
    source: "mus-02-performance-echo-source-v01-a.mp3",
    output: "mus-02-performance-echo",
    start: 25.49,
    end: 57.97,
    crossfade: 4.0,
    loop: true,
  },
  {
    id: "MUS-03A",
    source: "mus-03a-hesitation-source-v01-a.mp3",
    output: "mus-03a-hesitation",
    start: 5.5,
    end: 47.73,
    crossfade: 4.0,
    loop: true,
  },
  {
    id: "MUS-03B",
    source: "mus-03b-road-still-works-source-v01-a.mp3",
    output: "mus-03b-road-still-works",
    start: 38.73,
    end: 58.97,
    crossfade: 3.0,
    loop: true,
  },
  {
    id: "MUS-03C",
    source: "mus-03c-stop-detouring-source-v01-a.mp3",
    output: "mus-03c-stop-detouring",
    start: 16.74,
    end: 56.47,
    crossfade: 4.0,
    loop: true,
  },
  {
    id: "MUS-04",
    source: "mus-04-named-companions-source-v01-a.mp3",
    output: "mus-04-named-companions",
    start: 10.75,
    end: 83.49,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-05A",
    source: "mus-05a-search-source-v01-a.mp3",
    output: "mus-05a-search",
    start: 2.0,
    end: 22.0,
    loop: false,
    targetLufs: -23.0,
  },
  {
    id: "MUS-05B",
    source: "mus-05b-recognition-source-v01-a.mp3",
    output: "mus-05b-recognition",
    start: 31.24,
    end: 116.72,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-06B",
    source: "mus-06b-beginning-source-v01-a.mp3",
    output: "mus-06b-beginning",
    start: 37.73,
    end: 115.72,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-07A",
    source: "mus-07a-domestic-roads-source-v01-a.mp3",
    output: "mus-07a-domestic-roads",
    start: 18.24,
    end: 94.98,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-07B",
    source: "mus-07b-distant-roads-source-v01-a.mp3",
    output: "mus-07b-distant-roads",
    start: 26.99,
    end: 102.73,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-08A",
    source: "mus-08a-return-and-wait-source-v01-a.mp3",
    output: "mus-08a-return-and-wait",
    start: 9.5,
    end: 111.47,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-08B",
    source: "mus-08b-image-exists-source-v01-a.mp3",
    output: "mus-08b-image-exists",
    start: 31.99,
    end: 115.22,
    crossfade: 6.0,
    loop: true,
  },
  {
    id: "MUS-09A",
    source: "mus-09a-choice-already-exists-source-v01-a.mp3",
    output: "mus-09a-choice-already-exists",
    start: 23.99,
    end: 57.22,
    crossfade: 4.0,
    loop: true,
  },
  {
    id: "MUS-09B",
    source: "mus-09b-chosen-failure-source-v01-a.mp3",
    output: "mus-09b-chosen-failure",
    start: 19.49,
    end: 58.97,
    crossfade: 4.0,
    loop: true,
  },
  {
    id: "MUS-09C",
    source: "mus-09c-walk-to-lighthouse-source-v01-a.mp3",
    output: "mus-09c-walk-to-lighthouse",
    start: 36.73,
    end: 115.72,
    crossfade: 6.0,
    loop: true,
  },
];

function parseArgs(argv) {
  const options = {
    sourceDir: "/Users/dtysky/Downloads/b33/music",
    outputDir: path.join(gameDir, "assets", "audio", "music"),
  };
  for (let index = 0; index < argv.length; index += 1) {
    const value = argv[index];
    if (value === "--source-dir") {
      options.sourceDir = path.resolve(argv[++index]);
    } else if (value === "--output-dir") {
      options.outputDir = path.resolve(argv[++index]);
    } else if (value === "--master-dir") {
      options.masterDir = path.resolve(argv[++index]);
    } else {
      throw new Error(`Unknown argument: ${value}`);
    }
  }
  options.masterDir ??= path.join(options.sourceDir, "runtime-masters");
  return options;
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 16 * 1024 * 1024,
    ...options,
  });
  if (result.status !== 0) {
    throw new Error(
      `${command} failed (${result.status}):\n${result.stderr || result.stdout}`,
    );
  }
  return result;
}

function hashFile(filePath) {
  const hash = crypto.createHash("sha256");
  hash.update(fs.readFileSync(filePath));
  return hash.digest("hex");
}

function durationOf(filePath) {
  const result = run("ffprobe", [
    "-v",
    "error",
    "-show_entries",
    "format=duration",
    "-of",
    "default=noprint_wrappers=1:nokey=1",
    filePath,
  ]);
  return Number.parseFloat(result.stdout.trim());
}

function measureLoudness(filePath, targetLufs) {
  const result = run("ffmpeg", [
    "-hide_banner",
    "-nostats",
    "-i",
    filePath,
    "-af",
    `loudnorm=I=${targetLufs}:LRA=11:TP=-1.8:print_format=json`,
    "-f",
    "null",
    "-",
  ]);
  const match = result.stderr.match(/\{\s*"input_i"[\s\S]*?\}/);
  if (!match) {
    throw new Error(`Cannot parse loudness measurement for ${filePath}`);
  }
  const data = JSON.parse(match[0]);
  return {
    integratedLufs: Number.parseFloat(data.input_i),
    truePeakDb: Number.parseFloat(data.input_tp),
  };
}

function trimFilter(cue) {
  if (!cue.loop) {
    return (
      `[0:a]atrim=start=${cue.start}:end=${cue.end},` +
      "asetpts=PTS-STARTPTS[out]"
    );
  }

  const crossfade = cue.crossfade;
  const headEnd = cue.start + crossfade;
  const tailStart = cue.end - crossfade;
  return [
    "[0:a]asplit=3[core_source][tail_source][head_source]",
    `[core_source]atrim=start=${headEnd}:end=${tailStart},asetpts=PTS-STARTPTS[core]`,
    `[tail_source]atrim=start=${tailStart}:end=${cue.end},asetpts=PTS-STARTPTS,afade=t=out:st=0:d=${crossfade}:curve=qsin[tail]`,
    `[head_source]atrim=start=${cue.start}:end=${headEnd},asetpts=PTS-STARTPTS,afade=t=in:st=0:d=${crossfade}:curve=qsin[head]`,
    "[tail][head]amix=inputs=2:duration=longest:normalize=0,asetpts=PTS-STARTPTS[seam]",
    "[core][seam]concat=n=2:v=0:a=1[out]",
  ].join(";");
}

function buildCue(cue, options, tempDir) {
  const sourcePath = path.join(options.sourceDir, cue.source);
  if (!fs.existsSync(sourcePath)) {
    throw new Error(`Missing source for ${cue.id}: ${sourcePath}`);
  }

  const unmasteredPath = path.join(tempDir, `${cue.output}-unmastered.wav`);
  const masterPath = path.join(options.masterDir, `${cue.output}-master.wav`);
  const outputPath = path.join(options.outputDir, `${cue.output}.ogg`);
  run("ffmpeg", [
    "-y",
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    sourcePath,
    "-filter_complex",
    trimFilter(cue),
    "-map",
    "[out]",
    "-ar",
    "48000",
    "-ac",
    "2",
    "-c:a",
    "pcm_s24le",
    unmasteredPath,
  ]);

  const targetLufs = cue.targetLufs ?? -21.5;
  const before = measureLoudness(unmasteredPath, targetLufs);
  const loudnessGain = targetLufs - before.integratedLufs;
  const peakSafeGain = -1.8 - before.truePeakDb;
  const gainDb = Math.min(loudnessGain, peakSafeGain);

  run("ffmpeg", [
    "-y",
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    unmasteredPath,
    "-af",
    `volume=${gainDb.toFixed(4)}dB`,
    "-ar",
    "48000",
    "-ac",
    "2",
    "-c:a",
    "pcm_s24le",
    masterPath,
  ]);
  run("ffmpeg", [
    "-y",
    "-hide_banner",
    "-loglevel",
    "error",
    "-i",
    masterPath,
    "-ar",
    "48000",
    "-ac",
    "2",
    "-c:a",
    "libvorbis",
    "-q:a",
    "6",
    outputPath,
  ]);

  const after = measureLoudness(outputPath, targetLufs);
  return {
    id: cue.id,
    source_file: cue.source,
    source_sha256: hashFile(sourcePath),
    runtime_file: path.basename(outputPath),
    runtime_sha256: hashFile(outputPath),
    loop: cue.loop,
    source_start_seconds: cue.start,
    source_end_seconds: cue.end,
    crossfade_seconds: cue.crossfade ?? 0,
    runtime_duration_seconds: Number(durationOf(outputPath).toFixed(3)),
    target_lufs: targetLufs,
    applied_gain_db: Number(gainDb.toFixed(2)),
    measured_lufs: Number(after.integratedLufs.toFixed(2)),
    measured_true_peak_db: Number(after.truePeakDb.toFixed(2)),
  };
}

const options = parseArgs(process.argv.slice(2));
fs.mkdirSync(options.outputDir, { recursive: true });
fs.mkdirSync(options.masterDir, { recursive: true });
const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "b33-music-"));

try {
  const report = [];
  for (const cue of cues) {
    process.stdout.write(`Building ${cue.id}... `);
    const result = buildCue(cue, options, tempDir);
    report.push(result);
    console.log(
      `${result.runtime_duration_seconds.toFixed(1)}s, ` +
        `${result.measured_lufs.toFixed(1)} LUFS`,
    );
  }
  fs.writeFileSync(
    path.join(options.outputDir, "build-report.json"),
    `${JSON.stringify({ version: 1, cues: report }, null, 2)}\n`,
  );
  console.log(`WAV masters: ${options.masterDir}`);
  console.log(`Godot Ogg: ${options.outputDir}`);
} finally {
  fs.rmSync(tempDir, { recursive: true, force: true });
}
