extends Control


var done: = false

func _process(delta:float)->void :
	if not done:
		$AnimationPlayer.play("Play")
		done = true


func _on_animation_finished(anim_name:String)->void :
	get_tree().change_scene_to_packed(preload("res://SongSelect.tscn"))
