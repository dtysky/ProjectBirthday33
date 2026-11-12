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
		"TitleOverlay",
		"HistoryOverlay",
		"SettingsOverlay",
		"ChapterFxLayer/OpeningBackdrop",
		"ChapterFxLayer/OpeningPreviousTexture",
		"ChapterFxLayer/OpeningTexture",
		"ChapterFxLayer/OpeningPlaceholder",
		"ChapterFxLayer/DreamDoorWhiteout",
		"ChapterFxLayer/DreamLossTransition",
		"ChapterFxLayer/DreamMemoryVeil",
		"ChapterFxLayer/DreamMemoryEcho",
		"ChapterFxLayer/DreamEyelids",
		"ChapterFxLayer/G1ReverseSplit",
		"ChapterFxLayer/G3GlareOverlay",
		"ChapterFxLayer/G3TransitionOverlay",
		"ChapterFxLayer/G3EvidenceOverlay",
		"ChapterFxLayer/G4TransitionTexture",
		"ChapterFxLayer/G4PaperFrame",
		"ChapterFxLayer/G4TimeMarker",
		"ChapterFxLayer/G4ReplayFrame",
		"ChapterFxLayer/G5TransitionTexture",
		"ChapterFxLayer/G5LinksPlaceholder",
		"ChapterFxLayer/G5TransitionOverlay",
		"ChapterFxLayer/G5EndingOcean",
		"ChapterFxLayer/G5EndingBeaconGlow",
		"ChapterFxLayer/G5EndingWalkAnchor",
		"ChapterFxLayer/G5EndingWalkAnchor/G5EndingWalkBob/G5EndingPerson",
		"ChapterFxLayer/G5EndingWalkAnchor/G5EndingWalkBob/G5EndingLantern",
		"ChapterFxLayer/G5EndingWalkAnchor/G5EndingWalkBob/G5EndingLanternGlow",
		"G3EvidenceTimer",
		"MusicDirector/MusicPlayerA",
		"MusicDirector/MusicPlayerB",
		"VoiceSequencePlayer/VoiceTrack",
		"TitleOverlay/TitleBackdropVideo",
		"TitleSeaWind",
		"G0WindAmbience",
	]
	for node_name in required:
		if scene.get_node_or_null(node_name) == null:
			push_error("Missing runtime node: %s" % node_name)
			quit(1)
			return
	var title_wind := scene.get_node("TitleSeaWind") as AudioStreamPlayer
	if not title_wind.playing or title_wind.stream == null:
		push_error("Title sea-wind ambience did not start with the title screen.")
		quit(1)
		return

	if scene.get_node_or_null("TitleOverlay/TitleContent/AutoPlayButton") != null:
		push_error("Recording auto-play must not be exposed on the title screen.")
		quit(1)
		return
	if scene.get_node_or_null("MenuButton") != null:
		push_error("The retired bottom-right menu entry is still present.")
		quit(1)
		return

	scene.call("_start_new_game")
	await process_frame
	if (
		bool(scene.get("is_auto"))
		or bool(scene.get("recording_auto_mode"))
		or (scene.get_node("TitleOverlay") as Control).visible
		or int((scene.get("story") as RefCounted).get("line_index")) != 0
	):
		push_error("A normal game start unexpectedly enabled recording auto-play.")
		quit(1)
		return
	scene.call("_toggle_recording_auto_mode")
	await process_frame
	if (
		not bool(scene.get("is_auto"))
		or not bool(scene.get("recording_auto_mode"))
	):
		push_error("F9 recording auto-play did not start from the current game line.")
		quit(1)
		return
	scene.call("_on_voice_sequence_finished", "", false, false)
	var recording_auto_timer := scene.get("auto_timer") as Timer
	if (
		recording_auto_timer.is_stopped()
		or not is_equal_approx(recording_auto_timer.wait_time, 0.816)
	):
		push_error("Recording auto-play did not use the shortened post-voice pause.")
		quit(1)
		return
	scene.call("_toggle_recording_auto_mode")
	await process_frame
	if (
		bool(scene.get("is_auto"))
		or bool(scene.get("recording_auto_mode"))
	):
		push_error("F9 recording auto-play did not stop cleanly.")
		quit(1)
		return
	scene.call("_return_to_title")
	await process_frame

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
	var sound_director := scene.get("sound_director") as Node
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
	var opening_previous_texture := scene.get_node(
		"ChapterFxLayer/OpeningPreviousTexture"
	) as TextureRect
	var opening_placeholder := scene.get_node(
		"ChapterFxLayer/OpeningPlaceholder"
	) as Label
	var dream_whiteout := scene.get_node(
		"ChapterFxLayer/DreamDoorWhiteout"
	) as ColorRect
	var dream_loss_transition := scene.get_node(
		"ChapterFxLayer/DreamLossTransition"
	) as ColorRect
	var center_line := scene.get_node("CenterLine") as Label
	var dream_eyelids := scene.get_node(
		"ChapterFxLayer/DreamEyelids"
	) as ColorRect
	var dream_memory_veil := scene.get_node(
		"ChapterFxLayer/DreamMemoryVeil"
	) as ColorRect
	var dream_memory_echo := scene.get_node(
		"ChapterFxLayer/DreamMemoryEcho"
	) as Label
	var dream_final_answer := scene.get_node(
		"ChapterFxLayer/DreamFinalAnswer"
	) as Control
	var dream_final_answer_line := scene.get_node(
		"ChapterFxLayer/DreamFinalAnswer/UnfinishedLine"
	) as ColorRect
	var dream_wind := scene.get_node("G0WindAmbience") as AudioStreamPlayer
	if (
		str(opening_director.get("current_visual_id")) != "black"
		or opening_placeholder.visible
		or opening_texture.visible
		or opening_previous_texture.visible
		or center_line.visible
		or dream_wind.playing
		or not _any_event_is_playing(sound_director)
		or music_director.call("is_cue_active", "MUS-03C")
	):
		push_error("G0 did not begin on opening-howl black before its score.")
		quit(1)
		return
	await create_timer(2.35).timeout
	if (
		int(story.get("line_index")) != 0
		or str(opening_director.get("current_visual_id")) != "dream_pov_wake"
		or not opening_texture.visible
		or opening_texture.texture == null
		or not dream_eyelids.visible
		or center_line.visible
		or title_wind.playing
		or music_director.call("is_cue_active", "MUS-03C")
	):
		push_error("G0 did not enter its silent first-person eye-opening shot.")
		quit(1)
		return
	await create_timer(3.0).timeout
	if (
		int(story.get("line_index")) != 0
		or str(opening_director.get("current_visual_id")) != "dream_wake"
		or not opening_texture.visible
		or not center_line.visible
		or dream_eyelids.visible
		or not music_director.call("is_cue_active", "MUS-03C")
	):
		push_error("G0 did not start dialogue and MUS-03C after the POV shot.")
		quit(1)
		return
	await create_timer(0.65).timeout
	if not dream_wind.playing:
		push_error("The sustained rooftop wind did not follow the opening howl.")
		quit(1)
		return

	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.30).timeout
	if (
		int(story.get("line_index")) != 1
		or str(opening_director.get("current_visual_id")) != "dream_wake"
		or center_line.text != "奇怪，头疼。\n呃……我这是在哪？"
	):
		push_error("G0 wake state did not preserve its second dialogue beat.")
		quit(1)
		return

	story.call("start_at", 0, 2)
	var bell_prelude_deadline := Time.get_ticks_msec() + 8000
	while (
		bool(opening_director.get("prelude_locked"))
		and Time.get_ticks_msec() < bell_prelude_deadline
	):
		await create_timer(0.05).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_loss"
		or opening_previous_texture.visible
		or dream_loss_transition.visible
		or center_line.text != "钟声？又是一次审判吗？\n审判谁？谁来审判？"
	):
		push_error("G0 bell transition did not settle cleanly into the judgment line.")
		quit(1)
		return

	story.call("start_at", 0, 6)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "dream_shadow"
		or center_line.anchor_left < 0.54
	):
		push_error("G0 shadow voice did not use the right-side shadow composition.")
		quit(1)
		return

	story.call("start_at", 0, 8)
	await create_timer(2.05).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_youth_close"
		or not center_line.visible
		or bool(opening_director.get("prelude_locked"))
	):
		push_error("G0 youth reveal did not complete automatically before the close-up line.")
		quit(1)
		return

	story.call("start_at", 0, 11)
	await create_timer(1.25).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_adult_reaction"
		or not dream_memory_veil.visible
		or not dream_memory_echo.visible
		or not center_line.visible
		or not is_equal_approx(center_line.anchor_left, 0.5)
		or not is_equal_approx(center_line.anchor_right, 0.5)
		or center_line.offset_left >= 0.0
		or center_line.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT
	):
		push_error("G0 recalled line did not enter its memory treatment.")
		quit(1)
		return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(2.15).timeout
	if (
		int(story.get("line_index")) != 12
		or str(opening_director.get("current_visual_id")) != "dream_confrontation"
		or dream_memory_veil.visible
		or dream_memory_echo.visible
		or not center_line.visible
	):
		push_error("G0 recalled line did not release back into the present confrontation.")
		quit(1)
		return

	story.call("start_at", 0, 10)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "dream_adult_reaction"
		or center_line.text != "……"
	):
		push_error("G0 adult reaction insert did not carry the silent response.")
		quit(1)
		return

	story.call("start_at", 0, 12)
	await create_timer(1.0).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_confrontation"
		or center_line.anchor_right > 0.46
	):
		push_error("G0 confrontation did not return to the adult-left two-shot.")
		quit(1)
		return

	story.call("start_at", 0, 15)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "dream_train_approach"
		or center_line.text != "因为你也不是曾经的那个你，"
	):
		push_error("G0 train approach did not begin beneath the choice line.")
		quit(1)
		return

	# Use normal same-unit progression so the approach shot remains beneath the whistle.
	story.call("advance")
	await create_timer(0.15).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_train_approach"
		or not bool(opening_director.get("prelude_locked"))
		or not sound_director.call("is_event_active", "G1-01-D17")
	):
		push_error(
			"G0 train whistle did not hold on the approach shot: visual=%s, locked=%s, active=%s."
			% [
				str(opening_director.get("current_visual_id")),
				str(opening_director.get("prelude_locked")),
				str(sound_director.call("is_event_active", "G1-01-D17")),
			]
		)
		quit(1)
		return
	var train_prelude_deadline := Time.get_ticks_msec() + 4000
	while (
		bool(opening_director.get("prelude_locked"))
		and Time.get_ticks_msec() < train_prelude_deadline
	):
		await create_timer(0.05).timeout
	if (
		str(opening_director.get("current_visual_id")) != "dream_train_stop"
		or not center_line.visible
	):
		push_error("G0 train did not arrive automatically before the final question.")
		quit(1)
		return

	story.call("start_at", 0, 17)
	await create_timer(0.40).timeout
	if not dream_whiteout.visible:
		push_error("G0 door light did not expand from the train before the cut to black.")
		quit(1)
		return
	await create_timer(1.60).timeout
	if (
		str(opening_director.get("current_visual_id")) != "black"
		or opening_texture.visible
		or center_line.visible
		or not dream_final_answer.visible
		or dream_final_answer_line.size.x < 150.0
	):
		push_error("G0 final whiteout did not resolve to the unfinished black-screen answer.")
		quit(1)
		return

	scene.call("_finish_typing")
	scene.call("_advance_story")
	await create_timer(0.95).timeout
	if (
		int(story.get("line_index")) != 17
		or str(opening_director.get("current_visual_id")) != "black"
		or not str(music_director.get("active_cue_id")).is_empty()
	):
		push_error("G0 ending did not hold on black while its music withdrew.")
		quit(1)
		return
	await create_timer(1.60).timeout
	if (
		int(story.get("line_index")) != 17
		or str(opening_director.get("current_visual_id")) != "wake"
		or opening_texture.texture == null
	):
		push_error("G0 ending did not reveal the birthday morning before its narration.")
		quit(1)
		return
	await create_timer(1.55).timeout
	if (
		int(story.get("line_index")) != 18
		or str(opening_director.get("current_visual_id")) != "wake"
		or opening_texture.texture == null
		or center_line.text != "2026 年 8 月 20 日。"
		or not music_director.call("is_cue_active", "MUS-03B")
	):
		push_error("G0 did not complete its buffered transition into the birthday morning.")
		quit(1)
		return
	var opening_beats := opening_director.get("current_beats") as Array
	if (
		opening_beats.size() != 2
		or str((opening_beats[0] as Dictionary).get("text", "")) != "2026 年 8 月 20 日。"
		or str((opening_beats[1] as Dictionary).get("text", "")) != "三十三岁的第一天。\n我似乎做了一个梦。"
	):
		push_error("G1-01 did not preserve the reviewed birthday-line pagination.")
		quit(1)
		return

	story.call("start_at", 0, 23)
	await process_frame
	if str(opening_director.get("current_visual_id")) != "wash":
		push_error("G0 reality sequence no longer reached its wash state.")
		quit(1)
		return

	story.call("start_at", 0, 27)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "cats"
		or center_line.text != "滚滚和糖糖也变得没那么活泼爱动了。"
	):
		push_error("G0 reality sequence no longer reached its cats state.")
		quit(1)
		return

	story.call("start_at", 0, 31)
	await process_frame
	if str(opening_director.get("current_visual_id")) != "board":
		push_error("G0 reality sequence no longer reached its boarding state.")
		quit(1)
		return

	story.call("start_at", 0, 34)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "drive"
		or center_line.text != "通勤，上班，赚钱，好好过日子，\n业余还能有时间做自己的爱好。"
	):
		push_error("G0 reality sequence no longer reached its commute state.")
		quit(1)
		return

	story.call("start_at", 0, 37)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "black"
		or center_line.text != "我不明白。"
		or opening_texture.visible
	):
		push_error("G0 restored callback line did not cut to black after the commute.")
		quit(1)
		return

	story.call("start_at", 0, 38)
	await process_frame
	if (
		str(opening_director.get("current_visual_id")) != "arrive"
		or center_line.text != "是啊，进入社会已经十二年了，\n也经历过许多事情。"
	):
		push_error("G0 company arrival did not follow the restored black-screen callback line.")
		quit(1)
		return

	story.call("start_at", 5, 0)
	await process_frame
	if (
		(scene.get_node("DialoguePanel") as Control).visible
		or not (scene.get_node("CenterLine") as Control).visible
		or not bool((scene.get("voice_sequence_player") as Node).call("is_active"))
	):
		push_error("G1-06 was not converted to voiced off-screen narration.")
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
		or dialogue_panel.visible
		or not center_line.visible
		or center_line.anchor_right > 0.43
		or center_line.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT
		or not bool((scene.get("voice_sequence_player") as Node).call("is_active"))
	):
		push_error("G1-06 did not begin with voiced narration in the left safe area.")
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

	# Let the real SHOT-38 -> SHOT-09 transition finish before crossing the
	# script-only G3-02 -> G3-03 boundary. Both units use SHOT-09, so the latter
	# boundary must not generate a second, meaningless black flash.
	await create_timer(0.70).timeout
	story.call("start_at", 14, 0)
	await process_frame
	var glare_overlay := scene.get_node("ChapterFxLayer/G3GlareOverlay") as ColorRect
	var g3_transition_overlay := scene.get_node(
		"ChapterFxLayer/G3TransitionOverlay"
	) as ColorRect
	var g3_03_bubble_position := Vector2(
		minf(1300.0, 1880.0 - dialogue_panel.size.x),
		40.0,
	)
	if (
		str(chapter_three_director.get("current_shot_id")) != "SHOT-09"
		or master_texture.texture == null
		or asset_placeholder.visible
		or glare_overlay.visible
		or g3_transition_overlay.visible
		or not dialogue_panel.visible
		or not dialogue_panel.position.is_equal_approx(g3_03_bubble_position)
	):
		push_error("G3-03 did not keep its opening dialogue continuously in the flower sea.")
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
	var evidence_timer := scene.get_node("G3EvidenceTimer") as Timer
	var evidence_labels := evidence_overlay.find_children("*", "Label", true, false)
	var has_skip_copy := false
	var longest_fragment_length := 0
	var widest_fragment := 0.0
	var has_project_tomorrow_context := false
	var has_project_tomorrow_chandelier := false
	var has_birthday_script_copy := false
	for label_variant in evidence_labels:
		if "点击可跳过检索" in (label_variant as Label).text:
			has_skip_copy = true
	for fragment_variant in evidence_fragments.get_children():
		var fragment := fragment_variant as Label
		longest_fragment_length = maxi(longest_fragment_length, fragment.text.length())
		widest_fragment = maxf(widest_fragment, fragment.size.x)
		if "为了在这人生的虚无活下来" in fragment.text:
			has_project_tomorrow_context = true
		if "吊灯很大很亮很白" in fragment.text:
			has_project_tomorrow_chandelier = true
		if "概率模型" in fragment.text or "最后的抗争" in fragment.text:
			has_birthday_script_copy = true
	if (
		not evidence_overlay.visible
		or evidence_overlay.material == null
		or evidence_flash == null
		or evidence_fragments == null
		or evidence_fragments.get_child_count() < 20
		or not (evidence_fragments.get_child(0) is Label)
		or str((evidence_fragments.get_child(0) as Label).text).is_empty()
		or longest_fragment_length < 34
		or widest_fragment < 800.0
		or not has_project_tomorrow_context
		or not has_project_tomorrow_chandelier
		or has_birthday_script_copy
		or evidence_timer == null
		or not is_equal_approx(evidence_timer.wait_time, 10.0)
		or has_skip_copy
		or center_line.visible
		or not bool(music_director.call("is_cue_active", "MUS-05A"))
	):
		push_error("G3 did not insert the ten-second script-text filtering field after the cue line.")
		quit(1)
		return
	scene.call("_advance_story")
	await process_frame
	if (
		evidence_overlay.visible
		or int(story.get("line_index")) != 4
		or not bool(music_director.call("is_cue_active", "MUS-05B"))
	):
		push_error("G3 evidence field could not resolve into the retrieved quote.")
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
	var g4_transition_overlay := scene.get_node("ChapterFxLayer/G4TransitionOverlay") as ColorRect
	var g4_replay_frame := scene.get_node("ChapterFxLayer/G4ReplayFrame") as Control
	var g4_replay_border := g4_replay_frame.get_node("ReplayBorder") as Panel
	var g4_replay_header := g4_replay_frame.get_node("ReplayHeader") as Label
	var g4_replay_progress := g4_replay_frame.get_node("ReplayProgressFill") as ColorRect
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
		or not g4_replay_frame.visible
		or g4_replay_header.text != "来自三十一岁的质问"
		or g4_replay_header.get_theme_font_size("font_size") < 26
		or g4_replay_border.position.x < 60.0
		or g4_replay_border.position.y < 46.0
		or g4_replay_border.size.x > 1800.0
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
	var g4_progress_at_three := g4_replay_progress.size.x
	await create_timer(0.14).timeout
	if g4_replay_progress.size.x <= g4_progress_at_three:
		push_error("G4-01 replay progress did not advance continuously with its soundtrack.")
		quit(1)
		return
	voice_sequence_player.call("seek", 12.50)
	await process_frame
	if (
		int(story.get("line_index")) != 2
		or str(chapter_four_director.get("current_variant_id")) != "mountains"
		or not (scene.get_node("CenterLine") as Control).visible
		or not g4_replay_frame.visible
		or g4_replay_progress.size.x <= 0.0
		or not g4_transition_overlay.visible
	):
		push_error("G4-01 soundtrack did not advance subtitles and imagery without input.")
		quit(1)
		return
	await create_timer(1.0).timeout
	if g4_transition_overlay.visible:
		push_error("G4-01 replay shot fade did not settle after the image change.")
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
		or not bool(voice_sequence_player.call("is_active"))
		or str(music_director.get("active_cue_id")) != "MUS-07B"
		or str(chapter_four_director.get("current_shot_id")) != "SHOT-13"
		or bool(chapter_four_director.get("age_jump_active"))
		or g4_replay_frame.visible
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
	story.call("start_at", 19, 17)
	await process_frame
	if (
		not bool(voice_sequence_player.call("is_active"))
		or str(music_director.get("active_cue_id")) != "MUS-07B"
	):
		push_error("Manual G4 narration did not preserve the chapter BGM.")
		quit(1)
		return
	await create_timer(0.15).timeout
	if int(story.get("line_index")) != 17:
		push_error("Manual G4 narration advanced without player input.")
		quit(1)
		return
	voice_sequence_player.call("_on_player_finished")
	await process_frame
	if int(story.get("line_index")) != 17:
		push_error("Completed manual G4 narration advanced without player input.")
		quit(1)
		return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if (
		int(story.get("line_index")) != 18
		or not center_line.visible
		or not center_line.text.contains("在三姐妹和大象岩")
		or not bool(voice_sequence_player.call("is_active"))
	):
		push_error("Manual G4 narration did not start the next line after player input.")
		quit(1)
		return
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if (
		int(story.get("line_index")) != 18
		or not center_line.visible
		or not center_line.text.contains("我站在延时相机旁")
		or not bool(voice_sequence_player.call("is_active"))
	):
		push_error("Manual G4 narration did not follow the reviewed page advance.")
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
		or g4_time_marker.visible
		or g4_replay_frame.visible
	):
		push_error("G4-02 did not return cleanly from the age-thirty-one replay to the present.")
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
		or g4_replay_frame.visible
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
		or g4_replay_frame.visible
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
		or g4_replay_frame.visible
	):
		push_error("G4-04 did not begin on the accepted Shenzhen garage departure master.")
		quit(1)
		return
	if not is_equal_approx(float(scene.call("_current_auto_wait_seconds")), 5.27):
		push_error("G4-04 did not apply its chapter-specific auto-play breathing room.")
		quit(1)
		return
	if not is_equal_approx(float(scene.call("_current_voiced_auto_wait_seconds")), 1.2648):
		push_error("G4-04 still leaves an excessive gap after voiced lines.")
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
		or g4_replay_frame.visible
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
	scene.call("_finish_typing")
	scene.call("_advance_story")
	await process_frame
	if (
		str(chapter_four_director.get("current_shot_id")) != "SHOT-61"
		or str(story.call("get_current_line").get("id", "")) != "G4-05-06"
		or not bool(music_director.call("is_cue_active", "MUS-07B"))
		or master_texture.texture == null
		or asset_placeholder.visible
		or g4_replay_frame.visible
	):
		push_error("G4-05 did not present the closing narration on the night descent.")
		quit(1)
		return

	scene.call("_finish_typing")
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
		or not bool(music_director.call("is_cue_active", "MUS-09C"))
	):
		push_error("G5-01 did not reveal the fog scene together with its BGM entry.")
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
	if not is_equal_approx(float(scene.call("_current_voiced_auto_wait_seconds")), 1.428):
		push_error("G5-02 still leaves an excessive gap after voiced lines.")
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
		or str(chapter_five_director.get("current_variant_id")) != "threshold"
		or master_texture.texture == null
		or not bool(chapter_five_director.get("finale_threshold_active"))
		or not (scene.get_node("ChapterFxLayer/G5TransitionOverlay") as Control).visible
		or not (scene.get_node("ChapterFxLayer/G5TransitionTexture") as Control).visible
		or not center_line.visible
		or not bool(voice_sequence_player.call("is_active"))
	):
		push_error("G5-04 did not begin its finale threshold with the decision line.")
		quit(1)
		return
	chapter_five_director.call("_finish_finale_threshold")
	await process_frame
	if (
		bool(chapter_five_director.get("finale_threshold_active"))
		or str(chapter_five_director.get("current_variant_id")) != "lantern"
		or (scene.get_node("ChapterFxLayer/G5TransitionOverlay") as Control).visible
		or (scene.get_node("ChapterFxLayer/G5TransitionTexture") as Control).visible
	):
		push_error("G5-04 finale threshold did not settle on the lantern state.")
		quit(1)
		return

	story.call("start_at", 27, 0)
	await process_frame
	if (
		str(chapter_five_director.get("current_variant_id")) != "live"
		or master_texture.texture == null
		or not (scene.get_node("ChapterFxLayer/G5EndingOcean") as Control).visible
		or (scene.get_node("ChapterFxLayer/G5EndingOcean") as Control).z_index > center_line.z_index
		or (scene.get_node("ChapterFxLayer/G5EndingBeaconGlow") as Control).visible
		or (scene.get_node("ChapterFxLayer/G5EndingWalkAnchor") as Control).visible
		or (scene.get_node("ChapterFxLayer/G5EndingWalkAnchor/G5EndingWalkBob/G5EndingPerson") as Control).visible
		or (scene.get_node("ChapterFxLayer/G5EndingWalkAnchor/G5EndingWalkBob/G5EndingLantern") as Control).visible
	):
		push_error("G5-05 opening has a retired cut-out layer or an ocean layer above its captions.")
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
	story.call("start_at", 27, 2)
	await process_frame
	if (
		str(chapter_five_director.get("current_variant_id")) != "walk-step-01"
		or master_texture.texture == null
		or center_line.visible
		or not bool(chapter_five_director.get("ending_sequence_active"))
		or (scene.get_node("ChapterFxLayer/G5EndingWalkAnchor") as Control).visible
		or not bool(voice_sequence_player.call("is_active"))
	):
		push_error("G5-05 did not begin on the first full-frame walk still.")
		quit(1)
		return
	chapter_five_director.call("_show_ending_identity_close")
	voice_sequence_player.call("seek", 5.45)
	await process_frame
	if (
		str(chapter_five_director.get("current_variant_id")) != "identity-close"
		or not center_line.visible
		or (center_line as Label).text != "我是瞬光。"
	):
		push_error("G5-05 did not reveal the voiced identity line on the close cutaway.")
		quit(1)
		return
	var identity_ocean := scene.get_node("ChapterFxLayer/G5EndingOcean") as TextureRect
	var beacon_material := identity_ocean.material as ShaderMaterial
	var identity_texture := identity_ocean.texture
	chapter_five_director.call("tick", 1.44)
	if (
		identity_ocean.texture != identity_texture
		or not identity_ocean.texture.resource_path.ends_with("identity-close.png")
		or beacon_material.shader.code.contains("TIME")
	):
		push_error("G5-05 identity frame should remain static without water or wind deformation.")
		quit(1)
		return
	chapter_five_director.call("_reset_ending_beacon_cycle")
	chapter_five_director.call("tick", 0.73)
	if (
		bool(chapter_five_director.get("ending_beacon_on"))
		or (scene.get_node("ChapterFxLayer/G5EndingBeaconGlow") as Control).visible
		or float(beacon_material.get_shader_parameter("beacon_on")) != 0.0
	):
		push_error("G5-05 beacon did not switch fully off after its lit interval.")
		quit(1)
		return
	chapter_five_director.call("tick", 2.66)
	if (
		not bool(chapter_five_director.get("ending_beacon_on"))
		or not (scene.get_node("ChapterFxLayer/G5EndingBeaconGlow") as Control).visible
		or float(beacon_material.get_shader_parameter("beacon_on")) != 1.0
	):
		push_error("G5-05 beacon did not switch fully on after its dark interval.")
		quit(1)
		return

	voice_sequence_player.call("seek", 10.25)
	await process_frame
	chapter_five_director = scene.get("active_chapter_director") as RefCounted
	if (
		chapter_five_director == null
		or not bool(chapter_five_director.get("ending_final_hold_active"))
		or not bool(chapter_five_director.get("ending_sequence_active"))
		or str(chapter_five_director.get("current_variant_id")) != "identity-close"
		or center_line.visible
		or not (scene.get_node("ChapterFxLayer/G5EndingOcean") as Control).visible
		or not (scene.get_node("ChapterFxLayer/G5EndingBeaconGlow") as Control).visible
		or (scene.get_node("EndingOverlay") as Control).visible
	):
		push_error("G5 did not hold the animated identity frame after the final voice line.")
		quit(1)
		return
	chapter_five_director.call("tick", 30.0)
	chapter_five_director.call("on_auto_timeout")
	chapter_five_director.call("advance")
	await process_frame
	if (
		not bool(chapter_five_director.get("ending_final_hold_active"))
		or not bool(chapter_five_director.get("ending_sequence_active"))
		or str(chapter_five_director.get("current_variant_id")) != "identity-close"
		or (scene.get_node("EndingOverlay") as Control).visible
		or not (scene.get_node("ChapterFxLayer/G5EndingOcean") as Control).visible
		or bool(scene.get("recording_end_scheduled"))
	):
		push_error("G5 left its ending frame, displayed a card or scheduled a non-recording exit.")
		quit(1)
		return

	print(
		"Smoke test passed: current script, ten G0 dream states plus six reality CGs, seven G1 CGs, "
		+ "sixteen G2 trial masters with line-level shot switching, semantic dialogue beats, shot variants, "
		+ "fourteen G3 masters with an independent opening, safe Ousia staging and a staged memory-search field, "
		+ "twenty-seven G4 runtime packages, paper-revealed timed G4-01 voiceover, four staged SHOT-12 phases, staged sky phases and scored descent, "
		+ "twenty-one G5 runtime states across nine packages, chapter interludes with music pre-fades and simultaneous scene/BGM entries, three-frame final walk, voiced identity close-up and a static final hold with a local beacon blink and no ending card, "
		+ "timed soundtrack fades, age-jump handoffs, reverse split, core UI, and ending flow."
	)
	quit(0)


func _any_event_is_playing(sound_director: Node) -> bool:
	for player_variant in sound_director.get("event_players") as Array:
		if (player_variant as AudioStreamPlayer).playing:
			return true
	return false


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
