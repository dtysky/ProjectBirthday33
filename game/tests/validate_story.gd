extends SceneTree


func _init() -> void:
	var failures: Array[String] = []
	var story := _read_json("res://content/story.json")
	var manifest := _read_json("res://content/asset_manifest.json")
	var units := story.get("units", []) as Array
	var line_count := 0
	var delivery_counts := {
		"dialogue": 0,
		"scene_monologue": 0,
		"voiceover": 0,
		"screen_text": 0,
	}

	if units.size() != 28:
		failures.append("Expected 28 units, got %d." % units.size())

	for unit_variant in units:
		var unit := unit_variant as Dictionary
		var lines := unit.get("lines", []) as Array
		line_count += lines.size()
		for line_variant in lines:
			var line := line_variant as Dictionary
			if not ["bubble", "caption", "center"].has(str(line.get("presentation", ""))):
				failures.append("%s has an invalid presentation mode." % line.get("id", "unknown"))
			var delivery := str(line.get("delivery", ""))
			if not delivery_counts.has(delivery):
				failures.append("%s has an invalid delivery mode." % line.get("id", "unknown"))
			else:
				delivery_counts[delivery] += 1
		var shot_id := str(unit.get("shot", ""))
		if shot_id.is_empty():
			failures.append("%s has no shot mapping." % unit.get("id", "unknown"))
		elif not (manifest.get("shots", {}) as Dictionary).has(shot_id):
			failures.append("%s references unknown shot %s." % [unit.get("id", "unknown"), shot_id])

	if line_count != 111:
		failures.append("Expected 111 lines, got %d." % line_count)
	if int(delivery_counts["voiceover"]) != 20:
		failures.append("Expected 20 voiceover lines.")
	if int(delivery_counts["scene_monologue"]) != 34:
		failures.append("Expected 34 scene-monologue lines.")
	if (manifest.get("shots", {}) as Dictionary).size() != 19:
		failures.append("Expected 19 shot packages.")
	if int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) != 1920:
		failures.append("Expected a 1920-wide logical viewport.")
	if int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) != 1080:
		failures.append("Expected a 1080-high logical viewport.")
	if int(ProjectSettings.get_setting("display/window/size/window_width_override", 0)) != 3840:
		failures.append("Expected a 3840-wide output window.")
	if int(ProjectSettings.get_setting("display/window/size/window_height_override", 0)) != 2160:
		failures.append("Expected a 2160-high output window.")

	if failures.is_empty():
		print("Validation passed: 28 units, 111 lines, balanced delivery, 19 shots, 4K output.")
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
