extends Node2D


var note_data:NoteData = null
var hit_beat_number: = 0.0
var release_beat_number: = - 1.0
var lane: = 0
var conductor:Conductor = null
var hit_input_seconds = - INF
var release_input_seconds = - INF
var hit_in_seconds: = 0.0
var release_in_seconds: = 0.0
var action: = "button1"
var seconds_from_previous: = - 10.0
var next_note_in_lane:Node2D = null
var seconds_for_next: = INF
var sustain: = false
var previous_note_died: = false
var previous_note_death_frames: = 0

var got_beginning: = false

var released_improperly: = false

var sent_hit: = false
var def_modulate:Color

@onready var game_node = get_tree().get_nodes_in_group("GameNode")[0]

var simulated: = false
var simulate_hits: = false

@onready var parentparent: = get_parent().get_parent()


func _ready()->void :
	def_modulate = modulate
	position.y = - hit_beat_number * Global.SCROLL_SPEED + 555
	if sustain:
		$Icon2.position.y = - (release_beat_number - hit_beat_number) * Global.SCROLL_SPEED
		$Icon2.visible = true
		$Icon3.visible = true
		$Icon3.scale.y = (1 / 64.0) * ($Icon.position.y - $Icon2.position.y)
	hit_in_seconds = hit_beat_number * conductor.get_crotchet()
	release_in_seconds = release_beat_number * conductor.get_crotchet()
	position.x = 100 * (lane - 2) + (get_viewport_rect().size.x / 2.0)
	
	match lane:
		1:action = "button1"
		2:action = "button2"
		3:action = "button3"


func _process(delta:float)->void :
	if parentparent.editor:
		return 
	if previous_note_died:
		previous_note_death_frames += 1
	var current_beat_in_seconds: = conductor.song_position().get_time_in_seconds()
	
	if current_beat_in_seconds > game_node.combo_timer_goal - conductor.get_crotchet() * 0.51:
		game_node.note_approaches = true
	
	
	var lowest_bound_for_hit: float = hit_in_seconds - min(0.2, (hit_in_seconds - seconds_from_previous) * 0.5)
	var highest_bound_for_hit: float = hit_in_seconds + min(0.2, (seconds_for_next - hit_in_seconds) * 0.5)
	if Input.is_action_just_pressed(action):
		if previous_note_death_frames > 1:
			highest_bound_for_hit = hit_in_seconds + 0.2
			lowest_bound_for_hit = hit_in_seconds - 0.2
		released_improperly = false
		hit_input_seconds = current_beat_in_seconds
		
	if Input.is_action_just_released(action):
		hit_input_seconds = - INF
		release_input_seconds = current_beat_in_seconds
	
	var imprecision = abs(hit_in_seconds - hit_input_seconds)
	var exit_imprecision = abs(release_in_seconds - release_input_seconds)
	
	var time_until_note_happens:float = hit_in_seconds - current_beat_in_seconds
	
	if simulate_hits:
		if time_until_note_happens < 0.0 and not simulated and time_until_note_happens > - 2.0:
			var new_click = AudioStreamPlayer.new()
			new_click.stream = preload("res://click.wav")
			get_parent().get_parent().add_child(new_click)
			new_click.play()
			new_click.volume_db = 10
			simulated = true
			
	
	if hit_input_seconds > lowest_bound_for_hit and hit_input_seconds < highest_bound_for_hit and not got_beginning:
		var new_click = AudioStreamPlayer.new()
		new_click.stream = preload("res://click.wav")
		get_parent().get_parent().add_child(new_click)
		new_click.play()
		got_beginning = true
		if hit_input_seconds < hit_in_seconds:
			game_node.hit_note(imprecision, - 1, hit_beat_number)
		else :
			game_node.hit_note(imprecision, 1, hit_beat_number)
		if not sustain:
			if is_instance_valid(next_note_in_lane):next_note_in_lane.previous_note_died = true
			queue_free()
	
	if sustain and got_beginning:
		if not $AudioStreamPlayer.playing:
			$AudioStreamPlayer.play()
		$Icon.visible = false
		$Icon3.scale.y = (555 - $Icon2.global_position.y) * (1 / 64.0)
		$Icon3.global_position.y = 555
		modulate = def_modulate.lightened(0.5)
		var time_until_release_happens: = release_in_seconds - current_beat_in_seconds
		var sustain_duration: = release_in_seconds - hit_in_seconds
		
		if time_until_release_happens <= sustain_duration and time_until_release_happens > - 0.3 and got_beginning:
			if exit_imprecision < 0.3:
				var new_click = AudioStreamPlayer.new()
				new_click.stream = preload("res://click.wav")
				get_parent().get_parent().add_child(new_click)
				new_click.play()
				if release_input_seconds < release_in_seconds:
					game_node.hit_note(exit_imprecision, - 1, release_beat_number, 1.0)
				else :
					game_node.hit_note(exit_imprecision, 1, release_beat_number, 1.0)
				if is_instance_valid(next_note_in_lane):next_note_in_lane.previous_note_died = true
				queue_free()
			elif exit_imprecision < sustain_duration and not released_improperly:
				released_improperly = true
				game_node.hit_note(exit_imprecision, 2, release_beat_number, 1e-05)
	
		if current_beat_in_seconds > release_in_seconds + 0.2:
			game_node.hit_note(exit_imprecision, 2, release_beat_number, 1.5)
			queue_free()
			if is_instance_valid(next_note_in_lane):next_note_in_lane.previous_note_died = true
	else :
		if current_beat_in_seconds > highest_bound_for_hit and not sent_hit:
			modulate = modulate.darkened(0.3)
			game_node.hit_note(imprecision, 2, hit_beat_number)
			sent_hit = true
			if is_instance_valid(next_note_in_lane):next_note_in_lane.previous_note_died = true
		
		if current_beat_in_seconds > highest_bound_for_hit + 1.5:
			queue_free()


func align_to_note_data(nd: NoteData) -> void:
	note_data = nd
	hit_beat_number = nd.start_beat_number
	release_beat_number = nd.end_beat_number
	lane = nd.lane + 1
	sustain = nd.is_sustain()
	
	def_modulate = modulate
	position.y = - hit_beat_number * Global.SCROLL_SPEED + 555
	if sustain:
		$Icon2.position.y = - (release_beat_number - hit_beat_number) * Global.SCROLL_SPEED
		$Icon2.visible = true
		$Icon3.visible = true
		$Icon3.scale.y = (1 / 64.0) * ($Icon.position.y - $Icon2.position.y)
	else:
		$Icon2.visible = false
		$Icon3.visible = false
	hit_in_seconds = hit_beat_number * conductor.get_crotchet()
	release_in_seconds = release_beat_number * conductor.get_crotchet()
	position.x = 100 * (lane - 2) + (get_viewport_rect().size.x / 2.0)
