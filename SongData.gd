extends Node


class_name SongData

var song_name: = ""
var song_author: = ""
var bpm: = 100.0
var path: = ""
var styled: = false
var bg_color: = Color("4a2025")
var color1: = Color("#ff7a1b")
var color2: = Color("#ff4879")
var playfield: = Color("#28100a")
var play_lines: = Color("#d91b4e")
var play_last_line = Color("#ffb300")
var combo_note_color = Color("#ffb300")
var difficulty = - 1

var editable: = false


func set_from_dict(data:Dictionary)->void :
	song_name = data["title"]
	song_author = data["author"]
	bpm = data["bpm"]
	difficulty = data["difficulty"] if "difficulty" in data else - 1
	if data.has("style"):
		styled = true
		var style:Dictionary = data["style"]
		bg_color = Color(style["bg_color"]) if style.has("bg_color") else bg_color
		color1 = Color(style["note_colors"][0]) if style.has("note_colors") else color1
		color2 = Color(style["note_colors"][1]) if style.has("note_colors") else color2
		combo_note_color = Color(style["combo_note_color"]) if style.has("combo_note_color") else combo_note_color
		if style.has("playfield"):
			var playstyle:Dictionary = style["playfield"]
			playfield = Color(style["bg_color"]) if style.has("bg_color") else playfield
			play_lines = Color(style["lines"]) if style.has("lines") else play_lines
			play_last_line = Color(style["last_line"]) if style.has("last_line") else play_last_line


func get_as_dict()->Dictionary:
	var data: = {
		"title":song_name, 
		"author":song_author, 
		"bpm":bpm, 
		"difficulty": - 1, 
	}
	var style:Dictionary = {
		"bg_color":bg_color.to_html(), 
		"note_colors":[color1.to_html(), color2.to_html()], 
		"combo_note_color":combo_note_color.to_html(), 
		"playfield":{
			"bg_color":playfield.to_html(), 
			"lines":play_lines.to_html(), 
			"last_line":play_last_line.to_html()
		}, 
	}
	data["style"] = style
	return data


static func get_difficulty_name(d:int)->String:
	if d == - 1:return "Unset!"
	var ret: = ""
	for idx in d + 1:
		ret += "?!"
	return ret
