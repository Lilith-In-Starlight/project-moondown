extends Node

const PASS := "asdjfow98fnqHJNPOhwlpfnaopvnQPOIHGVEAGNFQL�jf9iw"

const PERFECT_TIMING := 0.06
const INEXACT_PERFECT_TIMING := 0.1
const OKAY_TIMING := 0.2

var SCROLL_SPEED := 300.0

var song_data: SongData = null

var using_editor := false

var game_data := ConfigFile.new()

var to_menu := "main"


func _ready() -> void:
	load_data()


func save_data():
	game_data.save_encrypted_pass("user://heart.soul", PASS)


func load_data():
	var err = game_data.load_encrypted_pass("user://heart.soul", PASS)
	if err != OK:
		game_data.save_encrypted_pass("user://heart.soul", PASS)


func get_song_access_hash(song_path):
	var level_data := FileAccess.get_sha256(song_path + "/level.txt")
	var data_data := FileAccess.get_sha256(song_path + "/data.txt")
	var song_data = FileAccess.get_sha256(song_path + "/song.mp3")
	return str(level_data) + str(data_data) + str(hash(song_data))
