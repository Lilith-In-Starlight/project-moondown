extends EditorMode


var selection_cursor: = 1
var preview_position: = 0.0
var selected_clipboard: = 0

@onready var select_mode_cursor: = $"../CursorX"
@onready var selection_display: = $"../Selections"
@onready var preview_display: = $"../PastePreview"


func process(delta:float, editor:EditorGameMode):
	var amt:int = editor.clipboards[selected_clipboard].size() if editor.editor_mode == 3 else 0
	
	while preview_display.get_child_count() > amt:
		preview_display.get_child(0).free()
	while amt > preview_display.get_child_count():
		var new_note: = TextureRect.new()
		new_note.texture = preload("res://Sprites/BeatMagenta.png")
		preview_display.add_child(new_note)
	for idx in preview_display.get_child_count():
		var child:TextureRect = preview_display.get_child(idx)
		var note:NoteData = editor.clipboards[selected_clipboard][idx]
		var glane: = note.lane - 1 + selection_cursor

		child.position.x = 100 * wrapi(glane, - 1, 2) + (preview_display.size.x / 2.0) - 32
		child.position.y = note.start_beat_number * - Global.SCROLL_SPEED - 32
		if note.is_sustain() and child.get_child_count() == 0:
			var trail: = TextureRect.new()
			trail.texture = preload("res://Sprites/Sustain1.png")
			trail.scale.y = (note.end_beat_number - note.start_beat_number) * Global.SCROLL_SPEED / 64.0
			trail.position.y = (note.end_beat_number - note.start_beat_number) * - Global.SCROLL_SPEED
			child.add_child(trail)
		elif not note.is_sustain() and child.get_child_count() > 0:
			child.get_child(0).free()
	
	preview_display.position.y = lerp(preview_display.position.y, (editor.editor_beat - preview_position) * Global.SCROLL_SPEED + 513, 0.2)


func parse_command(editor:EditorGameMode):
	var current_parse: = ""
	for input_string in editor.editor_command.split(">", false):
		if input_string is String:
			var clear: = false
			var input: = - 1
			if input_string.begins_with("S-"):
				input = input_string.lstrip("S-") as int
				clear = true
				match input:
					KEY_J:
						if current_parse.is_empty():
							emit_signal("scroll_request", - 0.25)
						elif Util.is_valid_fraction(current_parse):
							emit_signal("arbitrary_scroll_request", - Util.frac_to_float(current_parse))
					KEY_K:
						if current_parse.is_empty():
							emit_signal("scroll_request", 0.25)
						elif Util.is_valid_fraction(current_parse):
							emit_signal("arbitrary_scroll_request", Util.frac_to_float(current_parse))
					KEY_N:
						emit_signal("align_cursor_to_grid_request")
					KEY_M:
						emit_signal("align_scroll_speed_to_grid_request")
					KEY_G:
						emit_signal("scroll_to_request", - 1)
					KEY_PERIOD:
						emit_signal("mode_change_request", 1)
				
			else :
				input = input_string as int
				match input:
					KEY_K:
						clear = true
						if current_parse.is_empty() or current_parse.is_valid_int():
							var amt: = 1 if current_parse.is_empty() else current_parse as int
							emit_signal("scroll_request", amt)
					KEY_J:
						clear = true
						if current_parse.is_empty() or current_parse.is_valid_int():
							var amt: = 1 if current_parse.is_empty() else current_parse as int
							emit_signal("scroll_request", - amt)
					KEY_M:
						clear = true
						if current_parse.is_empty() or Util.is_valid_fraction(current_parse):
							var desired_val: = Fraction.new(1, 1) if current_parse.is_empty() else Util.frac_to_frac(current_parse)
							if desired_val == null:
								desired_val = Fraction.new(1, 1)
							emit_signal("set_scroll_speed_request", desired_val)
					KEY_N:
						clear = true
						if not current_parse.is_empty() and Util.is_valid_fraction(current_parse):
							var desired_val = Util.frac_to_frac(current_parse)
							if desired_val != null:
								emit_signal("set_gridsize_request", desired_val)
					KEY_A:
						selection_cursor = wrapi(selection_cursor - 1, 0, 3)
						clear = true
					KEY_D:
						selection_cursor = wrapi(selection_cursor + 1, 0, 3)
						clear = true
					KEY_S:
						for note in editor.clipboards[selected_clipboard]:
							note.lane = 2 - note.lane
						clear = true
					KEY_G:
						if current_parse == "g" or Util.is_valid_fraction(current_parse):
							clear = true
							var destination: = 0.0 if current_parse == "g" else Util.frac_to_float(current_parse)
							emit_signal("scroll_to_request", destination)
					KEY_H:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = editor.editor_scroll_grid if current_parse.is_empty() else Util.frac_to_float(current_parse)
							preview_position += amt
					KEY_L:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = editor.editor_scroll_grid if current_parse.is_empty() else Util.frac_to_float(current_parse)
							preview_position -= amt
					KEY_PERIOD:
						clear = true
						if current_parse.is_empty():
							emit_signal("notification_request", "Expected a single digit number (clipboard referrent)")
						elif not current_parse.is_valid_int():
							emit_signal("notification_request", "Expected a single digit number (clipboard referrent)")
						elif current_parse.length() > 1:
							emit_signal("notification_request", "Clipboards are identified with single digits")
						elif not editor.clipboards.has(current_parse as int):
							emit_signal("notification_request", "Clipboards %s is empty, so it can't be previewed" % current_parse)
						else :
							emit_signal("notification_request", "Previewing clipboard %s" % current_parse)
							selected_clipboard = current_parse as int
					
					KEY_P:
						clear = true
						var clip: = []
						for note in editor.clipboards[selected_clipboard]:
							var new_note:NoteData = note.duplicate()
							new_note.start_beat_number += preview_position
							var glane: = new_note.lane + selection_cursor
							new_note.lane = wrapi(glane, 0, 3)
							if new_note.is_sustain():new_note.end_beat_number += preview_position
							clip.append(new_note)
						emit_signal("add_specific_notes_request", clip)
						emit_signal("mode_change_request", 2)
					
					KEY_MINUS, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
						pass
					KEY_SHIFT:
						continue
					KEY_ESCAPE:
						if current_parse == "":
							emit_signal("mode_change_request", 2)
							clear = true
						else :
							clear = true
					_:
						clear = true
			
			if input != KEY_SHIFT:
				if not clear:
					current_parse += Util.get_key_string(input)
				else :
					emit_signal("keybind_clear_request")
					current_parse = ""
