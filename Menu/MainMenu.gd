extends Control

signal menu_change_request(to)

onready var song_list:Control = $"../Songs/SongList"


func _on_play_pressed()->void :
	emit_signal("menu_change_request", "songs")

func _on_editor_pressed()->void :
	emit_signal("menu_change_request", "songs_editor")

func _on_quit_pressed()->void :
	$"../SceneExit".quit()

func _on_settings_pressed()->void :
	emit_signal("menu_change_request", "settings")
