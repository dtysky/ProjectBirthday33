import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const toolDir = path.dirname(fileURLToPath(import.meta.url));
const musicDir = path.resolve(toolDir, "..", "assets", "audio", "music");
const reportPath = path.join(musicDir, "build-report.json");
const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));

function run(command, args) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
  if (result.status !== 0) {
    throw new Error(
      `${command} failed (${result.status}):\n${result.stderr || result.stdout}`,
    );
  }
  return result;
}

if (report.version !== 2 || report.cues.length !== 16) {
  throw new Error("Expected sixteen cues in music build report version 2.");
}

let loopCount = 0;
for (const cue of report.cues) {
  const filePath = path.join(musicDir, cue.runtime_file);
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing runtime file for ${cue.id}: ${filePath}`);
  }
  if (cue.measured_true_peak_db > -1.0) {
    throw new Error(`${cue.id} exceeds the runtime peak ceiling.`);
  }
  if (Math.abs(cue.measured_lufs - cue.target_lufs) > 0.25) {
    throw new Error(`${cue.id} missed its loudness target.`);
  }
  if (
    cue.source_start_seconds !== 0 ||
    cue.crossfade_seconds !== 0 ||
    cue.temporal_edit !== "none" ||
    Math.abs(cue.runtime_duration_seconds - cue.source_end_seconds) > 0.08
  ) {
    throw new Error(`${cue.id} is not a full-length, untrimmed source.`);
  }
  if (!cue.loop) {
    continue;
  }
  loopCount += 1;
  const fiveRounds = (cue.runtime_duration_seconds * 5).toFixed(3);
  run("ffmpeg", [
    "-hide_banner",
    "-loglevel",
    "error",
    "-stream_loop",
    "4",
    "-i",
    filePath,
    "-t",
    fiveRounds,
    "-f",
    "null",
    "-",
  ]);
}

if (loopCount !== 15) {
  throw new Error(`Expected fifteen loop-ready assets, got ${loopCount}.`);
}

console.log(
  "Music verification passed: sixteen full-length untrimmed normalized assets, " +
    "fifteen loops decoded for five consecutive rounds, and one one-shot layer."
);
