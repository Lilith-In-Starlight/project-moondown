extends Node

class_name EditorMode


signal set_gridsize_request(to)
signal set_scroll_speed_request(to)
signal align_cursor_to_grid_request()
signal align_scroll_speed_to_grid_request()

signal scroll_request(amount)
signal arbitrary_scroll_request(amount)
signal scroll_to_request(amount)

signal raise_request(amount)
signal raise_selection_request(selections, amount)

signal mode_change_request(to)

signal add_remove_note_request(lane)
signal add_specific_notes_request(notes)
signal start_finish_sustain_request(lane)

signal put_selection_in_clipboard_request(clipboard, selections)
signal delete_selection_request(selections)

signal notification_request(notification)

signal keybind_clear_request()
