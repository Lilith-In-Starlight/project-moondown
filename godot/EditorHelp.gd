extends Panel

@onready var table := $HelpWindow/HSplitContainer/Contents
@onready var text := $HelpWindow/HSplitContainer/Help

var beginning: TreeItem
var setting_up: TreeItem
var adding_notes: TreeItem
var select_mode: TreeItem
var keybinds: TreeItem
var commands: TreeItem

func _ready() -> void:
	var root: TreeItem = table.create_item()
	beginning = table.create_item(root)
	beginning.set_text(0, "Using the editor")
	setting_up = table.create_item(root)
	setting_up.set_text(0, "Set up a level's data")
	adding_notes = table.create_item(root)
	adding_notes.set_text(0, "Making your level")
	select_mode = table.create_item(root)
	select_mode.set_text(0, "Using select mode")
	keybinds = table.create_item(root)
	keybinds.set_text(0, "All keybinds")
	commands = table.create_item(root)
	commands.set_text(0, "All commands and properties")

func _on_contents_item_selected() -> void:
	var selected: TreeItem = table.get_selected()
	text.clear()
	if selected == beginning:
		var file := FileAccess.open("res://editorman/introduction.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()
	elif selected == setting_up:
		var file := FileAccess.open("res://editorman/song_setup.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()
	elif selected == adding_notes:
		var file := FileAccess.open("res://editorman/level_creation.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()
	elif selected == select_mode:
		var file := FileAccess.open("res://editorman/select_mode.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()
	elif selected == keybinds:
		var file := FileAccess.open("res://editorman/keybinds.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()
	elif selected == commands:
		var file := FileAccess.open("res://editorman/commands.txt", FileAccess.READ)
		text.text = file.get_as_text()
		file.close()

	var custom_formatted = text.text
	custom_formatted = custom_formatted.replace("[code]", "[code][color=#c53c00]")
	custom_formatted = custom_formatted.replace("[/code]", "[/color][/code]")
	text.text = custom_formatted
