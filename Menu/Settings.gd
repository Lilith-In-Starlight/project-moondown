extends Control


signal menu_change_request(to)

var current_menu: = "main"

onready var main:Control = $Main
onready var audio:Control = $Audio
onready var gameplay:Control = $Gameplay
onready var slider:HSlider = $Gameplay / Options / ScrollOption / Slider



func change_menu_to(to:String)->void :
	match to:
		"main":
			main.visible = true
			audio.visible = false
			gameplay.visible = false
		"audio":
			audio.visible = true
			main.visible = false
			gameplay.visible = false
		"gameplay":
			gameplay.visible = true
			audio.visible = false
			main.visible = false
			slider.value = Global.SCROLL_SPEED / 100.0


func _on_audio_pressed()->void :
	change_menu_to("audio")


func _on_gameplay_pressed()->void :
	change_menu_to("gameplay")


func _on_return_pressed()->void :
	emit_signal("menu_change_request", "main")


func _on_go_main_pressed()->void :
	change_menu_to("main")


func _on_scrool_speed_drag_ended(value_changed:bool)->void :
	Global.SCROLL_SPEED = slider.value * 100.0
