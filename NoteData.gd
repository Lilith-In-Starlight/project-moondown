extends Reference

class_name NoteData

const TYPE: = "note"

var start_beat_number:float = 0.0
var end_beat_number:float = - 1.0
var duration_beats:float = - 1.0
var lane: = 0
var given_object:Node = null

func get_duration_beats()->float:
	if is_sustain():
		duration_beats = end_beat_number - start_beat_number
	
	return duration_beats


func is_sustain()->bool:
	return end_beat_number > start_beat_number


func get_as_dict()->Dictionary:
	var data: = {
		"type":TYPE, 
		"start":start_beat_number, 
		"lane":lane, 
	}
	
	if is_sustain():
		data["end"] = end_beat_number
	
	return data

func duplicate():
	var ret = get_script().new()
	ret.start_beat_number = start_beat_number
	ret.end_beat_number = end_beat_number
	ret.duration_beats = duration_beats
	ret.lane = lane
	return ret

func get_vector()->Vector2:
	return Vector2(lane, start_beat_number)

static func from_dict(dict:Dictionary)->NoteData:
	var new = load("res://NoteData.gd").new()
	new.start_beat_number = dict.start
	if dict.has("end"):
		new.end_beat_number = dict.end
	new.lane = dict.lane
	return new
