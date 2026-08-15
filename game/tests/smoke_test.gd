extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://src/main.tscn") as PackedScene
	if packed == null:
		push_error("Cannot load main scene.")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var required := [
		"Stage",
		"MasterTexture",
		"AssetPlaceholder",
		"ChapterFxLayer",
		"DialoguePanel",
		"DialoguePanel/DialogueMargin/DialogueBox/SpeakerLabel",
		"CenterLine",
		"ChapterInterludeOverlay",
		"ChapterInterludeOverlay/Backdrop",
		"ChapterInterludeOverlay/AtmosphereWash",
		"ChapterInterludeOverlay/OrganicVignette",
		"ChapterInterludeOverlay/ChapterNumber",
		"ChapterInterludeOverlay/ChapterRule",
		"ChapterInterludeOverlay/ChapterTitle",
		"QuickMenuOverlay",
		"SceneSelectOverlay",
		"MenuButton",
		"TitleOverlay",
		"HistoryOverlay",
		"SettingsOverlay",
		"ChapterFxLayer/OpeningBackdrop",
		"ChapterFxLayer/OpeningTexture",
		"ChapterFxLayer/OpeningPlaceholder",
		"ChapterFxLayer/G1ReverseSplit",
		"ChapterFxLayer/G3GlareOverlay",
		"ChapterFxLayer/G3TransitionOverlay",
		"ChapterFxLayer/G3EvidenceOverlay",
		"ChapterFxLayer/G4TransitionTexture",
		"ChapterFxLayer/G4PaperFrame",
		"ChapterFxLayer/G4TimeMarker",
		"ChapterFxLayer/G5TransitionTexture",
		"ChapterFxLayer/G5LinksPlaceholder",
		"ChapterFxLayer/G5TransitionOverlay",
		"G3EvidenceTimer",
		"MusicDirector/MusicPlayerA",
		"MusicDirector/MusicPlayerB",
		"VoiceSequencePlayer/VoiceTrack",
	]
	for node_name in required:
		if scene.get_node_or_null(node_name) == null:
			push_error("Missing runtime node: %s" % node_name)
			quit(1)
			return

	scene.call("_show_scene_select")
	await process_frame
	var scene_select := scene.get_node("SceneSelectOverlay") as Control
	var scene_list := scene_select.find_child("SceneList", true, false) as ItemList
	if not scene_select.visible or scene_list.item_count != 6:
		push_error("Scene selector did not expose all six G1 units.")
		quit(1)
		return
	scene.call("_jump_to_scene", 6)
	await process_frame
	var selector_story: RefCounted = scene.get("story")
	var selector_director := scene.get("active_chapter_director") as RefCounted
	if (
		scene_select.visible
		or int(selector_story.get("unit_index")) != 6
		or selector_director == null
		or int(selector_director.get("chapter_number")) != 2
		or not bool(scene.get("chapter_interlude_active"))
		or not (scene.get_node("ChapterInterludeOverlay") as Control).visible
		or (scene.get_node("ChapterInterludeOverlay/ChapterTitle") as Label).text != "最后一次迂回"
	):
		push_error("Scene selector did not enter G2-01 through its chapter interlude.")
		quit(1)
		return

	scene.call("_start_new_game")
	await process_frame
	var story: RefCounted = scene.get("story")
	var music_director := scene.get("music_director") as Node
	if int(story.get("unit_index")) != 0 or int(story.get("line_index")) != 0:
		push_error("New game did not start at G1-01 line 1.")
		quit(1)
		return

	var opening_director := scene.get("active_chapter_director") as RefCounted
	if opening_director == null or int(opening_director.get("chapter_number")) != 1:
		push_error("Chapter 1 director was not activated.")
		quit(1)
		return

	var opening_texture := scene.get_node(
		"ChapterFxLayer/OpeningTexture"
	) as TextureRect
	var opening_placeholder := scene.get_node(
		"ChapterFxLayer/OpeningPlaceholder"
	) as Label
	var center_line := scene.get_node("CenterLine") as Label
	if not opening_placeholder.visible or not opening_placeholder.text.contains("梦境"):
		push_error("G0 did not begin on the dream placeholder.")
		quit(1)
		return
	if center_line.visible:
		push_error("G0 dream placeholder did not preserve its opening silent hold.")
		quit(1)
		return
	await create_timer(1.10).timeout
	if (
		int(story.get("line_index")) != 0
		or not opening_placeholder.visible
		or center_line.visible
	):
		push_error("G0 advanced from the dream placeholder while auto mode was off.")
		quit(1)
		return

	scene.call("_advance_story")
	await process_frame
	if (
		not center_line.visible
		or str(opening_director.get("current_visual_id")) != "black"
		or center_line.visible_characters < 0
		or center_line.visible_characters >= center_line.text.length()
	):
		push_error("G0 black-screen line did not begin with the shared typewriter reveal.")
		quit(1)
		return

	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.30).timeout
	if (
		int(story.get("line_index")) != 1
		or str(opening_director.get("current_visual_id")) != "wake"
		or not opening_texture.visible
		or opening_texture.texture == null
	):
		push_error("G0 wake CG was not shown for the birthday line.")
		quit(1)
		return
	await create_timer(1.60).timeout
	if (
		int(story.get("line_index")) != 1
		or str(opening_director.get("current_visual_id")) != "wake"
	):
		push_error("G0 advanced from the wake CG while auto mode was off.")
		quit(1)
		return
	var opening_beats := opening_director.get("current_beats") as Array
	if (
		opening_beats.size() != 2
		or str((opening_beats[0] as Dictionary).get("text", "")) != "2026 年 8 月 20 日。"
		or str((opening_beats[1] as Dictionary).get("text", "")) != "三十三岁的第一天。\n我似乎做了一个梦。"
	):
		push_error("G1-01 did not distinguish reviewed page breaks from in-page line breaks.")
		quit(1)
		return

	story.call("start_at", 0, 4)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "wake"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.50
		or _max_line_length(center_line.text) > 16
	):
		push_error("G0 wake narration did not use the left-side bed safe area and compact wrapping.")
		quit(1)
		return

	story.call("start_at", 0, 6)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "wash"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.68
		or _max_line_length(center_line.text) > 13
	):
		push_error("G0 wash narration did not use the mirror's right-side safe area.")
		quit(1)
		return

	story.call("start_at", 0, 10)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "cats"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.62
		or center_line.anchor_top < 0.36
		or center_line.text != "滚滚和糖糖也变得没那么活泼爱动了。"
	):
		push_error(
			(
				"G0 cats narration missed its safe area: visual=%s, left=%.3f, "
				+ "top=%.3f, max_line=%d, text=%s"
			) % [
				str(opening_director.get("current_visual_id")),
				center_line.anchor_left,
				center_line.anchor_top,
				_max_line_length(center_line.text),
				center_line.text.replace("\n", " / "),
			]
		)
		quit(1)
		return

	story.call("start_at", 0, 14)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "board"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.38
	):
		push_error("G0 boarding narration did not use the garage's left-side safe area.")
		quit(1)
		return

	story.call("start_at", 0, 17)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "drive"
		or opening_texture.texture == null
		or center_line.anchor_left < 0.56
		or center_line.text != "通勤，上班，赚钱，好好过日子，\n业余还能有时间做自己的爱好。"
	):
		push_error("G0 commute narration did not use the dark dashboard safe area.")
		quit(1)
		return
	story.call("start_at", 0, 18)
	await process_frame
	if (
		center_line.text != "在这个年龄，在这个公司，T11这个职级，\n理论上是很安全的。"
		or not _label_text_fits(center_line)
	):
		push_error("G0 T11 narration exceeded the widened dashboard caption area.")
		quit(1)
		return

	story.call("start_at", 0, 20)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "black"
		or opening_texture.visible
		or not center_line.visible
		or center_line.text != "我不明白。"
	):
		push_error("G0 did not cut directly to the returning dream line.")
		quit(1)
		return

	story.call("start_at", 0, 21)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "arrive"
		or opening_texture.texture == null
		or center_line.anchor_right > 0.41
		or center_line.text != "是啊，进入社会已经十二年了，\n也经历过许多事情。"
	):
		push_error("G0 company-arrival narration did not use the left-side garage safe area.")
		quit(1)
		return

	story.call("start_at", 5, 0)
	await process_frame
	if (
		not (scene.get_node("DialoguePanel") as Control).visible
		or (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G1-06 scene monologue is not presented from the on-screen character.")
		quit(1)
		return

	var master_texture := scene.get_node("MasterTexture") as TextureRect
	var dialogue_panel := scene.get_node("DialoguePanel") as PanelContainer
	var dialogue_tail := scene.get_node("DialogueTail") as Polygon2D
	var speaker_label := scene.get_node(
		"DialoguePanel/DialogueMargin/DialogueBox/SpeakerLabel"
	) as Label
	var presenter := scene.get("dialogue_presenter") as RefCounted
	var body_label := presenter.get("body_label") as Label
	var reverse_split := scene.get_node("ChapterFxLayer/G1ReverseSplit") as Control

	story.call("start_at", 1, 0)
	await process_frame
	if (
		master_texture.texture == null
		or dialogue_panel.position.x < 440.0
		or dialogue_panel.position.x > 500.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
		or not str((scene.get("dialogue_presenter") as RefCounted).get("current_text")).contains("\n")
	):
		push_error("G1-02 did not use the fixed tailless dialogue card.")
		quit(1)
		return
	var g1_02_position := dialogue_panel.position
	var g1_02_size := dialogue_panel.size
	story.call("start_at", 1, 1)
	await process_frame
	(scene.get("dialogue_presenter") as RefCounted).call("advance_page")
	await process_frame
	if (
		not dialogue_panel.position.is_equal_approx(g1_02_position)
		or not dialogue_panel.size.is_equal_approx(g1_02_size)
	):
		push_error("G1-02 dialogue card moved between pages while the CG stayed fixed.")
		quit(1)
		return

	story.call("start_at", 2, 0)
	await process_frame
	if (
		master_texture.texture == null
		or opening_texture.visible
		or dialogue_panel.position.x > 100.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-03 did not use the fixed upper-left dialogue card.")
		quit(1)
		return
	story.call("start_at", 2, 3)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-03 did not add the professional-smile reflection on its final line.")
		quit(1)
		return

	story.call("start_at", 3, 0)
	await process_frame
	if (
		opening_texture.visible
		or not is_equal_approx(dialogue_panel.position.x, 1220.0)
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-04 did not begin with the tailless camera-addressed pixel card.")
		quit(1)
		return
	story.call("start_at", 3, 3)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-04 did not switch to the thumbs-up CG between lines three and four.")
		quit(1)
		return

	story.call("start_at", 4, 0)
	await process_frame
	if not reverse_split.visible or not center_line.visible:
		push_error("G1-05 did not show the desaturated work/creation reverse split.")
		quit(1)
		return

	story.call("start_at", 5, 0)
	await process_frame
	if (
		opening_texture.visible
		or dialogue_panel.position.x > 100.0
		or dialogue_tail.visible
		or not dialogue_panel.size.is_equal_approx(Vector2(620.0, 158.0))
	):
		push_error("G1-06 did not begin with the fixed left dialogue card.")
		quit(1)
		return
	story.call("start_at", 5, 5)
	await process_frame
	if not opening_texture.visible or opening_texture.texture == null:
		push_error("G1-06 did not open the protagonist's eyes for the final line.")
		quit(1)
		return

	var asset_placeholder := scene.get_node("AssetPlaceholder") as CenterContainer
	var placeholder_label := scene.get_node(
		"AssetPlaceholder/PlaceholderLabel"
	) as Label
	story.call("start_at", 7, 0)
	await process_frame
	var chapter_two_director := scene.get("active_chapter_director") as RefCounted
	if (
		chapter_two_director == null
		or int(chapter_two_director.get("chapter_number")) != 2
		or str(chapter_two_director.get("current_shot_id")) != "SHOT-06"
		or master_texture.texture == null
		or asset_placeholder.visible
		or not center_line.visible
		or center_line.anchor_left > 0.07
	):
		push_error("G2-02 did not begin on the SHOT-06 trial master with the chapter-two caption layout.")
		quit(1)
		return
	story.call("start_at", 7, 2)
	await process_frame
	if (
		str(chapter_two_director.get("current_shot_id")) != "SHOT-22"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G2-02 did not switch from SHOT-06 to the independent SHOT-22 trial master.")
		quit(1)
		return
	story.call("start_at", 7, 3)
	await process_frame
	if (
		not dialogue_panel.visible
		or dialogue_tail.visible
		or speaker_label.visible
		or not dialogue_panel.position.is_equal_approx(Vector2(1260.0, 450.0))
	):
		push_error("G2 spoken dialogue did not use the speaker's tailless spatial card.")
		quit(1)
		return
	var g2_member_a_position := dialogue_panel.position
	story.call("start_at", 7, 4)
	await process_frame
	if (
		speaker_label.visible
		or not dialogue_panel.position.is_equal_approx(Vector2(650.0, 760.0))
		or dialogue_panel.position.is_equal_approx(g2_member_a_position)
	):
		push_error("G2 did not move the content-only card from member A to the protagonist.")
		quit(1)
		return
	story.call("start_at", 7, 5)
	await process_frame
	if (
		speaker_label.visible
		or not dialogue_panel.position.is_equal_approx(Vector2(490.0, 40.0))
	):
		push_error("G2 did not anchor member B's content-only card to member B.")
		quit(1)
		return
	story.call("start_at", 7, 9)
	await process_frame
	if (
		speaker_label.visible
		or not dialogue_panel.position.is_equal_approx(Vector2(1040.0, 370.0))
	):
		push_error("G2 did not anchor member C's card beside member C.")
		quit(1)
		return
	story.call("start_at", 8, 5)
	await process_frame
	if (
		str(chapter_two_director.get("current_shot_id")) != "SHOT-23"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G2-03 did not switch from the birthday scene to the Kexing scene.")
		quit(1)
		return
	story.call("start_at", 8, 10)
	await process_frame
	if (
		str(chapter_two_director.get("current_shot_id")) != "SHOT-24"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G2-03 did not switch to the independent launch-without-me scene.")
		quit(1)
		return

	story.call("start_at", 12, 0)
	await process_frame
	var chapter_three_director := scene.get("active_chapter_director") as RefCounted
	if (
		chapter_three_director == null
		or int(chapter_three_director.get("chapter_number")) != 3
		or str(chapter_three_director.get("current_shot_id")) != "SHOT-42"
		or master_texture.texture == null
		or asset_placeholder.visible
		or not center_line.visible
		or center_line.anchor_left > 0.05
	):
		push_error("G3 did not begin on the independent no-Agent master with a safe unboxed caption.")
		quit(1)
		return
	story.call("start_at", 12, 2)
	await process_frame
	if (
		not dialogue_panel.visible
		or dialogue_tail.visible
		or speaker_label.visible
		or str(chapter_three_director.get("current_shot_id")) != "SHOT-32"
		or not dialogue_panel.position.is_equal_approx(Vector2(60.0, 520.0))
		or dialogue_panel.size.x < 537.0
		or not is_equal_approx(dialogue_panel.size.y, 158.0)
		or body_label.text != "我是 Poros，负责你的钱，\n也负责你对失去安全感的恐惧。"
	):
		push_error("G3 Poros dialogue did not use its content-only spatial card.")
		quit(1)
		return
	story.call("start_at", 12, 19)
	await process_frame
	if (
		body_label.text != "我会整理、筛选和投稿，\n让每一张真正完成的作品，\n都有机会被人看见。"
		or not is_equal_approx(dialogue_panel.size.y, 196.0)
	):
		push_error("G3 reviewed three-line dialogue did not receive a three-line card.")
		quit(1)
		return
	story.call("start_at", 12, 17)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-37"
		or not dialogue_panel.position.is_equal_approx(Vector2(1280.0, 40.0))
	):
		push_error("G3 Nostos dialogue did not use the right wall safe area.")
		quit(1)
		return
	story.call("start_at", 12, 20)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-38"
		or master_texture.texture == null
		or asset_placeholder.visible
		or dialogue_tail.visible
		or not dialogue_panel.position.is_equal_approx(Vector2(1300.0, 40.0))
	):
		push_error("G3 did not enter Ousia's flower sea with her anchored dialogue card.")
		quit(1)
		return

	story.call("start_at", 13, 0)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-09"
		or master_texture.texture == null
		or asset_placeholder.visible
		or center_line.anchor_top > 0.04
	):
		push_error("G3 flower-sea prelude did not use the upper caption safe area.")
		quit(1)
		return

	story.call("start_at", 14, 0)
	await process_frame
	var glare_overlay := scene.get_node("ChapterFxLayer/G3GlareOverlay") as ColorRect
	var g3_03_bubble_position := Vector2(
		minf(1300.0, 1880.0 - dialogue_panel.size.x),
		40.0,
	)
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-09"
		or master_texture.texture == null
		or asset_placeholder.visible
		or glare_overlay.visible
		or not dialogue_panel.visible
		or not dialogue_panel.position.is_equal_approx(g3_03_bubble_position)
	):
		push_error("G3-03 did not keep its opening probability dialogue in the flower sea.")
		quit(1)
		return

	story.call("start_at", 14, 2)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-10"
		or master_texture.texture == null
		or asset_placeholder.visible
		or not glare_overlay.visible
		or not center_line.visible
		or center_line.anchor_top < 0.66
	):
		push_error("G3 ceiling-light shot did not wait for the line that names the ceiling light.")
		quit(1)
		return

	story.call("start_at", 14, 3)
	await process_frame
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	var evidence_overlay := scene.get_node("ChapterFxLayer/G3EvidenceOverlay") as ColorRect
	var evidence_flash := evidence_overlay.get_node("HitFlash") as ColorRect
	var evidence_fragments := evidence_overlay.get_node("MemoryIndexFragments") as Control
	if (
		not evidence_overlay.visible
		or evidence_overlay.material == null
		or evidence_flash == null
		or evidence_fragments == null
		or evidence_fragments.get_child_count() < 20
		or center_line.visible
		or not bool(music_director.call("is_cue_active", "MUS-05A"))
	):
		push_error("G3 did not insert the staged twenty-second memory-search field after the cue line.")
		quit(1)
		return
	scene.call("_advance_story")
	await process_frame
	if (
		evidence_overlay.visible
		or int(story.get("line_index")) != 4
		or not bool(music_director.call("is_cue_active", "MUS-05B"))
	):
		push_error("G3 evidence placeholder could not be skipped into the retrieved quote.")
		quit(1)
		return

	story.call("start_at", 17, 1)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-41"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G3 crying beat did not switch to the independent embrace master.")
		quit(1)
		return
	story.call("start_at", 17, 5)
	await process_frame
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-11"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G3 did not return from the embrace to the blank-page master.")
		quit(1)
		return

	story.call("start_at", 18, 0)
	await process_frame
	var chapter_four_director := scene.get("active_chapter_director") as RefCounted
	var voice_sequence_player := scene.get("voice_sequence_player") as Node
	var g4_paper_reveal := scene.get_node("ChapterFxLayer/G4PaperFrame") as Control
	var g4_paper_signature := scene.get_node("ChapterFxLayer/G4PaperSignature") as Label
	var g4_time_marker := scene.get_node("ChapterFxLayer/G4TimeMarker") as Control
	var g4_time_marker_label := g4_time_marker.get_child(0) as Label
	if (
		chapter_four_director == null
		or int(chapter_four_director.get("chapter_number")) != 4
		or str(chapter_four_director.get("current_shot_id")) != "SHOT-12"
		or str(chapter_four_director.get("current_variant_id")) != "outward"
		or (scene.get_node("DialoguePanel") as Control).visible
		or (scene.get_node("CenterLine") as Control).visible
		or master_texture.texture == null
		or asset_placeholder.visible
		or not g4_paper_reveal.visible
		or not g4_paper_signature.visible
		or g4_time_marker.visible
		or not bool(voice_sequence_player.call("is_active"))
	):
		push_error("G4-01 did not begin with the paper reveal and timed original soundtrack.")
		quit(1)
		return
	voice_sequence_player.call("seek", 3.02)
	await process_frame
	if not (scene.get_node("CenterLine") as Control).visible:
		push_error("G4-01 first subtitle did not follow the original soundtrack cue.")
		quit(1)
		return
	voice_sequence_player.call("seek", 12.50)
	await process_frame
	if (
		int(story.get("line_index")) != 2
		or str(chapter_four_director.get("current_variant_id")) != "mountains"
		or not (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G4-01 soundtrack did not advance subtitles and imagery without input.")
		quit(1)
		return
	voice_sequence_player.call("seek", 56.52)
	await process_frame
	if (
		int(story.get("unit_index")) != 18
		or not bool(chapter_four_director.get("age_jump_active"))
		or not bool(voice_sequence_player.call("is_active"))
		or not str(music_director.get("active_cue_id")).is_empty()
	):
		push_error("G4-01 did not begin the synchronized audio-visual fade at its final cue.")
		quit(1)
		return
	await create_timer(3.60).timeout
	if (
		int(story.get("unit_index")) != 19
		or int(story.get("line_index")) != 0
		or bool(voice_sequence_player.call("is_active"))
		or str(music_director.get("active_cue_id")) != "MUS-07B"
		or str(chapter_four_director.get("current_shot_id")) != "SHOT-13"
		or bool(chapter_four_director.get("age_jump_active"))
	):
		push_error(
			"G4-01 age-jump completion mismatch: unit=%d line=%d voice=%s cue=%s shot=%s active=%s."
			% [
				int(story.get("unit_index")),
				int(story.get("line_index")),
				voice_sequence_player.call("is_active"),
				music_director.get("active_cue_id"),
				chapter_four_director.get("current_shot_id"),
				chapter_four_director.get("age_jump_active"),
			]
		)
		quit(1)
		return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if int(story.get("line_index")) != 1:
		push_error("G4-02 did not restore player input after the age-jump reveal.")
		quit(1)
		return
	story.call("start_at", 18, 2)
	await process_frame
	if str(chapter_four_director.get("current_variant_id")) != "mountains" or master_texture.texture == null:
		push_error("G4-01 did not switch to the selected mountains phase.")
		quit(1)
		return
	story.call("start_at", 18, 4)
	await process_frame
	if str(chapter_four_director.get("current_variant_id")) != "pleasure" or master_texture.texture == null:
		push_error("G4-01 did not switch to the selected pleasure phase.")
		quit(1)
		return
	story.call("start_at", 18, 6)
	await process_frame
	if (
		str(chapter_four_director.get("current_variant_id")) != "return"
		or master_texture.texture == null
		or g4_time_marker.visible
	):
		push_error("G4-01 did not switch to the selected return phase.")
		quit(1)
		return
	story.call("start_at", 19, 0)
	await process_frame
	if (
		chapter_four_director == null
		or int(chapter_four_director.get("chapter_number")) != 4
		or str(chapter_four_director.get("current_shot_id")) != "SHOT-13"
		or master_texture.texture == null
		or asset_placeholder.visible
		or (scene.get_node("DialoguePanel") as Control).visible
		or not (scene.get_node("CenterLine") as Control).visible
		or not g4_time_marker.visible
		or not g4_time_marker_label.text.contains("三十三岁")
		or not g4_time_marker_label.text.contains("2026")
		or g4_time_marker_label.text.contains("两年后")
	):
		push_error("G4-02 did not identify the two-year jump over its opening caption.")
		quit(1)
		return
	story.call("start_at", 19, 2)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-62"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-02 did not switch to the accepted Dawn reveal master.")
		quit(1)
		return
	story.call("start_at", 20, 8)
	await process_frame
	var g4_reviewed_segments := presenter.get("current_segments") as Array
	if (
		g4_reviewed_segments.size() != 2
		or str(g4_reviewed_segments[0]) != "我没有在摄影中逃离创作。"
		or str(g4_reviewed_segments[1]) != "我只是在另一个媒介上，开始用画面、\n声音和真实的时间继续写作。"
		or center_line.text != "我没有在摄影中逃离创作。"
	):
		push_error("G4-03 did not preserve the reviewed page and line-break structure.")
		quit(1)
		return
	story.call("start_at", 19, 3)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-43"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-02 did not switch to the accepted Tengger sunset master.")
		quit(1)
		return
	story.call("start_at", 20, 0)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-14"
		or master_texture.texture == null
		or asset_placeholder.visible
		or g4_time_marker.visible
	):
		push_error("G4-03 did not load the generated planning master.")
		quit(1)
		return
	story.call("start_at", 20, 4)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-53"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-03 did not switch from its placeholder to the accepted field master.")
		quit(1)
		return
	story.call("start_at", 20, 8)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-55"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-03 did not load the generated monitor-viewing master.")
		quit(1)
		return
	story.call("start_at", 21, 0)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-15"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-04 did not begin on the accepted Shenzhen garage departure master.")
		quit(1)
		return
	if not is_equal_approx(float(scene.call("_current_auto_wait_seconds")), 5.27):
		push_error("G4-04 did not apply its chapter-specific auto-play breathing room.")
		quit(1)
		return
	story.call("start_at", 21, 2)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-56"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-04 did not load the accepted snow arrival master.")
		quit(1)
		return
	story.call("start_at", 21, 4)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-58"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-04 did not load the generated farewell master.")
		quit(1)
		return
	story.call("start_at", 22, 0)
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-16"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G4-05 did not begin on the generated fixed-camera sunset variant.")
		quit(1)
		return
	story.call("start_at", 22, 2)
	await process_frame
	if master_texture.texture == null or asset_placeholder.visible:
		push_error("G4-05 did not advance to the generated stars variant.")
		quit(1)
		return
	story.call("start_at", 22, 4)
	await process_frame
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-61"
		or not bool(chapter_four_director.get("descent_active"))
		or not bool(music_director.call("is_cue_active", "MUS-08B"))
		or master_texture.texture == null
		or asset_placeholder.visible
		or (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G4-05 did not keep MUS-08B across the generated night descent.")
		quit(1)
		return

	scene.call("_advance_story")
	await process_frame
	var fading_player_count := 0
	for player_variant in music_director.get("players") as Array:
		if (player_variant as AudioStreamPlayer).playing:
			fading_player_count += 1
	if (
		not bool(scene.get("chapter_transition_pending"))
		or bool(scene.get("chapter_interlude_active"))
		or not str(music_director.get("active_cue_id")).is_empty()
		or fading_player_count == 0
	):
		push_error("G4 to G5 did not fade the old BGM before opening the chapter card.")
		quit(1)
		return
	scene.call("_finish_chapter_music_fade")
	await process_frame
	var chapter_interlude := scene.get_node("ChapterInterludeOverlay") as Control
	var chapter_number := scene.get_node(
		"ChapterInterludeOverlay/ChapterNumber"
	) as Label
	var chapter_title := scene.get_node(
		"ChapterInterludeOverlay/ChapterTitle"
	) as Label
	var chapter_backdrop := scene.get_node(
		"ChapterInterludeOverlay/Backdrop"
	) as TextureRect
	if (
		not bool(scene.get("chapter_interlude_active"))
		or not chapter_interlude.visible
		or chapter_number.text != "第五章"
		or chapter_title.text != "主动失去"
		or chapter_backdrop.texture == null
		or (scene.get_node("DialoguePanel") as Control).visible
		or (scene.get_node("CenterLine") as Control).visible
	):
		push_error("G4 to G5 did not stage the designed chapter interlude over the night road.")
		quit(1)
		return
	scene.call("_finish_chapter_interlude")
	await process_frame
	var chapter_five_director := scene.get("active_chapter_director") as RefCounted
	if (
		chapter_five_director == null
		or int(chapter_five_director.get("chapter_number")) != 5
		or str(chapter_five_director.get("current_shot_id")) != "SHOT-17"
		or str(chapter_five_director.get("current_variant_id")) != "fog"
		or master_texture.texture == null
		or asset_placeholder.visible
		or not bool(scene.get("chapter_music_delay_active"))
		or not str(music_director.get("active_cue_id")).is_empty()
	):
		push_error("G5-01 did not reveal the fog scene before its delayed BGM entry.")
		quit(1)
		return
	scene.call("_finish_chapter_music_delay")
	await process_frame
	if not bool(music_director.call("is_cue_active", "MUS-09A")):
		push_error("G5-01 BGM did not enter after the post-interlude delay.")
		quit(1)
		return
	story.call("start_at", 23, 3)
	await process_frame
	if str(chapter_five_director.get("current_variant_id")) != "fog":
		push_error("G5-01 did not hold the expanded opening across four fog lines.")
		quit(1)
		return
	story.call("start_at", 23, 4)
	await process_frame
	if str(chapter_five_director.get("current_variant_id")) != "wide":
		push_error("G5-01 did not advance from fog to the turbine wide state.")
		quit(1)
		return
	story.call("start_at", 23, 8)
	await process_frame
	if str(chapter_five_director.get("current_variant_id")) != "sunrise_back":
		push_error("G5-01 did not enter the merged sunrise-back state.")
		quit(1)
		return
	story.call("start_at", 23, 12)
	await process_frame
	if str(chapter_five_director.get("current_variant_id")) != "sunrise_back":
		push_error("G5-01 did not finish on the merged sunrise-back state.")
		quit(1)
		return

	story.call("start_at", 24, 0)
	await process_frame
	var links_placeholder := scene.get_node("ChapterFxLayer/G5LinksPlaceholder") as Control
	if (
		str(chapter_five_director.get("current_shot_id")) != "SHOT-18"
		or master_texture.texture == null
		or links_placeholder.visible
		or asset_placeholder.visible
		or (scene.get_node("DialoguePanel") as Control).visible
		or not center_line.visible
	):
		push_error("G5-02 did not begin on the sofa-and-snow-screen master.")
		quit(1)
		return
	if not is_equal_approx(float(scene.call("_current_auto_wait_seconds")), 5.95):
		push_error("G5-02 did not apply its reflective auto-play breathing room.")
		quit(1)
		return
	story.call("start_at", 24, 2)
	await process_frame
	if (
		str(chapter_five_director.get("current_shot_id")) != "SHOT-70"
		or str(chapter_five_director.get("current_variant_id")) != "wide"
		or master_texture.texture == null
		or links_placeholder.visible
		or asset_placeholder.visible
	):
		push_error("G5-02 did not cut from borrowed imagery to the ruin wide state.")
		quit(1)
		return
	story.call("start_at", 24, 3)
	await process_frame
	if (
		str(chapter_five_director.get("current_shot_id")) != "SHOT-70"
		or str(chapter_five_director.get("current_variant_id")) != "glass"
		or master_texture.texture == null
	):
		push_error("G5-02 did not switch to the broken-glass reflection state.")
		quit(1)
		return

	story.call("start_at", 25, 0)
	await process_frame
	if str(chapter_five_director.get("current_shot_id")) != "SHOT-71" or master_texture.texture == null:
		push_error("G5-03 did not begin on the selected desert recovery master.")
		quit(1)
		return
	story.call("start_at", 25, 2)
	await process_frame
	if str(chapter_five_director.get("current_shot_id")) != "SHOT-72" or master_texture.texture == null:
		push_error("G5-03 did not switch to the integrated damage assessment master.")
		quit(1)
		return
	story.call("start_at", 25, 3)
	await process_frame
	if str(chapter_five_director.get("current_shot_id")) != "SHOT-75" or master_texture.texture == null:
		push_error("G5-03 did not switch to the adverse-weather Huangzaoding road master.")
		quit(1)
		return
	story.call("start_at", 25, 4)
	await process_frame
	if (
		str(chapter_five_director.get("current_shot_id")) != "SHOT-76"
		or master_texture.texture == null
		or asset_placeholder.visible
	):
		push_error("G5-03 did not enter the selected H-LOOK-01 sinkhole master.")
		quit(1)
		return

	story.call("start_at", 26, 0)
	await process_frame
	if str(chapter_five_director.get("current_shot_id")) != "SHOT-73" or master_texture.texture == null:
		push_error("G5-04 did not begin on the selected beach-and-lighthouse master.")
		quit(1)
		return
	story.call("start_at", 26, 2)
	await process_frame
	if (
		str(chapter_five_director.get("current_shot_id")) != "SHOT-74"
		or str(chapter_five_director.get("current_variant_id")) != "lantern"
		or master_texture.texture == null
	):
		push_error("G5-04 did not enter the moon, green beacon and probing-lantern state.")
		quit(1)
		return
	story.call("start_at", 27, 2)
	await process_frame
	if (
		str(chapter_five_director.get("current_variant_id")) != "empty"
		or master_texture.texture == null
		or not center_line.visible
	):
		push_error("G5-05 did not dissolve to the clean lighthouse plate for central text.")
		quit(1)
		return

	var longest := _find_longest_bubble(story.get("units") as Array)
	story.call(
		"start_at",
		int(longest.get("unit_index", 0)),
		int(longest.get("line_index", 0)),
	)
	await process_frame
	if not (scene.get_node("DialoguePanel") as Control).visible:
		push_error("Dialogue bubble is hidden for a spoken line.")
		quit(1)
		return
	var current_line := story.call("get_current_line") as Dictionary
	if str(current_line.get("text", "")).length() != int(longest.get("length", 0)):
		push_error("Longest bubble line was not loaded correctly.")
		quit(1)
		return
	var segments := presenter.get("current_segments") as Array
	if segments.size() < 2:
		push_error("Longest dialogue was not divided into compact visual beats.")
		quit(1)
		return
	for segment in segments:
		if _max_line_length(str(segment)) > 26:
			push_error("A dialogue bubble segment exceeds the visual limit.")
			quit(1)
			return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if int(presenter.get("current_segment_index")) != 1:
		push_error("Advancing a paginated line skipped directly to the next dialogue.")
		quit(1)
		return

	story.call("start_at", 27, 3)
	await process_frame
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	chapter_five_director = scene.get("active_chapter_director") as RefCounted
	if (
		chapter_five_director == null
		or not bool(chapter_five_director.get("final_hold_active"))
		or not str(music_director.get("active_cue_id")).is_empty()
		or str(chapter_five_director.get("current_variant_id")) != "empty"
		or center_line.visible
		or (scene.get_node("EndingOverlay") as Control).visible
	):
		push_error("G5 did not insert the silent, textless lighthouse hold after the final line.")
		quit(1)
		return
	chapter_five_director.set(
		"final_hold_started_at_msec",
		Time.get_ticks_msec() - 3000,
	)
	scene.call("_advance_story")
	await process_frame
	if not (scene.get_node("EndingOverlay") as Control).visible:
		push_error("Story did not reach the ending after the final lighthouse hold.")
		quit(1)
		return

	print(
		"Smoke test passed: current script, six G0 CGs, seven G1 CGs, "
		+ "sixteen G2 trial masters with line-level shot switching, semantic dialogue beats, shot variants, "
		+ "fourteen G3 masters with an independent opening, safe Ousia staging and a staged memory-search field, "
		+ "twenty-seven G4 runtime packages, paper-revealed timed G4-01 voiceover, four staged SHOT-12 phases, staged sky phases and scored descent, "
		+ "thirteen G5 runtime states across nine packages, chapter interludes with music pre-fades and delayed entries, staged final imagery and a silent lighthouse hold, "
		+ "timed soundtrack fades, age-jump handoffs, reverse split, core UI, and ending flow."
	)
	quit(0)


func _find_longest_bubble(units: Array) -> Dictionary:
	var result := {
		"unit_index": 0,
		"line_index": 0,
		"length": 0,
	}
	for unit_index in range(units.size()):
		var unit := units[unit_index] as Dictionary
		var lines := unit.get("lines", []) as Array
		for line_index in range(lines.size()):
			var line := lines[line_index] as Dictionary
			if str(line.get("presentation", "")) != "bubble":
				continue
			var length := str(line.get("text", "")).length()
			if length > int(result["length"]):
				result = {
					"unit_index": unit_index,
					"line_index": line_index,
					"length": length,
				}
	return result


func _max_line_length(text: String) -> int:
	var longest := 0
	for line in text.split("\n"):
		longest = maxi(longest, line.length())
	return longest


func _label_text_fits(label: Label) -> bool:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	for line in label.text.split("\n"):
		var line_width := font.get_string_size(
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			font_size,
		).x
		if line_width > label.size.x:
			return false
	return true
