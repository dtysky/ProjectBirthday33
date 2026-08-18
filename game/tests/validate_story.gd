extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var story := _read_json("res://content/story.json")
	var manifest := _read_json("res://content/asset_manifest.json")
	var music := _read_json("res://content/music_cues.json")
	var voice_sequences := _read_json("res://content/voice_sequences.json")
	var music_build := _read_json("res://assets/audio/music/build-report.json")
	var units := story.get("units", []) as Array
	var line_count := 0
	var line_ids: Dictionary = {}
	var lines_by_id: Dictionary = {}
	var line_order: Array[String] = []
	var delivery_counts := {
		"dialogue": 0,
		"scene_monologue": 0,
		"voiceover": 0,
		"screen_text": 0,
	}

	if int(story.get("version", 0)) != 3:
		failures.append("Expected reviewed-dialogue story format version 3.")
	if units.size() != 28:
		failures.append("Expected 28 units, got %d." % units.size())

	for unit_variant in units:
		var unit := unit_variant as Dictionary
		var lines := unit.get("lines", []) as Array
		line_count += lines.size()
		for line_variant in lines:
			var line := line_variant as Dictionary
			var line_id := str(line.get("id", "unknown"))
			line_ids[line_id] = true
			lines_by_id[line_id] = line
			line_order.append(line_id)
			if not ["bubble", "caption", "center"].has(str(line.get("presentation", ""))):
				failures.append("%s has an invalid presentation mode." % line_id)
			var delivery := str(line.get("delivery", ""))
			if not delivery_counts.has(delivery):
				failures.append("%s has an invalid delivery mode." % line_id)
			else:
				delivery_counts[delivery] += 1
			var segments := line.get("segments", []) as Array
			if segments.is_empty():
				failures.append("%s has no reviewed dialogue segments." % line_id)
			else:
				var reconstructed_text := ""
				for segment_variant in segments:
					var segment := str(segment_variant)
					if segment.is_empty():
						failures.append("%s contains an empty reviewed page." % line_id)
					if segment.contains("◆") or segment.contains("↵"):
						failures.append("%s still contains review notation at runtime." % line_id)
					reconstructed_text += segment.replace("\n", "")
				if reconstructed_text != str(line.get("text", "")):
					failures.append("%s reviewed pages do not reconstruct its script text." % line_id)
			var line_shot_id := str(line.get("shot", ""))
			if line_shot_id.is_empty():
				failures.append("%s has no line-level shot mapping." % line_id)
			elif not (manifest.get("shots", {}) as Dictionary).has(line_shot_id):
				failures.append(
					"%s references unknown line shot %s." % [
						line_id,
						line_shot_id,
					]
				)
			elif not (unit.get("assets", []) as Array).has(line_shot_id):
				failures.append(
					"%s uses %s outside its unit asset list." % [
						line_id,
						line_shot_id,
					]
				)
		var shot_id := str(unit.get("shot", ""))
		if shot_id.is_empty():
			failures.append("%s has no shot mapping." % unit.get("id", "unknown"))
		elif not (manifest.get("shots", {}) as Dictionary).has(shot_id):
			failures.append("%s references unknown shot %s." % [unit.get("id", "unknown"), shot_id])
		for asset_ref_variant in unit.get("assets", []) as Array:
			var asset_ref := str(asset_ref_variant)
			if asset_ref.begins_with("SHOT-") and not (manifest.get("shots", {}) as Dictionary).has(asset_ref):
				failures.append("%s references unknown asset %s." % [unit.get("id", "unknown"), asset_ref])

	if line_count != int(story.get("line_count", -1)):
		failures.append(
			"Story metadata says %d lines, but %d were loaded." % [
				int(story.get("line_count", -1)),
				line_count,
			]
		)
	var reviewed_text := {
		"G2-04-04": "我准备去竞选另一个项目，先活下来再说吧。",
		"G2-04-21": "还是想做一次3A，网易那边是燕云，做引擎。",
		"G2-05-02": "作为团队里最懂AI的人，组员也对AI有着极大热情。所以我也真的觉得，我们有机会把这件事做成。",
		"G2-05-05": "回到深圳以后，我又去现场参加了最终竞聘。已经预期到的结局，但还是选择由自己见证。",
		"G4-02-17": "年少的我从未想过，有一天能靠自己完成这样一场特别的「圣地巡礼」。",
		"G5-01-03": "但越是想继续干下去，就越是休息不好。即便只是在摸鱼，也会反复焦虑、失眠，甚至频繁感冒。",
	}
	for line_id in reviewed_text:
		if str((lines_by_id.get(line_id, {}) as Dictionary).get("text", "")) != reviewed_text[line_id]:
			failures.append("%s does not contain its corrected reviewed sentence." % line_id)
	for delivery in delivery_counts:
		if int(delivery_counts[delivery]) == 0:
			failures.append("Story has no %s lines." % delivery)
	if (manifest.get("shots", {}) as Dictionary).size() != 71:
		failures.append("Expected 71 shot packages.")
	var shot_one := (manifest.get("shots", {}) as Dictionary).get("SHOT-01", {}) as Dictionary
	var opening_variants := shot_one.get("variants", {}) as Dictionary
	for variant_id in [
		"wake", "wash", "cats", "board", "drive", "arrive",
		"dream_pov_wake", "dream_wake", "dream_loss", "dream_shadow", "dream_reveal",
		"dream_youth_close", "dream_adult_reaction", "dream_confrontation",
		"dream_train_approach", "dream_train_stop",
	]:
		var variant_path := str(opening_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-01 is missing G0 variant %s." % variant_id)
	var g1_assets := {
		"SHOT-02": ["master"],
		"SHOT-03": ["point", "thumb"],
		"SHOT-04": ["closed", "open"],
		"SHOT-19": ["base", "reflection"],
	}
	for shot_id in g1_assets:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		for asset_id in g1_assets[shot_id]:
			var asset_path := str(shot.get("master", ""))
			if str(asset_id) != "master":
				asset_path = str((shot.get("variants", {}) as Dictionary).get(asset_id, ""))
			if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
				failures.append("%s is missing G1 asset %s." % [shot_id, asset_id])
				continue
			var texture := ResourceLoader.load(asset_path) as Texture2D
			if texture == null or texture.get_width() != 3840 or texture.get_height() != 2160:
				failures.append("%s/%s is not a 3840x2160 texture." % [shot_id, asset_id])
	var g2_masters := [
		"SHOT-05", "SHOT-06", "SHOT-07", "SHOT-08",
		"SHOT-20", "SHOT-21", "SHOT-22", "SHOT-23",
		"SHOT-24", "SHOT-25", "SHOT-26", "SHOT-27",
		"SHOT-28", "SHOT-29", "SHOT-30", "SHOT-31",
	]
	for shot_id in g2_masters:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		var asset_path := str(shot.get("master", ""))
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			failures.append("%s is missing its G2 trial master." % shot_id)
			continue
		var texture := ResourceLoader.load(asset_path) as Texture2D
		if texture == null or texture.get_width() != 3840 or texture.get_height() != 2160:
			failures.append("%s/master is not a 3840x2160 texture." % shot_id)
	var g3_masters := [
		"SHOT-09", "SHOT-10", "SHOT-11",
		"SHOT-32", "SHOT-33", "SHOT-34", "SHOT-35", "SHOT-36", "SHOT-37",
		"SHOT-38", "SHOT-39", "SHOT-40", "SHOT-41", "SHOT-42",
	]
	for shot_id in g3_masters:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		var asset_path := str(shot.get("master", ""))
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			failures.append("%s is missing its G3 master." % shot_id)
			continue
		var texture := ResourceLoader.load(asset_path) as Texture2D
		if texture == null or texture.get_width() != 3840 or texture.get_height() != 2160:
			failures.append("%s/master is not a 3840x2160 texture." % shot_id)
	var g4_masters := [
		"SHOT-12", "SHOT-13", "SHOT-14", "SHOT-15", "SHOT-16", "SHOT-43", "SHOT-44", "SHOT-45", "SHOT-46",
		"SHOT-47", "SHOT-48", "SHOT-49", "SHOT-50", "SHOT-51",
		"SHOT-52", "SHOT-53", "SHOT-54", "SHOT-55", "SHOT-56", "SHOT-58", "SHOT-60", "SHOT-61",
		"SHOT-62", "SHOT-63", "SHOT-66", "SHOT-68", "SHOT-69",
	]
	for shot_id in g4_masters:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		var asset_path := str(shot.get("master", ""))
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			failures.append("%s is missing its accepted G4 master." % shot_id)
			continue
		var texture := ResourceLoader.load(asset_path) as Texture2D
		if texture == null or texture.get_width() != 3840 or texture.get_height() != 2160:
			failures.append("%s/master is not a 3840x2160 texture." % shot_id)
	var shot_sixteen := (manifest.get("shots", {}) as Dictionary).get("SHOT-16", {}) as Dictionary
	var shot_sixteen_variants := shot_sixteen.get("variants", {}) as Dictionary
	for variant_id in ["sunset", "blue", "stars", "moonrise"]:
		var variant_path := str(shot_sixteen_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-16 is missing G4 sky variant %s." % variant_id)
			continue
		var variant_texture := ResourceLoader.load(variant_path) as Texture2D
		if variant_texture == null or variant_texture.get_width() != 3840 or variant_texture.get_height() != 2160:
			failures.append("SHOT-16/%s is not a 3840x2160 texture." % variant_id)
	var shot_twelve := (manifest.get("shots", {}) as Dictionary).get("SHOT-12", {}) as Dictionary
	var shot_twelve_variants := shot_twelve.get("variants", {}) as Dictionary
	for variant_id in ["outward", "mountains", "pleasure", "return"]:
		var variant_path := str(shot_twelve_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-12 is missing G4 memory phase %s." % variant_id)
			continue
		var variant_texture := ResourceLoader.load(variant_path) as Texture2D
		if variant_texture == null or variant_texture.get_width() != 3840 or variant_texture.get_height() != 2160:
			failures.append("SHOT-12/%s is not a 3840x2160 texture." % variant_id)
	var g5_masters := [
		"SHOT-17", "SHOT-18", "SHOT-70", "SHOT-71",
		"SHOT-72", "SHOT-73", "SHOT-74", "SHOT-75", "SHOT-76",
	]
	for shot_id in g5_masters:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		var asset_path := str(shot.get("master", ""))
		if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
			failures.append("%s is missing its selected G5 runtime master." % shot_id)
			continue
		var texture := ResourceLoader.load(asset_path) as Texture2D
		if texture == null or texture.get_width() != 3840 or texture.get_height() != 2160:
			failures.append("%s/master is not a 3840x2160 texture." % shot_id)
	var shot_seventeen := (manifest.get("shots", {}) as Dictionary).get("SHOT-17", {}) as Dictionary
	var shot_seventeen_variants := shot_seventeen.get("variants", {}) as Dictionary
	for variant_id in ["fog", "wide", "sunrise_back"]:
		var variant_path := str(shot_seventeen_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-17 is missing G5 phase %s." % variant_id)
			continue
		var variant_texture := ResourceLoader.load(variant_path) as Texture2D
		if variant_texture == null or variant_texture.get_width() != 3840 or variant_texture.get_height() != 2160:
			failures.append("SHOT-17/%s is not a 3840x2160 texture." % variant_id)
	var shot_seventy := (manifest.get("shots", {}) as Dictionary).get("SHOT-70", {}) as Dictionary
	var shot_seventy_variants := shot_seventy.get("variants", {}) as Dictionary
	for variant_id in ["wide", "glass"]:
		var variant_path := str(shot_seventy_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-70 is missing G5 ruin state %s." % variant_id)
			continue
		var variant_texture := ResourceLoader.load(variant_path) as Texture2D
		if variant_texture == null or variant_texture.get_width() != 3840 or variant_texture.get_height() != 2160:
			failures.append("SHOT-70/%s is not a 3840x2160 texture." % variant_id)
	var shot_seventy_four := (manifest.get("shots", {}) as Dictionary).get("SHOT-74", {}) as Dictionary
	var shot_seventy_four_variants := shot_seventy_four.get("variants", {}) as Dictionary
	for variant_id in [
		"lantern",
		"walk-step-01",
		"walk-step-02",
		"walk-step-03",
		"identity-close",
		"identity-wind-hair-lead",
		"identity-wind-mid",
		"identity-wind-peak",
		"identity-wind-coat-lag",
		"identity-wind-fall",
	]:
		var variant_path := str(shot_seventy_four_variants.get(variant_id, ""))
		if variant_path.is_empty() or not ResourceLoader.exists(variant_path):
			failures.append("SHOT-74 is missing G5 ending state %s." % variant_id)
			continue
		var variant_texture := ResourceLoader.load(variant_path) as Texture2D
		if variant_texture == null or variant_texture.get_width() != 3840 or variant_texture.get_height() != 2160:
			failures.append("SHOT-74/%s is not a 3840x2160 texture." % variant_id)
	var expected_music_ids := [
		"MUS-02", "MUS-03B", "MUS-03C", "MUS-04", "MUS-05A", "MUS-05B", "MUS-06B",
		"MUS-07B", "MUS-09C",
	]
	var expected_built_music_ids := [
		"MUS-01", "MUS-02", "MUS-03A", "MUS-03B", "MUS-03C", "MUS-04",
		"MUS-05A", "MUS-05B", "MUS-06B", "MUS-07A", "MUS-07B",
		"MUS-08A", "MUS-08B", "MUS-09A", "MUS-09B", "MUS-09C",
	]
	var music_cues := music.get("cues", []) as Array
	var soundtrack_lines: Dictionary = {}
	var timed_voice_line_count := 0
	var timed_voice_segment_count := 0
	if int(voice_sequences.get("version", 0)) != 1:
		failures.append("Expected voice sequence format version 1.")
	for sequence_variant in voice_sequences.get("sequences", []) as Array:
		var sequence := sequence_variant as Dictionary
		var stream_path := str(sequence.get("stream", ""))
		var duration := float(sequence.get("duration", 0.0))
		var handoff_at := float(sequence.get("handoff_at", -1.0))
		var start_at := float(sequence.get("start_at", 0.0))
		if stream_path.is_empty() or not ResourceLoader.exists(stream_path):
			failures.append("Timed voice sequence is missing its runtime stream.")
		else:
			var stream := ResourceLoader.load(stream_path) as AudioStream
			if stream == null or absf(stream.get_length() - duration) > 0.3:
				failures.append("Timed voice sequence duration does not match its runtime stream.")
		var is_soundtrack := bool(sequence.get("soundtrack", false))
		if (
			str(sequence.get("id", "")) == "G4-01-THIRTY-ONE"
			and not is_equal_approx(float(sequence.get("volume_db", 0.0)), -4.0)
		):
			failures.append("G4-01 original soundtrack is no longer at its reviewed gain.")
		if handoff_at >= 0.0 and (handoff_at <= 0.0 or handoff_at >= duration):
			failures.append("Timed voice handoff must occur before its natural audio ending.")
		if is_soundtrack and handoff_at < 0.0:
			failures.append("Timed soundtrack is missing its controlled handoff.")
		if start_at < 0.0 or start_at >= duration:
			failures.append("Timed voice sequence has an invalid playback start.")
		var previous_at := -1.0
		for cue_variant in sequence.get("cues", []) as Array:
			var voice_cue := cue_variant as Dictionary
			var line_id := str(voice_cue.get("line_id", ""))
			var cue_at := float(voice_cue.get("at", -1.0))
			var segment_index := int(voice_cue.get("segment_index", 0))
			if not line_ids.has(line_id):
				failures.append("Timed voice cue references unknown line %s." % line_id)
			if cue_at <= previous_at or cue_at >= duration:
				failures.append("Timed voice cue %s has an invalid time." % line_id)
			if segment_index < 0:
				failures.append("Timed voice cue %s has an invalid segment index." % line_id)
			elif segment_index > 0:
				var voice_line := lines_by_id.get(line_id, {}) as Dictionary
				if segment_index >= (voice_line.get("segments", []) as Array).size():
					failures.append("Timed voice cue %s references a missing page." % line_id)
				timed_voice_segment_count += 1
			previous_at = cue_at
			if segment_index == 0:
				timed_voice_line_count += 1
			if is_soundtrack and segment_index == 0:
				soundtrack_lines[line_id] = true
	var music_ids: Dictionary = {}
	var loop_count := 0
	if int(music.get("version", 0)) != 2:
		failures.append("Expected music cue format version 2.")
	if music_cues.size() != expected_music_ids.size():
		failures.append(
			"Expected %d active music states, got %d." % [
				expected_music_ids.size(),
				music_cues.size(),
			]
		)
	for cue_variant in music_cues:
		var cue := cue_variant as Dictionary
		var cue_id := str(cue.get("id", ""))
		var stream_path := str(cue.get("stream", ""))
		if cue_id.is_empty() or music_ids.has(cue_id):
			failures.append("Music cue id is empty or duplicated: %s." % cue_id)
		music_ids[cue_id] = true
		var cue_ranges := cue.get("ranges", []) as Array
		if cue_ranges.is_empty():
			cue_ranges = [{
				"start_line": cue.get("start_line", ""),
				"end_line": cue.get("end_line", ""),
			}]
		for range_variant in cue_ranges:
			var line_range := range_variant as Dictionary
			var start_line := str(line_range.get("start_line", ""))
			var end_line := str(line_range.get("end_line", ""))
			if not line_ids.has(start_line) or not line_ids.has(end_line):
				failures.append("%s references an unknown story range." % cue_id)
			elif start_line > end_line:
				failures.append("%s has a reversed story range." % cue_id)
		if stream_path.is_empty() or not ResourceLoader.exists(stream_path):
			failures.append("%s is missing its runtime Ogg." % cue_id)
		else:
			var stream := ResourceLoader.load(stream_path) as AudioStream
			if stream == null or stream.get_length() < 10.0:
				failures.append("%s has an invalid runtime audio stream." % cue_id)
		if bool(cue.get("loop", false)):
			loop_count += 1
	for cue_id in expected_music_ids:
		if not music_ids.has(cue_id):
			failures.append("Active music state %s is missing." % cue_id)
	for excluded_id in ["MUS-06A", "MUS-07C"]:
		if music_ids.has(excluded_id):
			failures.append("Excluded or duplicated cue %s entered runtime." % excluded_id)
	if loop_count != 8:
		failures.append("Expected eight looping BGM states, got %d." % loop_count)
	for line_id in line_order:
		var coverage_count := 0
		for cue_variant in music_cues:
			var cue := cue_variant as Dictionary
			if str(cue.get("trigger_mode", "line")) == "custom":
				continue
			var cue_ranges := cue.get("ranges", []) as Array
			if cue_ranges.is_empty():
				cue_ranges = [{
					"start_line": cue.get("start_line", ""),
					"end_line": cue.get("end_line", ""),
				}]
			for range_variant in cue_ranges:
				var line_range := range_variant as Dictionary
				if (
					line_id >= str(line_range.get("start_line", ""))
					and line_id <= str(line_range.get("end_line", ""))
				):
					coverage_count += 1
		var is_g1_unscored := line_id >= "G1-05-01" and line_id <= "G1-06-06"
		var expected_coverage := 0 if soundtrack_lines.has(line_id) or is_g1_unscored else 1
		if coverage_count != expected_coverage:
			failures.append(
				"%s has %d line-triggered BGM states; expected %d." % [
					line_id,
					coverage_count,
					expected_coverage,
				]
			)
	if timed_voice_line_count != 169:
		failures.append("Expected 169 timed voice lines, got %d." % timed_voice_line_count)
	if timed_voice_segment_count != 30:
		failures.append("Expected 30 timed voice page cues, got %d." % timed_voice_segment_count)
	var built_cues := music_build.get("cues", []) as Array
	if int(music_build.get("version", 0)) != 2:
		failures.append("Music build report must use full-source format version 2.")
	if built_cues.size() != expected_built_music_ids.size():
		failures.append("Music build report does not cover all processed assets.")
	else:
		for built_variant in built_cues:
			var built := built_variant as Dictionary
			if not expected_built_music_ids.has(str(built.get("id", ""))):
				failures.append("Music build report contains an unknown asset.")
			if float(built.get("measured_true_peak_db", 0.0)) > -1.0:
				failures.append("%s exceeds the runtime peak ceiling." % built.get("id", ""))
			if (
				float(built.get("source_start_seconds", -1.0)) != 0.0
				or float(built.get("crossfade_seconds", -1.0)) != 0.0
				or str(built.get("temporal_edit", "")) != "none"
				or absf(
					float(built.get("runtime_duration_seconds", 0.0))
					- float(built.get("source_end_seconds", -1.0))
				) > 0.08
			):
				failures.append("%s is not a complete untrimmed original track." % built.get("id", ""))

	if int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) != 1920:
		failures.append("Expected a 1920-wide logical viewport.")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) != 1080:
		failures.append("Expected a 1080-high logical viewport.")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)) != 3840:
		failures.append("Expected a 3840-wide output window.")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)) != 2160:
		failures.append("Expected a 2160-high output window.")

	if failures.is_empty():
		print(
			(
				"Validation passed: 28 units, %d lines, balanced delivery, "
				+ "71 planned shots, ten G0 dream states plus six reality CGs, seven G1 CGs, sixteen G2 trial masters, "
				+ "fourteen G3 masters, twenty-seven G4 runtime packages with four SHOT-12 phases, "
				+ "twenty-one G5 runtime states across nine packages, nine active music states, "
				+ "eight looping states, nine timed soundtrack lines and eight intentionally unscored G1 lines, "
				+ "no G5 placeholder, 4K output."
			) % line_count
		)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary
