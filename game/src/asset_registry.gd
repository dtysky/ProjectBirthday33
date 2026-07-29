class_name AssetRegistry
extends RefCounted

const MANIFEST_PATH := "res://content/asset_manifest.json"

var shots: Dictionary = {}


func load_manifest() -> bool:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open asset manifest: %s" % MANIFEST_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Asset manifest is not a JSON object.")
		return false

	shots = (parsed as Dictionary).get("shots", {}) as Dictionary
	return not shots.is_empty()


func load_master(shot_id: String) -> Texture2D:
	var shot: Dictionary = shots.get(shot_id, {})
	var path := str(shot.get("master", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


func load_variant(shot_id: String, variant_id: String) -> Texture2D:
	var shot: Dictionary = shots.get(shot_id, {})
	var variants: Dictionary = shot.get("variants", {}) as Dictionary
	var path := str(variants.get(variant_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D
