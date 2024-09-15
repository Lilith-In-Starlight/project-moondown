extends CanvasLayer

const time: = 0.3

var closedness: = 3.0

var transition:Tween

var opened: = false

var t: = ""


func change_scene_to_packed(to:String):
	if transition != null and transition.is_valid():
		transition.kill()
	visible = true
	transition = create_tween()
	transition.set_trans(Tween.TRANS_QUAD)
	transition.set_ease(Tween.EASE_IN)
	transition.tween_property(self, "closedness", 3.0, time)
	transition.connect("finished", Callable(self, "_on_change_anim_finished"))
	t = to


func reload_current_scene():
	if transition != null and transition.is_valid():
		transition.kill()
	visible = true
	transition = create_tween()
	transition.set_trans(Tween.TRANS_QUAD)
	transition.set_ease(Tween.EASE_IN)
	transition.tween_property(self, "closedness", 3.0, time)
	transition.connect("finished", Callable(self, "_on_reload_anim_finished"))


func quit():
	if transition != null and transition.is_valid():
		transition.kill()
	visible = true
	transition = create_tween()
	transition.set_trans(Tween.TRANS_QUAD)
	transition.set_ease(Tween.EASE_IN)
	transition.tween_property(self, "closedness", 3.0, time)
	transition.connect("finished", Callable(self, "_on_quit_anim_finished"))


func _process(delta:float)->void :
	$Coverage.material.set_shader_parameter("cover_progress", closedness)
	if not opened:
		await RenderingServer.frame_post_draw
		transition = create_tween()
		transition.set_trans(Tween.TRANS_QUAD)
		transition.set_ease(Tween.EASE_IN)
		transition.tween_property(self, "closedness", 0.0, time)
		transition.tween_property(self, "visible", false, time)
		opened = true

func _on_change_anim_finished():
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(t)


func _on_reload_anim_finished():
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_anim_finished():
	await RenderingServer.frame_post_draw
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	get_tree().quit()
