extends EditorMode




var selection_cursor: = 1
@onready var select_mode_cursor: = $"../CursorX"
@onready var selection_display: = $"../Selections"
@onready var paste_mode: = $"../PasteMode"

var editor_selections: = []
var editing_selection:Selection = null



func process(delta:float, editor:EditorGameMode):
	draw_selections(editor)


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
					KEY_V:
						clear = true
						editor_selections.clear()
						editing_selection = null
					KEY_R:
						clear = true
						emit_signal("put_selection_in_clipboard_request", 1, editor_selections)
						emit_signal("delete_selection_request", editor_selections)
					KEY_P:
						clear = true
						paste_mode.selection_cursor = selection_cursor
						paste_mode.selected_clipboard = 0
						if editor.clipboards.has(0):
							emit_signal("mode_change_request", 3)
						else :
							emit_signal("notification_request", "Clipboard 0 is empty, so it can't be pasted")
					KEY_PERIOD:
						emit_signal("mode_change_request", 1)
				
			else :
				input = input_string as int
				match input:
					KEY_K:
						clear = true
						if current_parse.is_empty() or current_parse.is_valid_int():
							var amt: = 1 if current_parse.is_empty() else (current_parse as int)
							emit_signal("scroll_request", amt)
					KEY_J:
						clear = true
						if current_parse.is_empty() or current_parse.is_valid_int():
							var amt: = 1 if current_parse.is_empty() else (current_parse as int)
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
						selection_cursor = max(selection_cursor - 1, 0)
						clear = true
					KEY_D:
						selection_cursor = min(selection_cursor + 1, 2)
						clear = true
					KEY_G:
						if current_parse == "g" or Util.is_valid_fraction(current_parse):
							clear = true
							var destination: = 0.0 if current_parse == "g" else Util.frac_to_float(current_parse)
							emit_signal("scroll_to_request", destination)
					KEY_H:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = INF if current_parse.is_empty() else Util.frac_to_float(current_parse)
							emit_signal("raise_selection_request", editor_selections, amt)
					KEY_L:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = INF if current_parse.is_empty() else Util.frac_to_float(current_parse)
							emit_signal("raise_selection_request", editor_selections, - amt)
					
					KEY_F:
						clear = true
						if editing_selection == null:
							var removed_selection: = false
							for idx in editor_selections.size():
								var selection:Selection = editor_selections[idx]
								if selection.has_point(Vector2(selection_cursor, editor.editor_beat)):
									editor_selections.pop_at(idx)
									removed_selection = true
									break
							if not removed_selection:
								editing_selection = Selection.new()
								editing_selection.start = Vector2(selection_cursor, editor.editor_beat)
						else :
							editing_selection.end = Vector2(selection_cursor, editor.editor_beat)
							editing_selection.organize()
							editor_selections.append(editing_selection)
							editing_selection = null
					
					KEY_Y:
						clear = true
						if current_parse.is_empty():
							emit_signal("put_selection_in_clipboard_request", 1, editor_selections)
						elif not current_parse.is_valid_int():
							emit_signal("notification_request", "Expected a single digit number (clipboard referrent)")
						elif current_parse.length() > 1:
							emit_signal("notification_request", "Clipboards are identified with single digits")
						else :
							emit_signal("put_selection_in_clipboard_request", current_parse as int, editor_selections)
					KEY_R:
						clear = true
						if current_parse.is_empty():
							emit_signal("put_selection_in_clipboard_request", 0, editor_selections)
							emit_signal("delete_selection_request", editor_selections)
							editor_selections.clear()
							editing_selection = null
						elif not current_parse.is_valid_int():
							emit_signal("notification_request", "Expected a single digit number (clipboard referrent)")
						elif current_parse.length() > 1:
							emit_signal("notification_request", "Clipboards are identified with single digits")
						else :
							emit_signal("put_selection_in_clipboard_request", current_parse as int, editor_selections)
							emit_signal("delete_selection_request", editor_selections)
							editor_selections.clear()
							editing_selection = null
					KEY_P:
						clear = true
						paste_mode.selection_cursor = selection_cursor
						if current_parse.is_empty():
							paste_mode.selected_clipboard = 1
							if editor.clipboards.has(1):
								emit_signal("mode_change_request", 3)
							else :
								emit_signal("notification_request", "Clipboard 1 is empty, so it ca't be pasted")
						elif not current_parse.is_valid_int():
							emit_signal("notification_request", "Expected a single digit number (clipboard referrent)")
						elif current_parse.length() > 1:
							emit_signal("notification_request", "Clipboards are identified with single digits")
						elif not editor.clipboards.has(current_parse as int):
							emit_signal("notification_request", "Clipboards %s is empty, so it can't be pasted" % current_parse)
						else :
							paste_mode.selected_clipboard = current_parse as int
							emit_signal("mode_change_request", 3)
					
					KEY_MINUS, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
						pass
					KEY_SHIFT:
						continue
					KEY_ESCAPE:
						if current_parse == "":
							editing_selection = null
							editor_selections.clear()
							emit_signal("mode_change_request", 0)
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


func draw_selections(editor:EditorGameMode):
	select_mode_cursor.visible = editor.editor_mode == 2
	if editor.editor_mode == 2:
		match selection_cursor:
			0:select_mode_cursor.position.x = 378
			1:select_mode_cursor.position.x = 480
			2:select_mode_cursor.position.x = 578
	select_mode_cursor.modulate = Color(0, 0.505882, 1) if editing_selection == null else Color(0, 1, 0.0625)
	var plus: = 0 if editing_selection == null else 1
	while selection_display.get_child_count() > editor_selections.size() + plus:
		selection_display.get_child(0).free()
	while selection_display.get_child_count() < editor_selections.size() + plus:
		var new_panel: = Panel.new()
		selection_display.add_child(new_panel)
	
	for idx in editor_selections.size() + plus:
		var child: = selection_display.get_child(idx)
		var selection:Selection = editor_selections[idx] if idx != editor_selections.size() else editing_selection
		if idx != editor_selections.size():
			child.position.x = lerp(child.position.x, selection.start.x * selection_display.size.x / 3.0, 0.2)
			child.position.y = lerp(child.position.y, selection.end.y * - Global.SCROLL_SPEED + 555 - 32 + editor.editor_beat * Global.SCROLL_SPEED, 0.2)
			child.size.x = (selection.end.x - selection.start.x + 1) * selection_display.size.x / 3.0
			child.size.y = (selection.end.y - selection.start.y) * Global.SCROLL_SPEED + 64
		else :
			var starty:float = min(editor.editor_beat, selection.start.y)
			var startx:float = min(selection_cursor, selection.start.x)
			var endy:float = max(editor.editor_beat, selection.start.y)
			var endx:float = max(selection_cursor, selection.start.x)
			child.position.x = lerp(child.position.x, startx * selection_display.size.x / 3.0, 0.2)
			child.position.y = lerp(child.position.y, 555 - 32 + (endy - editor.editor_beat) * - Global.SCROLL_SPEED, 0.2)
			child.size.x = lerp(child.size.x, (endx - startx + 1) * selection_display.size.x / 3.0, 0.2)
			child.size.y = lerp(child.size.y, (endy - starty) * Global.SCROLL_SPEED + 64, 0.2)
