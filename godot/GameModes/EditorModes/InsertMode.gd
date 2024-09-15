extends EditorMode


func parse_command(editor:EditorGameMode):
	var current_parse: = ""
	for input_string in editor.editor_command.split(">", false):
		if input_string is String:
			var clear: = false
			var input: = - 1
			if input_string.begins_with("S-"):
				input = input_string.lstrip("fS-") as int
				clear = true
				match input:
					KEY_1:
						emit_signal("set_gridsize_request", Fraction.new(1.0, 1.0))
						emit_signal("set_scroll_speed_request", Fraction.new(1.0, 1.0))
						emit_signal("align_cursor_to_grid_request")
					KEY_2:
						emit_signal("set_gridsize_request", Fraction.new(1.0, 2.0))
						emit_signal("set_scroll_speed_request", Fraction.new(1.0, 2.0))
						emit_signal("align_cursor_to_grid_request")
					KEY_3:
						emit_signal("set_gridsize_request", Fraction.new(1.0, 4.0))
						emit_signal("set_scroll_speed_request", Fraction.new(1.0, 4.0))
						emit_signal("align_cursor_to_grid_request")
					KEY_4:
						emit_signal("set_gridsize_request", Fraction.new(1.0, 8.0))
						emit_signal("set_scroll_speed_request", Fraction.new(1.0, 8.0))
						emit_signal("align_cursor_to_grid_request")
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
					KEY_A:
						emit_signal("start_finish_sustain_request", 0)
					KEY_S:
						emit_signal("start_finish_sustain_request", 1)
					KEY_D:
						emit_signal("start_finish_sustain_request", 2)
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
						clear = true
						emit_signal("add_remove_note_request", 0)
					KEY_S:
						clear = true
						emit_signal("add_remove_note_request", 1)
					KEY_D:
						clear = true
						emit_signal("add_remove_note_request", 2)
					KEY_G:
						if current_parse == "g" or Util.is_valid_fraction(current_parse):
							clear = true
							var destination: = 0.0 if current_parse == "g" else Util.frac_to_float(current_parse)
							emit_signal("scroll_to_request", destination)
					KEY_L:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = INF if current_parse.is_empty() else Util.frac_to_float(current_parse)
							emit_signal("raise_request", amt)
					KEY_H:
						clear = true
						if Util.is_valid_fraction(current_parse) or current_parse.is_empty():
							var amt: = INF if current_parse.is_empty() else Util.frac_to_float(current_parse)
							emit_signal("raise_request", - amt)
					
					KEY_V:
						clear = true
						emit_signal("mode_change_request", 2)
					
					KEY_MINUS, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
						pass
					KEY_SHIFT:
						continue
					_:
						clear = true
			
			if input != KEY_SHIFT:
				if not clear:
					current_parse += Util.get_key_string(input)
				else :
					emit_signal("keybind_clear_request")
					current_parse = ""
