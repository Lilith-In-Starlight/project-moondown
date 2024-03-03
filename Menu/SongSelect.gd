extends Control

signal menu_change_request(to)
signal play_song_request(songid)


const DISPLAY: = preload("res://Menu/SongDisplay.tscn")
onready var song_list:Control = $SongList

var songs: = 0
var csong: = 0
var use_editor: = false

var non_editable_places: = []

var tween:SceneTreeTween


func add_display(song_data, play_data)->void :
	var nd: = DISPLAY.instance()
	song_list.add_child(nd)
	nd.rect_position.x = nd.rect_size.x * (songs)
	nd.set_song_data(song_data)
	nd.set_play_data(play_data)
	if not song_data.editable and not OS.has_feature("editor"):
		non_editable_places.append(songs)
	songs += 1

func move_right():
	csong = wrapi(csong + 1, 0, songs)
	$"..".song = csong
	update_display()

func move_left():
	csong = wrapi(csong - 1, 0, songs)
	$"..".song = csong
	update_display()

func update_display():
	if tween != null and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(song_list, "rect_position:x", - csong * song_list.rect_size.x + 198, 0.3)

func _on_return_pressed()->void :
	emit_signal("menu_change_request", "main")


func _on_leftward_pressed()->void :
	move_left()


func _on_rightward_pressed()->void :
	move_right()

func _input(event:InputEvent)->void :
	if not visible:
		return 
	if not event is InputEventKey:
		return 
	if Input.is_action_just_pressed("button3"):
		move_right()
	elif Input.is_action_just_pressed("button1"):
		move_left()
	elif Input.is_action_just_pressed("button2"):
		_on_play_pressed()


func _on_play_pressed()->void :
	if not (use_editor and non_editable_places.has(csong)):
		emit_signal("play_song_request", csong)
