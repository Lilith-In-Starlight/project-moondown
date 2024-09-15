extends Control

@onready var note_display := $Notes
@onready var combo_note := $ComboNote
@onready var limit_line := $Panel2
@onready var note_hit_particles := [$Panel2/Node2D, $Panel2/Node2D2, $Panel2/Node2D3]
@onready var note_hit_lights := [$LightUpA, $LightUpB, $LightUpC]
@onready var playfield := $Panel3
@onready var play_lines := $Panel3/Lines
@onready var background := $Background
@onready var background_flash := $Background/Flash

@onready var music_player := $AudioStreamPlayer
@onready var combo_note_get_sfx := $ComboCoinGet

@onready var game_hud := $ScoreHUD

@onready var combo_amount_text := $ScoreHUD/Combo
@onready var combo_progress_bar := $ScoreHUD/Combo/ProgressBar
@onready var combo_was := $ScoreHUD/Combo/ThisCombo
@onready var combo_title := $ScoreHUD/Combo/Descriptor
@onready var score_display := $ScoreHUD/Score

@onready var hit_notification := $ScoreHUD/Label
@onready var hit_notification_disappear := $ScoreHUD/LabelAnim

@onready var live_luna_reaction := $ScoreHUD/Luna_react

@onready var ranking_screen := $Ranking
@onready var ranking_score_display := $Ranking/Score
@onready var ranking_combo_display := $Ranking/Combo
@onready var ranking_combo_title := $Ranking/ComboTitle
@onready var ranking_combo_was := $Ranking/ComboWas
@onready var ranking_song_title := $Ranking/SongName
@onready var ranking_grade := $Ranking/ComboRank

@onready var editor_hud := $Editor

@onready var game_start_timer := $Timer
@onready var pause_menu := $Pause

var conductor: Conductor = Conductor.new()
var last_beat := 0.0

var bpm_measurer := false
var beats := 0

var last_input_time: float = -INF

var song_started := false

var combo := 0
var combo_timer := 0.0
var combo_timer_goal := 0.0
var combo_timer_go_down := false
var combo_timer_precision := 1.0

var total := 0
var current := 0
var highest_combo := 0
var fullcombo := true

var note_approaches := false

var pause := false

var score := 0
var combo_score := 0

var playthrough_data := []

var editor := false

var previous_left_note: Node = null
var previous_middle_note: Node = null
var previous_right_note: Node = null
var previous_left_beat: float = -1.0
var previous_middle_beat: float = -1.0
var previous_right_beat: float = -1.0

var song_ended := false

var editor_clipboards := {}

func _ready() -> void:
	Global.to_menu = "songs_editor" if Global.using_editor else "songs"
	editor_hud.conductor = conductor
	combo_note.self_modulate = Global.song_data.combo_note_color
	limit_line.modulate = Global.song_data.play_last_line
	playfield.self_modulate = Global.song_data.playfield
	play_lines.self_modulate = Global.song_data.play_lines
	background.self_modulate = Global.song_data.bg_color
	music_player.stream = load(Global.song_data.path + "/song.mp3")
	conductor.set_audio_object(music_player, Global.song_data.bpm, 0)
	
	combo_progress_bar.max_value = 2 * conductor.crotchet
	
	read_level_file()
	editor_hud.editor_notes.append((conductor.notes[0].duplicate()))
	editor_hud.editor_notes.append((conductor.notes[1].duplicate()))
	editor_hud.editor_notes.append((conductor.notes[2].duplicate()))
	
	if Global.using_editor:
		conductor.notes[0] = editor_hud.editor_notes[0]
		conductor.notes[1] = editor_hud.editor_notes[1]
		conductor.notes[2] = editor_hud.editor_notes[2]
		setup_note_nodes(conductor.notes[0])
		setup_note_nodes(conductor.notes[1])
		setup_note_nodes(conductor.notes[2])
		editor_hud.editor_notes.clear()
		disable_everything()
		conductor.connect("beat_plus_offset_happened", Callable(self, "_on_beat_plus_offset_happened"))
		conductor.connect("beat_happened", Callable(self, "_on_beat_happened"))
		game_start_timer.stop()
		editor = true

func _process(delta: float) -> void:
	editor_hud.visible = editor
	editor_hud.in_editor = editor
	get_tree().set_auto_accept_quit(not editor and not editor_hud.changes_done)
	if not editor:

		process_game(delta)
		if Input.is_action_just_pressed("editlevel") and Global.using_editor:
			disable_everything()
			song_ended = false
			conductor.sound_object.stop()
			for node in note_display.get_children():
				if node is Node:
					node.queue_free()
			editor = true
			conductor.notes[0].clear()
			conductor.notes[2].clear()
			conductor.notes[1].clear()
			if editor_hud.editor_notes.is_empty():
				read_level_file()
			else:
				conductor.notes[0] = editor_hud.editor_notes[0]
				conductor.notes[1] = editor_hud.editor_notes[1]
				conductor.notes[2] = editor_hud.editor_notes[2]
				setup_note_nodes(conductor.notes[0])
				setup_note_nodes(conductor.notes[1])
				setup_note_nodes(conductor.notes[2])
				editor_hud.editor_notes.clear()
	else:
		song_ended = false
		$Editor.process(delta)

		if Input.is_action_just_pressed("editlevel") and not $Editor.editor_mode in [1, 4]:
			previous_left_note = null
			previous_middle_note = null
			previous_right_note = null
			previous_left_beat = -1.0
			previous_middle_beat = -1.0
			previous_right_beat = -1.0
			conductor.sound_object.play(editor_hud.editor_beat * conductor.crotchet)
			editor_hud.editor_notes.append((conductor.notes[0].duplicate()))
			editor_hud.editor_notes.append((conductor.notes[1].duplicate()))
			editor_hud.editor_notes.append((conductor.notes[2].duplicate()))
			conductor.time = null
			editor = false
			song_started = true
			for node in note_display.get_children():
				if node is Node:
					node.queue_free()

func process_game(delta: float) -> void:
	score_display.text = str(score)
	ranking_score_display.text = "Score: " + str(score + combo_score * combo)
	if combo > highest_combo: highest_combo = combo
	var rank = 0.0
	note_display.position.y = (conductor.song_position().get_time_in_beats() - game_start_timer.time_left / conductor.crotchet) * Global.SCROLL_SPEED
	if total != 0.0:
		rank = float(current) / float(total)
	
	if Input.is_action_just_pressed("buttonpause"):
		get_tree().paused = not get_tree().paused
	
	pause_menu.visible = get_tree().paused
	
	note_hit_lights[0].visible = Input.is_action_pressed("button1")
	note_hit_lights[0].position.x = -100 + (get_viewport_rect().size.x / 2.0) - note_hit_lights[0].size.x / 2.0
	note_hit_lights[1].visible = Input.is_action_pressed("button2")
	note_hit_lights[1].position.x = (get_viewport_rect().size.x / 2.0) - note_hit_lights[1].size.x / 2.0
	note_hit_lights[2].visible = Input.is_action_pressed("button3")
	note_hit_lights[2].position.x = 100 + (get_viewport_rect().size.x / 2.0) - note_hit_lights[2].size.x / 2.0
	
	note_hit_particles[0].emitting = Input.is_action_pressed("button1")
	note_hit_particles[0].position.x = -100 + (get_viewport_rect().size.x / 2.0)
	note_hit_particles[1].emitting = Input.is_action_pressed("button2")
	note_hit_particles[1].position.x = (get_viewport_rect().size.x / 2.0)
	note_hit_particles[2].emitting = Input.is_action_pressed("button3")
	note_hit_particles[2].position.x = 100 + (get_viewport_rect().size.x / 2.0)
	
	if get_tree().paused:
		if Input.is_action_just_pressed("button1") and not editor_hud.changes_done:
			$SceneExit.reload_current_scene()
		elif Input.is_action_just_pressed("button2"):
			pass
		elif Input.is_action_just_pressed("button3"):
			$SceneExit.change_scene_to_packed("res://SongSelect.tscn")
	else:
		if Input.is_action_just_pressed("button1"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "A"])
		if Input.is_action_just_pressed("button2"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "S"])
		if Input.is_action_just_pressed("button3"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "D"])
		if Input.is_action_just_released("button1"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "a"])
		if Input.is_action_just_released("button2"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "s"])
		if Input.is_action_just_released("button3"):
			playthrough_data.append([conductor.song_position().get_time_in_seconds(), "d"])
	
	if conductor.song_position().get_time_in_beats() > get_max_beat() + 3 or song_ended:
		song_ended = true
		get_tree().paused = false
		if Input.is_action_just_pressed("button1"):
			get_tree().reload_current_scene()
		if Input.is_action_just_pressed("button3"):
			$SceneExit.change_scene_to_packed("res://SongSelect.tscn")
		if Global.using_editor:
			Input.action_press("editlevel")
			return
		ranking_screen.visible = true
		ranking_combo_display.text = "x" + str(highest_combo)
		ranking_combo_title.text = get_combo_title(highest_combo)
		ranking_song_title.text = Global.song_data.song_name
		var peppino := false
		if fullcombo: ranking_combo_was.text = "Your FULL COMBO was:"
		if rank <= 0.05:
			ranking_grade.text = "wHAT THE [F]UCK"
		elif rank <= 0.3:
			ranking_grade.text = "That was [D]awful"
		elif rank <= 0.6:
			ranking_grade.text = "That was A[C]ceptable"
		elif rank <= 0.8:
			ranking_grade.text = "That was [B]okay!"
		elif rank < 0.95:
			ranking_grade.text = "That was [A]wesome!"
		elif rank <= 0.98:
			ranking_grade.text = "That was [S]weaty!"
		elif rank <= 0.999 and not fullcombo:
			ranking_grade.text = "That was [S]weaty!"
		elif rank <= 0.999 and fullcombo:
			ranking_grade.text = "That was [SS]upreme!!!"
		elif rank <= 1.0 and not fullcombo:
			ranking_grade.text = "you were so close"
		elif rank <= 1.0 and fullcombo:
			ranking_grade.text = "peppino."
			peppino = true
		var song_data = conductor.sound_object.stream.data
		
		var song_access_hash = Global.get_song_access_hash(Global.song_data.path)
		if Global.game_data.has_section_key("songs", song_access_hash + "_score") and Global.game_data.get_value("songs", song_access_hash + "_score") < score + combo_score * combo or not Global.game_data.has_section_key("songs", song_access_hash + "_score"):
			Global.game_data.set_value("songs", song_access_hash + "_score", score + combo_score * combo)
			Global.game_data.set_value("songs", song_access_hash + "_combo", highest_combo)
			Global.game_data.set_value("songs", song_access_hash + "_peppino", peppino)
			Global.save_data()
	
	conductor.process()
	
	if is_instance_valid(previous_left_note):
		previous_left_note = null
	if is_instance_valid(previous_middle_note):
		previous_middle_note = null
	if is_instance_valid(previous_right_note):
		previous_right_note = null
	var lout = active_note_setup(conductor.notes[0], previous_left_beat, previous_left_note)
	previous_left_beat = lout[0]
	previous_left_note = lout[1]
	lout = active_note_setup(conductor.notes[1], previous_middle_beat, previous_middle_note)
	previous_middle_beat = lout[0]
	previous_middle_note = lout[1]
	lout = active_note_setup(conductor.notes[2], previous_right_beat, previous_right_note)
	previous_right_beat = lout[0]
	previous_right_note = lout[1]
	
	combo_amount_text.text = "x%s" % str(combo)
	
	if combo == 0:
		combo_timer_goal = ceil(conductor.song_position().get_time_in_beats()) * conductor.crotchet + 2.0 * conductor.crotchet
	else:
		process_combo_timer()
		combo_progress_bar.value = max(combo_timer_goal - conductor.song_position().get_time_in_seconds(), 0)
		combo_progress_bar.value = 2 * conductor.crotchet
		
		if abs(conductor.song_position().get_time_in_seconds() - combo_timer_goal) < conductor.crotchet * 0.5 and not note_approaches:
			live_luna_reaction.play("combo_fear")
		
		if combo_timer_goal + Global.OKAY_TIMING <= conductor.song_position().get_time_in_seconds() and note_display.get_child_count() != 0:
			score += combo_score * combo
			combo_score = 0
			combo = 0
			fullcombo = false
			combo_was.text = "that combo was..."
			hit_notification.text = "Super F!"
	
	var combo_should_y = -combo_timer_goal / conductor.crotchet * Global.SCROLL_SPEED + 555 + conductor.song_position().get_time_in_beats() * Global.SCROLL_SPEED - combo_note.size.y / 2.0
	if combo_note.position.y < combo_should_y:
		combo_note.position.y = combo_should_y
	else:
		combo_note.position.y = lerp(combo_note.position.y, combo_should_y, 0.3)
	combo_note.size.y = (Global.SCROLL_SPEED / conductor.crotchet) * 0.1 * combo_timer_precision
	
	if combo != 0:
		combo_title.text = get_combo_title(combo)
	
	if combo == 1:
		combo_was.text = "this combo is..."
	
	if song_started:
		if Input.is_action_just_pressed("button1") or Input.is_action_just_pressed("button2") or Input.is_action_just_pressed("button3"):
			last_input_time = conductor.song_position().get_time_in_seconds()
	
	if bpm_measurer:
		if Input.is_action_just_pressed("button1"):
			beats += 1
			print(float(beats) / conductor.song_position().get_time_in_minutes())

func _on_beat_plus_offset_happened(beat, beat_number):
	pass

func _on_beat_happened(beat_number):
	var tween_background = create_tween()
	tween_background.tween_property(background_flash, "self_modulate:a", max(combo / 50, 0.3), conductor.crotchet * 0.1)
	tween_background.tween_property(background_flash, "self_modulate:a", 0.2, conductor.crotchet * 0.75)
	if combo > 0: combo_timer_go_down = true
	if combo_amount_text.rotation < 0.0:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(combo_amount_text, "rotation", 10 * max(combo, 2) / 50.0, conductor.crotchet).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(hit_notification, "rotation", -5 * max(combo, 2) / 50.0, conductor.crotchet).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	else:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(combo_amount_text, "rotation", -10 * max(combo, 2) / 50.0, conductor.crotchet).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(hit_notification, "rotation", 5 * max(combo, 2) / 50.0, conductor.crotchet).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func celebrate_beat(beat_time: float, no_miss: bool) -> bool:
	var imprecision :float = abs(beat_time - last_input_time)
	
	if imprecision < 0.05 * combo_timer_precision:
		combo_timer_precision *= 0.98
		hit_notification.text = "Recovery!"
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
		return true
		
	elif imprecision < 0.1 * combo_timer_precision and beat_time > last_input_time:
		hit_notification.text = "ERecovery"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
		return true
	elif imprecision < 0.1 * combo_timer_precision and beat_time < last_input_time:
		hit_notification.text = "LRecovery"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
		return true
	
	elif imprecision < 0.2 * combo_timer_precision and beat_time > last_input_time:
		hit_notification.text = "A Bit Early!"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
		return true
	elif imprecision < 0.2 * combo_timer_precision and beat_time < last_input_time:
		hit_notification.text = "Almost Late!"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
		return true
	return false

func _on_Timer_timeout() -> void:
	conductor.connect("beat_plus_offset_happened", Callable(self, "_on_beat_plus_offset_happened"))
	conductor.connect("beat_happened", Callable(self, "_on_beat_happened"))
	music_player.play(conductor.crotchet * 0)
	song_started = true

func hit_note(imprecision, lateness, time, combo_leniency:=1.0):
	note_approaches = false
	var previous_combo = combo
	total += 100
	if imprecision < Global.PERFECT_TIMING * combo_leniency:
		current += 100
		combo_timer_goal = ceil(time) * conductor.crotchet + 2.0 * conductor.crotchet
		combo += 1
		hit_notification.text = "Perfect!"
		combo_timer_precision = 1.0
		combo_score += 100
		
	elif imprecision < Global.INEXACT_PERFECT_TIMING * combo_leniency and lateness == - 1:
		current += 98
		combo_timer_goal = ceil(time) * conductor.crotchet + 2.0 * conductor.crotchet
		combo += 1
		hit_notification.text = "EPerfect!"
		combo_timer_precision = 1.0
		combo_score += 90
	elif imprecision < Global.INEXACT_PERFECT_TIMING * combo_leniency and lateness == 1:
		current += 98
		combo_timer_goal = ceil(time) * conductor.crotchet + 2.0 * conductor.crotchet
		combo += 1
		hit_notification.text = "LPerfect!"
		combo_timer_precision = 1.0
		combo_score += 90
	
	elif imprecision < Global.OKAY_TIMING * combo_leniency and lateness == - 1:
		current += 50
		combo_timer_goal = ceil(time) * conductor.crotchet + 2.0 * conductor.crotchet
		combo += 1
		hit_notification.text = "EOkay!"
		combo_timer_precision = 1.0
		combo_score += 20
	elif imprecision < Global.OKAY_TIMING * combo_leniency and lateness == 1:
		current += 50
		combo_timer_goal = ceil(time) * conductor.crotchet + 2.0 * conductor.crotchet
		combo += 1
		hit_notification.text = "LOkay!"
		combo_timer_precision = 1.0
		combo_score += 20
	
	else:
		fullcombo = false
		combo_was.text = "that combo was..."
		if combo == 0:
			combo_title.text = "not existant..."
		else:
			score += combo_score * combo
			combo_score = 0
		if combo > 80:
			hit_notification.text = "Nice Choke"
		else:
			hit_notification.text = "Miss!"
		combo = 0
		combo_timer_precision = 1.0
	
	hit_notification_disappear.stop(true)
	hit_notification_disappear.play("Flash")
	
	if previous_combo != 0 and combo == 0:
		live_luna_reaction.play("miss")
	elif combo == 0:
		live_luna_reaction.play("default")
	elif combo <= 2:
		live_luna_reaction.play("combo_2")
	elif combo <= 30:
		live_luna_reaction.play("combo_10")
		live_luna_reaction.speed_scale = 1.0 / conductor.crotchet
	elif combo <= 100:
		live_luna_reaction.play("combo_30")
		live_luna_reaction.speed_scale = 1.0 / conductor.crotchet
	else:
		live_luna_reaction.play("combo_50")
		live_luna_reaction.speed_scale = 1.0 / conductor.crotchet

func get_combo_title(combo_input: int) -> String:
	var combo_title := ""
	if combo_input != 0:
		if combo_input == 1:
			combo_title = "Not A Combo!"
		elif combo_input % 300 <= 10:
			combo_title = "A combo!"
		elif combo_input % 300 <= 20:
			combo_title = "Getting Somewhere"
		elif combo_input % 300 <= 50:
			combo_title = "Pretty Good"
		elif combo_input % 300 <= 80:
			combo_title = "REALLY Good"
		elif combo_input % 300 <= 100:
			combo_title = "PREPOSTEROUS"
		elif combo_input % 300 <= 150:
			combo_title = "UNLADYLIKE"
		elif combo_input % 300 == 151:
			combo_title = "LIKE A SWEATY TOMBOY"
		elif combo_input % 300 == 152:
			combo_title = "what"
		elif combo_input % 300 <= 200:
			combo_title = "INDELICATE"
		elif combo_input % 300 <= 250:
			combo_title = "VULGAR"
		elif combo_input % 300 <= 300:
			combo_title = "UNCOUTH"
	
	if combo_input >= 300:
		if not combo_title.begins_with("VERY "):
			combo_title = "VERY " + combo_title
	
	return combo_title

func read_level_file():
	if FileAccess.file_exists(Global.song_data.path + "/level.txt") and not FileAccess.file_exists(Global.song_data.path + "/level.luna"):
		var dict := read_level_old()
		var level_file = FileAccess.open(Global.song_data.path + "/level.luna", FileAccess.WRITE)
		level_file.store_string(JSON.stringify(dict))
		level_file.close()
	
	if FileAccess.file_exists(Global.song_data.path + "/level.luna"):
		read_level()

func read_level_old() -> Dictionary:
	var data := {
		"file_ver": 0,
		"notes":[],
	}
	
	var level_file = FileAccess.open(Global.song_data.path + "/level.txt", FileAccess.READ)
	var current_line := level_file.get_line()
	var right_sustain: NoteData = null
	var middle_sustain: NoteData = null
	var left_sustain: NoteData = null
	
	while current_line != "":
		var split_line = current_line.split("	", false)
		var beat_number = split_line[0] as float
		var notes_text_data = split_line[1]
		var new_note_data := NoteData.new()
		new_note_data.start_beat_number = beat_number
		
		if notes_text_data.find("R") != - 1:
			new_note_data.lane = 2
			data.notes.append(new_note_data.get_as_dict())
		if notes_text_data.find("M") != - 1:
			new_note_data.lane = 1
			data.notes.append(new_note_data.get_as_dict())
		if notes_text_data.find("L") != - 1:
			new_note_data.lane = 0
			data.notes.append(new_note_data.get_as_dict())
		
		new_note_data = NoteData.new()
		new_note_data.start_beat_number = beat_number
		if notes_text_data.find("r") != - 1:
			if right_sustain == null:
				right_sustain = new_note_data
				right_sustain.lane = 2
			else:
				right_sustain.end_beat_number = beat_number
				data.notes.append(right_sustain.get_as_dict())
				right_sustain = null
		
		new_note_data = NoteData.new()
		new_note_data.start_beat_number = beat_number
		if notes_text_data.find("m") != - 1:
			if middle_sustain == null:
				middle_sustain = new_note_data
				middle_sustain.lane = 1
			else:
				middle_sustain.end_beat_number = beat_number
				data.notes.append(middle_sustain.get_as_dict())
				middle_sustain = null
		
		new_note_data = NoteData.new()
		new_note_data.start_beat_number = beat_number
		if notes_text_data.find("l") != - 1:
			if left_sustain == null:
				left_sustain = new_note_data
				left_sustain.lane = 0
			else:
				left_sustain.end_beat_number = beat_number
				data.notes.append(left_sustain.get_as_dict())
				left_sustain = null
		
		current_line = level_file.get_line()
		
	level_file.close()
	return data

func read_level():
	var level_file = FileAccess.open(Global.song_data.path + "/level.luna", FileAccess.READ)
	var text := level_file.get_as_text()
	var test_json_conv = JSON.new()
	var error = test_json_conv.parse(text)
	if error == OK:
		var json_result :Dictionary = test_json_conv.get_data()
		var data: Dictionary = json_result
		for object in data.notes:
			if object.type == NoteData.TYPE:
				var note_data := NoteData.from_dict(object)
				conductor.notes[note_data.lane].append(note_data)
	else:
		push_error(test_json_conv.get_error_message())

func setup_note_nodes(note_array: Array):
	var previous_beat_time = -1.0
	var previous_note_node = null
	
	for note_data in note_array:
		var new_note_node = preload ("res://Note.tscn").instantiate()
		new_note_node.hit_beat_number = note_data.start_beat_number
		if note_data.is_sustain():
			new_note_node.release_beat_number = note_data.end_beat_number
		new_note_node.sustain = note_data.is_sustain()
		new_note_node.lane = note_data.lane + 1
		new_note_node.conductor = conductor
		new_note_node.seconds_from_previous = previous_beat_time * conductor.crotchet
		new_note_node.modulate = Global.song_data.color2
		if randi() % 2 == 0:
			new_note_node.modulate = Global.song_data.color1
		note_display.add_child(new_note_node)
		if previous_beat_time != new_note_node.hit_beat_number:
			previous_beat_time = new_note_node.hit_beat_number
		
		if previous_note_node != null:
			previous_note_node.seconds_for_next = new_note_node.hit_beat_number * conductor.crotchet
			previous_note_node.next_note_in_lane = new_note_node
		
		previous_note_node = new_note_node

func process_combo_timer():
	var combo_note_imprecision = abs(combo_timer_goal - last_input_time)
	var beat_time = ceil(conductor.song_position().get_time_in_beats()) * conductor.crotchet
	var late = combo_timer_goal < last_input_time
	if combo_note_imprecision < Global.PERFECT_TIMING * combo_timer_precision:
		combo_note_get_sfx.play()
		combo_timer_precision *= 0.8
		hit_notification.text = "Recovery!"
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
	elif combo_note_imprecision < Global.INEXACT_PERFECT_TIMING * combo_timer_precision and not late:
		combo_note_get_sfx.play()
		hit_notification.text = "ERecovery"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
	elif combo_note_imprecision < Global.INEXACT_PERFECT_TIMING * combo_timer_precision and late:
		combo_note_get_sfx.play()
		hit_notification.text = "LRecovery"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
	elif combo_note_imprecision < Global.OKAY_TIMING * combo_timer_precision and not late:
		combo_note_get_sfx.play()
		hit_notification.text = "A Bit Early!"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet
	elif combo_note_imprecision < Global.OKAY_TIMING * combo_timer_precision and late:
		combo_note_get_sfx.play()
		hit_notification.text = "Almost late!!"
		combo_timer_precision *= 0.98
		combo_timer_goal = ceil(beat_time) + 2.0 * conductor.crotchet

func get_max_beat() -> float:
	var max_beat := 0.0
	if not editor_hud.editor_notes[2].is_empty():
		max_beat = editor_hud.editor_notes[2][ - 1].start_beat_number
		if editor_hud.editor_notes[2][ - 1].is_sustain():
			max_beat = editor_hud.editor_notes[2][ - 1].end_beat_number
	if not editor_hud.editor_notes[1].is_empty():
		max_beat = max(max_beat, editor_hud.editor_notes[1][ - 1].start_beat_number)
		if editor_hud.editor_notes[1][ - 1].is_sustain():
			max_beat = editor_hud.editor_notes[1][ - 1].end_beat_number
	if not editor_hud.editor_notes[0].is_empty():
		max_beat = max(max_beat, editor_hud.editor_notes[0][ - 1].start_beat_number)
		if editor_hud.editor_notes[0][ - 1].is_sustain():
			max_beat = editor_hud.editor_notes[0][ - 1].end_beat_number
	return max_beat

func active_note_setup(array: Array, previous_beat: float, previous_node: Node):
	var previous_beat_time := previous_beat
	var previous_note_node = previous_node
	while not array.is_empty():
		var note_data = array[0]
		if (note_data.start_beat_number - conductor.song_position().get_time_in_beats()) > 5:
			break
		array.pop_front()
		if (note_data.start_beat_number - conductor.song_position().get_time_in_beats()) < - 1:
			continue
		var new_note_node = preload ("res://Note.tscn").instantiate()
		new_note_node.hit_beat_number = note_data.start_beat_number
		if note_data.is_sustain():
			new_note_node.release_beat_number = note_data.end_beat_number
		new_note_node.sustain = note_data.is_sustain()
		new_note_node.lane = note_data.lane + 1
		new_note_node.conductor = conductor
		new_note_node.seconds_from_previous = previous_beat_time * conductor.crotchet
		new_note_node.modulate = Global.song_data.color2
		
		print(Global.song_data.color2)
		if randi() % 2 == 0:
			new_note_node.modulate = Global.song_data.color1
		note_display.add_child(new_note_node)
	
		if previous_beat_time != new_note_node.hit_beat_number:
			previous_beat_time = new_note_node.hit_beat_number
		
		if previous_note_node != null:
			previous_note_node.seconds_for_next = new_note_node.hit_beat_number * conductor.crotchet
			previous_note_node.next_note_in_lane = new_note_node
		
		previous_note_node = new_note_node
	return [previous_beat_time, previous_note_node]

func _on_song_finished() -> void:
	song_ended = true

func disable_everything() -> void:
	combo_note.position.y = -100
	for idx in note_hit_lights.size():
		note_hit_lights[idx].visible = false
		note_hit_particles[idx].emitting = false
