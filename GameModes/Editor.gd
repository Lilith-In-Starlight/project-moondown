extends Control

class_name EditorGameMode

var in_editor: = 0

var editor_mode: = 0
var changes_done: = false

@onready var insert_mode: = $InsertMode
@onready var select_mode: = $SelectMode
@onready var paste_mode: = $PasteMode

@onready var music_player: = $"../AudioStreamPlayer"
@onready var editor_gridlines: = $Beats
@onready var editor_sustains: = [$Sustains / Note1, $Sustains / Note2, $Sustains / Note3]
@onready var editor_sustain_trails: = [$Sustains / Note1 / Sustain, $Sustains / Note2 / Sustain, $Sustains / Note3 / Sustain]
@onready var editor_sustain_ends: = [$Sustains / Note1 / End, $Sustains / Note2 / End, $Sustains / Note3 / End]
@onready var quick_command_display: = $QuickCommand
@onready var command_line: = $Command

@onready var editor_notifications: = $History

@onready var note_display: = $"../Notes"

var conductor:Conductor = null

var editor_beat: = 0.0
var editor_grid_separators: = []
var editor_scroll_speed: = 1.0
var editor_scroll_grid: = 0.25
var editor_grid_fraction:Fraction = Fraction.new(1.0, 4.0)
var editor_making_sustains: = [null, null, null]
var editor_command: = ""
var editor_notes: = []
var old_grid_size: = NAN
var old_max_beat: = NAN


var editor_view_grid: = true
var editor_settings_gridnumbers: = 1
var editor_grid_forced_update: = true


var clipboards: = {}


func _ready()->void :
	connect_requests(insert_mode)
	connect_requests(select_mode)
	connect_requests(paste_mode)

func connect_requests(from:Node):
	connect_request("add_remove_note_request", from)
	connect_request("align_scroll_speed_to_grid_request", from)
	connect_request("align_cursor_to_grid_request", from)
	connect_request("arbitrary_scroll_request", from)
	connect_request("keybind_clear_request", from)
	connect_request("mode_change_request", from)
	connect_request("notification_request", from)
	connect_request("raise_request", from)
	connect_request("raise_selection_request", from)
	connect_request("scroll_request", from)
	connect_request("scroll_to_request", from)
	connect_request("set_gridsize_request", from)
	connect_request("set_scroll_speed_request", from)
	connect_request("start_finish_sustain_request", from)
	connect_request("put_selection_in_clipboard_request", from)
	connect_request("delete_selection_request", from)
	connect_request("add_specific_notes_request", from)

func connect_request(signal_name:String, from:Node):
	from.connect(signal_name, Callable(self, "_on_%sed" % signal_name))


func process(delta:float)->void :
	select_mode.process(delta, self)
	paste_mode.process(delta, self)
	editor_beat = clamp(editor_beat, 0.0, INF)
	note_display.position.y = lerp(note_display.position.y, editor_beat * Global.SCROLL_SPEED + 2.0, 0.2)
	editor_gridlines.visible = editor_view_grid
	
	var max_beat: = 0.0
	if not conductor.notes[2].is_empty():max_beat = conductor.notes[2][ - 1].start_beat_number
	if not conductor.notes[1].is_empty():max_beat = max(max_beat, conductor.notes[1][ - 1].start_beat_number)
	if not conductor.notes[0].is_empty():max_beat = max(max_beat, conductor.notes[0][ - 1].start_beat_number)
	
	var separators: = max_beat / editor_scroll_grid + 10
	
	
	while editor_grid_separators.size() < separators:
		var new_separator: = HSeparator.new()
		new_separator.position.y = - separators * editor_scroll_grid * Global.SCROLL_SPEED
		var new_label: = Label.new()
		new_label.text = "Null"
		new_label.position.x -= 10
		new_label.position.y += 2
		new_separator.add_child(new_label)
		editor_grid_separators.append(new_separator)
	
	while editor_grid_separators.size() > separators * 2.0:
		editor_grid_separators.pop_back().queue_free()
	
	for lane in 3:
		if editor_making_sustains[lane] == null:
			editor_sustains[lane].visible = false
		else :
			editor_sustains[lane].visible = true
			editor_sustains[lane].position.y = lerp(editor_sustains[lane].position.y, ( - editor_making_sustains[lane].start_beat_number + editor_beat) * Global.SCROLL_SPEED + 555 - 32, 0.2)
			editor_sustain_ends[lane].global_position.y = 481
			editor_sustain_trails[lane].scale.y = - (editor_sustains[lane].position.y - 480) / 64
	
	if old_grid_size != editor_scroll_grid or old_max_beat != max_beat or editor_grid_forced_update:
		old_max_beat = max_beat
		old_grid_size = editor_scroll_grid
		editor_grid_forced_update = false
		for idx in editor_grid_separators.size():
			var sep:HSeparator = editor_grid_separators[idx]
			var desire:float = - idx * editor_scroll_grid * Global.SCROLL_SPEED
			sep.position.y = desire
			sep.size.x = editor_gridlines.size.x
			match editor_settings_gridnumbers:
				1:sep.get_child(0).text = editor_grid_fraction.fmultiplied(idx).as_mixed().as_string()
				2:sep.get_child(0).text = editor_grid_fraction.fmultiplied(idx).as_fract().as_string()
				3:sep.get_child(0).text = str(editor_grid_fraction.fmultiplied(idx).as_float()).pad_decimals(2)
				0:sep.get_child(0).text = ""
			if idx < separators and not sep.is_inside_tree():
				editor_gridlines.add_child(sep)
			elif idx >= separators and sep.is_inside_tree():
				editor_gridlines.remove_child(sep)
	
	editor_gridlines.position.y = note_display.position.y + 555 - 2.0
	
	quick_command_display.text = ""
	
	for input_string in editor_command.split(">", false):
		if input_string is String:
			if input_string is String:
				var input: = - 1
				if not input_string.begins_with("S-"):
					input = input_string as int
					quick_command_display.text += Util.get_key_string(input)


func _input(event:InputEvent)->void :
	if not in_editor:
		return 
	if event is InputEventKey and not event.is_echo() and event.is_pressed():
		if editor_mode == 0:
			if not event.shift_pressed && not event.keycode == KEY_SHIFT:
				editor_command += "%s>" % event.keycode
			else:
				editor_command += "S-%s>" % event.keycode
			insert_mode.parse_command(self)
		elif editor_mode == 1:
			if event.keycode == KEY_ESCAPE:
				editor_mode = 0
				command_line.text = ""
				command_line.release_focus()
			elif event.keycode == KEY_ENTER:
				parse_commandmode()
		elif editor_mode == 2:
			if not event.shift_pressed:
				editor_command += "%s>" % event.keycode
			else :
				editor_command += "S-%s>" % event.keycode
			select_mode.parse_command(self)
		elif editor_mode == 3:
			if not event.shift_pressed:
				editor_command += "%s>" % event.keycode
			else :
				editor_command += "S-%s>" % event.keycode
			paste_mode.parse_command(self)
		elif editor_mode == 4:
			if event.keycode == KEY_ESCAPE:
				editor_mode = 0
				$Help.visible = false


func parse_commandmode():
	var cmd:Array = command_line.text.split(" ", false)
	command_line.text = ""
	command_line.release_focus()
	editor_mode = 0
	if cmd.size() == 0:
		return 
	var maincmd:String = cmd[0]
	match maincmd:
		":w":
			save_level_files()
		":wq":
			save_level_files()
			get_tree().change_scene_to_packed(load("res://SongSelect.tscn"))
		":q":
			if changes_done:
				send_notification("Can't quit with unsaved changes.")
			else :
				get_tree().change_scene_to_packed(load("res://SongSelect.tscn"))
		":q!":
			get_tree().change_scene_to_packed(load("res://SongSelect.tscn"))
		":set":
			if cmd.size() <= 1:
				send_notification(":set expects a setting and its new value")
			elif cmd.size() == 2:
				var arg:Array = cmd[1].split("=")
				if arg.size() == 1:
					send_notification("Expected format is :set setting=new_value")
				elif arg.size() == 2:
					var setting:String = arg[0]
					var newval:String = arg[1]
					set_setting(setting, newval)
			elif cmd.size() == 3:
				var setting:String = cmd[1].trim_suffix("=")
				var newval:String = cmd[2].trim_prefix("=")
				set_setting(setting, newval)
			elif cmd.size() == 4:
				if cmd[2] != "=":
					send_notification("Too many arguments! Did you mistype an equals sign?")
				else :
					var setting:String = cmd[1]
					var newval:String = cmd[3]
					set_setting(setting, newval)
		":help":
			_on_mode_change_requested(4)
		":issorted":
			if cmd.size() == 1:
				for lane_idx in conductor.notes.size():
					var is_sorted: = true
					for note_idx in conductor.notes[lane_idx].size() - 1:
						var note:NoteData = conductor.notes[lane_idx][note_idx]
						var next_note:NoteData = conductor.notes[lane_idx][note_idx + 1]
						if note.start_beat_number > next_note.start_beat_number:
							is_sorted = false
							send_notification("Lane %s has a discontinuity at position %s" % [lane_idx, note_idx])
							break
					if is_sorted:
						send_notification("Lane %s has no discontinuities" % lane_idx)
			else :
				send_notification("issorted doesn't expect any arguments")
		":findnote":
			if cmd.size() == 1:
				send_notification("findnote expects a decimal number")
			elif cmd.size() == 2:
				if not cmd[1].is_valid_float():
					send_notification("findnote expects a decimal number")
				else :
					for idx in conductor.notes.size():
						var lane:Array = conductor.notes[idx]
						send_notification("Found note at index %s in lane %s" % [find_note_idx_at_beat(lane, cmd[1] as float), idx])
			else :
				send_notification("findnote expects only one argument")
		":findcnote":
			if cmd.size() == 1:
				send_notification("findnote expects a decimal number")
			elif cmd.size() == 2:
				if not cmd[1].is_valid_float():
					send_notification("findnote expects a decimal number")
				else :
					for idx in conductor.notes.size():
						var lane:Array = conductor.notes[idx]
						send_notification("Found note at index %s in lane %s" % [find_note_idx_at_beat(lane, cmd[1] as float, true), idx])
			else :
				send_notification("findnote expects only one argument")


func save_level_files():
	var data: = {
		"file_ver":0, 
		"notes":[]
	}
	for i in conductor.notes[0]:
		data.notes.append(i.get_as_dict())
	for i in conductor.notes[2]:
		data.notes.append(i.get_as_dict())
	for i in conductor.notes[1]:
		data.notes.append(i.get_as_dict())
	var save_file: = FileAccess.open(Global.song_data.path + "/level.luna", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(data))
	save_file.close()
	save_file = FileAccess.open(Global.song_data.path + "/data.txt", FileAccess.WRITE)
	save_file.store_string(JSON.stringify(Global.song_data.get_as_dict(), "	"))
	save_file.close()
	send_notification("Saved")
	changes_done = false


func set_setting(setting:String, value:String):
	match setting:
		"bpm":
			if value.is_valid_float():
				changes_done = true
				Global.song_data.bpm = float(value)
				conductor.bpm = float(value)
				conductor.crotchet = 60.0 / conductor.bpm
				send_notification("Set song bpm to %s" % conductor.bpm)
			else :
				send_notification("Song bpm expects a decimal value")
		"crotchet":
			if value.is_valid_float():
				changes_done = true
				conductor.crotchet = float(value)
				Global.song_data.bpm = 60.0 / float(value)
				conductor.bpm = 60.0 / float(value)
				send_notification("Set song crotchet to %ss" % conductor.bpm)
			else :
				send_notification("Song crotchet expects a decimal value")
		"title":
			changes_done = true
			Global.song_data.song_name = value
			send_notification("Song title set to %s" % value)
		"author":
			changes_done = true
			Global.song_data.song_author = value
			send_notification("Song author set to %s" % value)
		"viewgrid":
			match value.to_lower():
				"true":editor_view_grid = true
				"false":editor_view_grid = false
				_:send_notification("viewgrid setting expects true or false as values")
		"gridnumbers":
			editor_grid_forced_update = true
			match value.to_lower():
				"mixed":editor_settings_gridnumbers = 1
				"fraction":editor_settings_gridnumbers = 2
				"decimal":editor_settings_gridnumbers = 3
				"off":editor_settings_gridnumbers = 0
				_:send_notification("viewgrid setting expects mixed, fraction, decimal or off as values")
		"speed":
			if value.is_valid_float():
				music_player.pitch_scale = float(value)
				send_notification("Sonw will play at %s times the speed" % setting)
			else :
				send_notification("speed setting expects a decimal value")
		_:send_notification("Unknown setting %s" % setting)


func add_remove_note(array_to: Array, note_data:NoteData) -> Array:
	if array_to.is_empty():
		array_to.append(note_data)
	elif note_data.start_beat_number < array_to[0].start_beat_number:
		array_to.push_front(note_data)
	elif note_data.start_beat_number > array_to[-1].start_beat_number:
		array_to.append(note_data)
	else:
		for idx in array_to.size():
			var note:NoteData = array_to[idx]
			if abs(note.start_beat_number - note_data.start_beat_number) < 0.01:
				array_to.remove_at(idx)
				break
			elif note.start_beat_number > note_data.start_beat_number:
				var thing: = array_to.slice(0, idx)
				thing.append(note_data)
				thing.append_array(array_to.slice(idx, array_to.size()))
				array_to = thing
				break
	return array_to


func send_notification(text:String)->void :
	var label: = Label.new()
	label.text += text + "\n"
	editor_notifications.add_child(label)
	var tw: = label.create_tween()
	tw.tween_property(label, "modulate:a", 0.0, 5.0)
	tw.connect("finished", Callable(self, "_on_notif_died").bind(label))


func _on_notif_died(label:Label)->void :
	label.queue_free()


func _on_command_focus_entered()->void :
	editor_mode = 1


func _on_command_focus_exited()->void :
	editor_mode = 0
	command_line.text = ""



func _notification(what:int)->void :
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not changes_done:
			get_tree().quit()
		else :
			send_notification("There are unsaved changes!")


func refresh_lane(lane:int)->void :
	var referrents: = []
	for node in note_display.get_children():
		if node.lane == lane + 1:
			referrents.append(node)
	while referrents.size() > conductor.notes[lane].size():
		referrents.pop_back().queue_free()
	for idx in conductor.notes[lane].size():
		var notedata:NoteData = conductor.notes[lane][idx]
		if idx < referrents.size():
			var referrent:Node = referrents[idx]
			referrent.align_to_note_data(notedata)
		else :
			add_editor_note_child(notedata)


func add_editor_note_child(note_data:NoteData)->Node:
	var new_note_node = preload("res://Note.tscn").instantiate()
	new_note_node.hit_beat_number = note_data.start_beat_number
	if note_data.is_sustain():
		new_note_node.release_beat_number = note_data.end_beat_number
	new_note_node.sustain = note_data.is_sustain()
	new_note_node.lane = note_data.lane + 1
	new_note_node.conductor = conductor
	new_note_node.modulate = Global.song_data.color2
	if randi() % 2 == 0:
		new_note_node.modulate = Global.song_data.color1
	note_display.add_child(new_note_node)
	return new_note_node


func setup_note_nodes(note_array:Array):
	var previous_beat_time = - 1.0
	var previous_note_node = null
	
	for note_data in note_array:
		var new_note_node = preload("res://Note.tscn").instantiate()
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


func _on_set_gridsize_requested(to:Fraction):
	editor_grid_fraction = to
	editor_scroll_grid = to.as_float()
	send_notification("Grid size set to %s" % to.as_string())

func _on_set_scroll_speed_requested(to:Fraction):
	editor_scroll_speed = to.as_float()
	send_notification("Scroll speed set to %s" % to.as_string())

func _on_align_cursor_to_grid_requested():
	editor_beat = snapped(editor_beat, editor_scroll_grid)
	send_notification("Aligned cursor to grid")

func _on_notification_requested(notification:String):
	send_notification(notification)

func _on_align_scroll_speed_to_grid_requested():
	editor_scroll_speed = editor_scroll_grid
	send_notification("Aligned scroll speed with grid")

func _on_add_remove_note_requested(lane):
	changes_done = true
	editor_making_sustains[lane] = null
	var new_note: = NoteData.new()
	new_note.lane = lane
	new_note.start_beat_number = editor_beat
	conductor.notes[lane] = add_remove_note(conductor.notes[lane], new_note)
	refresh_lane(lane)

func _on_add_specific_notes_requested(notes:Array):
	changes_done = true
	for note in notes:
		conductor.notes[note.lane] = add_remove_note(conductor.notes[note.lane], note)
	refresh_lane(0)
	refresh_lane(1)
	refresh_lane(2)

func _on_start_finish_sustain_requested(lane):
	changes_done = true
	if editor_making_sustains[lane] == null:
		editor_making_sustains[lane] = NoteData.new()
		editor_making_sustains[lane].start_beat_number = editor_beat
		editor_making_sustains[lane].lane = lane
	else :
		editor_making_sustains[lane].lane = lane
		if editor_beat > editor_making_sustains[lane].start_beat_number:
			editor_making_sustains[lane].end_beat_number = editor_beat
			conductor.notes[lane] = add_remove_note(conductor.notes[lane], editor_making_sustains[lane])
			refresh_lane(lane)
		elif editor_beat < editor_making_sustains[lane].start_beat_number:
			editor_making_sustains[lane].end_beat_number = editor_making_sustains[lane].start_beat_number
			editor_making_sustains[lane].start_beat_number = editor_beat
			conductor.notes[lane] = add_remove_note(conductor.notes[lane], editor_making_sustains[lane])
			refresh_lane(lane)
		editor_making_sustains[lane] = null

func _on_scroll_requested(amount:float):
	editor_beat = max(0, editor_beat + amount * editor_scroll_speed)
	
func _on_arbitrary_scroll_requested(amount:float):
	editor_beat = max(0, editor_beat + amount)

func _on_scroll_to_requested(to:float):
	if to >= 0.0:
		editor_beat = to
		send_notification("Scrolled to beat %s" % to)
	else :
		editor_beat = get_max_beat() - to - 1
		send_notification("Scrolled to beat %s" % (get_max_beat() - to - 1))

func _on_mode_change_requested(to:int):
	if to == 1:
		command_line.grab_focus()
	elif editor_mode == 1:
		command_line.release_focus()
		command_line.text = ""
	
	if to == 3:
		paste_mode.selection_cursor = select_mode.selection_cursor
		paste_mode.preview_position = editor_beat
	
	if to == 4:
		$Help.visible = true
	
	editor_mode = to

func _on_raise_requested(requested_amt:float):
	var amt:float = editor_scroll_grid * sign(requested_amt) if is_inf(requested_amt) else requested_amt
	changes_done = true
	
	for lane_data in conductor.notes:
		for idx in range(max(find_note_idx_at_beat(lane_data, editor_beat, true) - 3, 0), lane_data.size()):
			var note:NoteData = lane_data[idx]
			if note.start_beat_number >= editor_beat:
				note.start_beat_number += amt
				if note.is_sustain():
					note.end_beat_number += amt
				sort_note_array_at(lane_data, idx)
	
	send_notification("%s everything above cursor by %s" % ["Raised" if amt > 0 else "Lowered", abs(amt)])
		
	refresh_lane(0)
	refresh_lane(1)
	refresh_lane(2)

func _on_raise_selection_requested(selections:Array, requested_amt:float):
	var amt:float = editor_scroll_grid * sign(requested_amt) if is_inf(requested_amt) else requested_amt
	changes_done = true
	var already_raised: = []
	
	for selection in selections:
		selection = selection as Selection
		for lane_data in conductor.notes:
			for idx in range(max(find_note_idx_at_beat(lane_data, selection.start.y, true) - 3, 0), lane_data.size()):
				var note:NoteData = lane_data[idx]
				if note in already_raised:continue
				already_raised.append(note)
				if selection.has_point(Vector2(note.lane, note.start_beat_number)):
					note.start_beat_number += amt
					if note.is_sustain():
						note.end_beat_number += amt
					sort_note_array_at(lane_data, idx)
		selection.end.y += amt
		selection.start.y += amt
	
	var selection_was_empty = already_raised.is_empty()
	
	if not selection_was_empty:
		send_notification("%s everything in selection by %s" % ["Raised" if amt > 0 else "Lowered", abs(amt)])
	else :
		send_notification("Nothing was %s" % "raised" if amt > 0 else "lowered")
	
	
	refresh_lane(0)
	refresh_lane(1)
	refresh_lane(2)

func _on_put_selection_in_clipboard_requested(clipboard, selections):
	var selected_notes: = []
	var total_minimum: = Vector2(INF, INF)
	
	for selection in selections:
		selection = selection as Selection
		total_minimum.y = min(selection.start.y, total_minimum.y)
		total_minimum.x = min(selection.start.x, total_minimum.x)
		for lane_data in conductor.notes:
			for note_idx in range(max(find_note_idx_at_beat(lane_data, selection.start.y, true) - 3, 0), lane_data.size()):
				var note:NoteData = lane_data[note_idx]
				if note.start_beat_number > selection.end.y:
					break
				if not selection.has_point(note.get_vector()):
					continue
				if note in selected_notes:continue
				selected_notes.append(note)
	
	if selected_notes.is_empty():
		send_notification("Selection is empty, clipboard %s remains unchanged" % clipboard)
		return 
	
	var new_clip: = []
	
	for original_note in selected_notes:
		var note:NoteData = (original_note as NoteData).duplicate()
		note.lane -= select_mode.selection_cursor
		note.start_beat_number -= total_minimum.y
		if note.is_sustain():note.end_beat_number -= total_minimum.y
		new_clip.append(note)
	
	clipboards[clipboard] = new_clip
	send_notification("Copied selection into the %s clipboard" % clipboard)


func _on_delete_selection_requested(selections):
	var total_minimum: = Vector2(0, 0)
	changes_done = true
	for selection in selections:
		selection = selection as Selection
		total_minimum.y = min(selection.start.y, total_minimum.y)
		total_minimum.x = min(selection.start.x, total_minimum.x)
		for lane_data in conductor.notes:
			var idx:int = - 1 + max(find_note_idx_at_beat(lane_data, selection.start.y, true) - 3, 0)
			while idx < lane_data.size():
				idx += 1
				var note:NoteData = lane_data[idx]
				if note.start_beat_number > selection.end.y:break
				if not selection.has_point(note.get_vector()):continue
				lane_data.pop_at(idx)
				idx -= 1
	
	refresh_lane(0)
	refresh_lane(1)
	refresh_lane(2)
	
	send_notification("Removed selected notes from chart")

func sort_note_array_at(array:Array, at:int):
	var note_at:NoteData = array[at]
	var note_next:NoteData = null if at == array.size() - 1 else array[at + 1]
	var note_prev:NoteData = null if at == 0 else array[at - 1]
	
	if note_prev != null:
		if note_prev.start_beat_number > note_at.start_beat_number:
			array[at - 1] = note_at
			array[at] = note_prev
			sort_note_array_at(array, at - 1)
			note_at = array[at]
			note_prev = array[at - 1]
	if note_next != null:
		if note_next.start_beat_number < note_at.start_beat_number:
			array[at + 1] = note_at
			array[at] = note_next
			sort_note_array_at(array, at + 1)


func _on_keybind_clear_requested():
	editor_command = ""

func get_max_beat()->float:
	var max_beat: = 0.0
	if not conductor.notes[2].is_empty():
		max_beat = conductor.notes[2][ - 1].start_beat_number
		if conductor.notes[2][ - 1].is_sustain():
			max_beat = conductor.notes[2][ - 1].end_beat_number
	if not conductor.notes[1].is_empty():
		max_beat = max(max_beat, conductor.notes[1][ - 1].start_beat_number)
		if conductor.notes[1][ - 1].is_sustain():
			max_beat = conductor.notes[1][ - 1].end_beat_number
	if not conductor.notes[0].is_empty():
		max_beat = max(max_beat, conductor.notes[0][ - 1].start_beat_number)
		if conductor.notes[0][ - 1].is_sustain():
			max_beat = conductor.notes[0][ - 1].end_beat_number
	return max_beat


func find_note_idx_at_beat(array:Array, beat:float, closest: = false)->int:
	var size: = array.size()
	var idx: = size / 2
	var depth: = 4
	var midnote:NoteData = array[idx]
	var foundbeat: = midnote.start_beat_number
	var reached_limit: = 0
	var closest_find: = idx
	while true:
		var delta: = size / depth
		if delta > 1:
			depth *= 2
		else :
			delta = 1
		if abs(beat - midnote.start_beat_number) < 0.01:
			return idx
		if delta == 1:
			if reached_limit == size / 2:
				return - 1 if not closest else idx
			else :reached_limit += 1
		if beat > midnote.start_beat_number:
			idx += delta
		elif beat < midnote.start_beat_number:
			idx -= delta
		if idx < 0:return - 1 if not closest else 0
		if idx > size - 1:return - 1 if not closest else size - 1
		midnote = array[idx]
		foundbeat = midnote.start_beat_number
	return idx
