extends Control


var song: = 0
var total_songs: = - 1

var song_list: = []

var current_menu: = "main"
var menu_tween:SceneTreeTween


func _ready()->void :
	song_list.append_array(load_songs("res://songs"))
	song_list.append_array(load_songs("user://songs"))
	
	
	if song >= song_list.size():
		song = 0
	elif song < 0:
		song = song_list.size() - 1
	
	_on_menu_change_requested(Global.to_menu)


func _input(event:InputEvent)->void :
	pass


func load_songs(song_directory:String)->Array:
	var return_value: = []
	
	var songs_dir: = Directory.new()
	if not songs_dir.dir_exists(song_directory):
		songs_dir.make_dir(song_directory)
	songs_dir.open(song_directory)
	songs_dir.list_dir_begin(true, true)
	
	var current_file: = songs_dir.get_next()
	
	while current_file != "":
		if songs_dir.current_is_dir():
			var new_song_data: = SongData.new()
			var data_file: = File.new()
			if data_file.file_exists(song_directory + "/%s/data.txt" % current_file) and (data_file.file_exists(song_directory + "/%s/level.txt" % current_file) or data_file.file_exists(song_directory + "/%s/level.luna" % current_file)):
				data_file.open(song_directory + "/%s/data.txt" % current_file, File.READ)
				var jsonres: = JSON.parse(data_file.get_as_text())
				if jsonres.error != OK:
					push_error("Failed to read file %s: %s at line %s" % [current_file, jsonres.error_string, jsonres.error_line])
				else :
					new_song_data.set_from_dict(jsonres.result)
					new_song_data.path = song_directory + "/" + current_file
					return_value.append(new_song_data)
					if song_directory.begins_with("user://"):
						new_song_data.editable = true
					else :new_song_data.editable = OS.has_feature("editor")
					var play_data: = {}
					var song_access_hash = Global.get_song_access_hash(new_song_data.path)
					if Global.game_data.has_section_key("songs", song_access_hash + "_score"):
						play_data = {
							"score":Global.game_data.get_value("songs", song_access_hash + "_score"), 
							"combo":Global.game_data.get_value("songs", song_access_hash + "_combo"), 
						}
					$Songs.add_display(new_song_data, play_data)
			
		current_file = songs_dir.get_next()
	
	return return_value


func get_color_from_text(s:String, default:Color)->Color:
	if s == "default":
		return default
	elif s.is_valid_html_color():
		return Color(s)
	else :
		return default


func _on_menu_change_requested(to:String)->void :
	if menu_tween != null and menu_tween.is_valid():
		menu_tween.kill()
	
	match to:
		"main":
			$Main.visible = true
			menu_tween = create_tween()
			menu_tween.tween_property($Main, "modulate:a", 1.0, 0.2)
			if current_menu == "songs" or current_menu == "songs_editor":
				menu_tween.parallel().tween_property($Logo, "modulate:a", 1.0, 0.2)
				menu_tween.parallel().tween_property($Songs, "modulate:a", 0.0, 0.2)
				menu_tween.parallel().tween_property($Songs, "visible", false, 0.2)
			if current_menu == "settings":
				menu_tween.parallel().tween_property($Settings, "modulate:a", 0.0, 0.2)
				menu_tween.parallel().tween_property($Settings, "visible", false, 0.2)
		"settings":
			menu_tween = create_tween()
			$Settings.visible = true
			menu_tween.parallel().tween_property($Main, "modulate:a", 0.0, 0.2)
			menu_tween.parallel().tween_property($Main, "visible", false, 0.2)
			menu_tween.parallel().tween_property($Settings, "modulate:a", 1.0, 0.2)
		"songs":
			menu_tween = create_tween()
			$Songs.visible = true
			menu_tween.tween_property($Songs, "modulate:a", 1.0, 0.2)
			menu_tween.parallel().tween_property($Logo, "modulate:a", 0.0, 0.2)
			menu_tween.parallel().tween_property($Main, "modulate:a", 0.0, 0.2)
			menu_tween.parallel().tween_property($Main, "visible", false, 0.2)
			$Songs.use_editor = false
		"songs_editor":
			menu_tween = create_tween()
			$Songs.visible = true
			menu_tween.tween_property($Songs, "modulate:a", 1.0, 0.2)
			menu_tween.parallel().tween_property($Logo, "modulate:a", 0.0, 0.2)
			menu_tween.parallel().tween_property($Main, "modulate:a", 0.0, 0.2)
			menu_tween.parallel().tween_property($Main, "visible", false, 0.2)
			$Songs.use_editor = true
				
	
	current_menu = to


func _on_play_song_requested(songid)->void :
	Global.song_data = song_list[song]
	Global.using_editor = $Songs.use_editor
	$SceneExit.change_scene_to("res://Game.tscn")
