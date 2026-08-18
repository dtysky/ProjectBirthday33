#!/bin/zsh
set -euo pipefail

script_directory="${0:A:h}"
game_directory="${script_directory:h}"
godot_binary="${B33_GODOT_BINARY:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
recording_directory="${B33_RECORDING_DIR:-${HOME}/Downloads/b33/recordings}"
timestamp="$(date '+%Y-%m-%dT%H%M%S')"
movie_path="${recording_directory}/birthday-33-${timestamp}.ogv"

if [[ ! -x "${godot_binary}" ]]; then
	print -u2 "Godot executable not found: ${godot_binary}"
	exit 1
fi

mkdir -p "${recording_directory}"
print "Recording to ${movie_path}"
print "Enter the game normally, then press F9 to start automatic playback."

exec "${godot_binary}" \
	--path "${game_directory}" \
	--write-movie "${movie_path}" \
	--fixed-fps 60 \
	"$@"
