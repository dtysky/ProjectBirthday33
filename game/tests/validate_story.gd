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
			var line_shot_id := str(line.get("shot", ""))
			if line_shot_id.is_empty():
				failures.append("%s has no line-level shot mapping." % line.get("id", "unknown"))
			elif not (manifest.get("shots", {}) as Dictionary).has(line_shot_id):
				failures.append(
					"%s references unknown line shot %s." % [
						line.get("id", "unknown"),
						line_shot_id,
					]
				)
			elif not (unit.get("assets", []) as Array).has(line_shot_id):
				failures.append(
					"%s uses %s outside its unit asset list." % [
						line.get("id", "unknown"),
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
	for delivery in delivery_counts:
		if int(delivery_counts[delivery]) == 0:
			failures.append("Story has no %s lines." % delivery)
	if (manifest.get("shots", {}) as Dictionary).size() != 64:
		failures.append("Expected 64 shot packages.")
	var shot_one := (manifest.get("shots", {}) as Dictionary).get("SHOT-01", {}) as Dictionary
	var opening_variants := shot_one.get("variants", {}) as Dictionary
	for variant_id in ["wake", "wash", "cats", "board", "drive", "arrive"]:
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
		"SHOT-13", "SHOT-43", "SHOT-44", "SHOT-45", "SHOT-46",
		"SHOT-47", "SHOT-48", "SHOT-49", "SHOT-50", "SHOT-51",
		"SHOT-52", "SHOT-53", "SHOT-54", "SHOT-56", "SHOT-62",
		"SHOT-63", "SHOT-66", "SHOT-68", "SHOT-69",
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
	var g4_placeholders := [
		"SHOT-12", "SHOT-14", "SHOT-15", "SHOT-16",
		"SHOT-55", "SHOT-58", "SHOT-60", "SHOT-61",
	]
	for shot_id in g4_placeholders:
		var shot := (manifest.get("shots", {}) as Dictionary).get(shot_id, {}) as Dictionary
		var asset_path := str(shot.get("master", ""))
		if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
			failures.append("%s should still be an explicit G4 placeholder." % shot_id)
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
				+ "64 planned shots, six G0 CGs, seven G1 CGs, sixteen G2 trial masters, "
				+ "fourteen G3 masters, nineteen accepted G4 masters, eight G4 placeholders, 4K output."
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
