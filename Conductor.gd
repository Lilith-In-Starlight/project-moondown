extends Node

class_name Conductor

signal beat_happened(number)
signal beat_plus_offset_happened(number)

var sound_object:AudioStreamPlayer = null
var bpm:float = - 1.0
var crotchet:float = - 1.0
var offset:float = - 1.0

var last_beat_seconds:float = - 1.0
var beats_passed:int = - 1

var post_beat_happened: = false

var notes: = [[], [], []]

var last_diff_pbp = 0
var ostick_ref = 0

var time:TimeUnit

func process():
	if sound_object == null:
		return 
	
	if song_position().get_time_in_seconds() > last_beat_seconds + crotchet:
		last_beat_seconds += crotchet
		post_beat_happened = false
		emit_signal("beat_happened", beats_passed)
		
		beats_passed += 1
	
	if song_position().get_time_in_seconds() > last_beat_seconds + 0.2 and not post_beat_happened:
		post_beat_happened = true
		emit_signal("beat_plus_offset_happened", last_beat_seconds, beats_passed - 1)



func song_position()->TimeUnit:
	var calculated_current_time: = sound_object.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	if time == null:
		time = TimeUnit.new(bpm, TimeUnit.UNITS.SECOND, calculated_current_time)
	if sound_object.playing:
		time = TimeUnit.new(bpm, TimeUnit.UNITS.SECOND, max(calculated_current_time, time.get_time_in_seconds()))
	return time


func set_audio_object(audio_object:AudioStreamPlayer, song_bpm:float, song_offset:float):
	sound_object = audio_object
	bpm = song_bpm
	offset = song_offset
	crotchet = 60.0 / bpm
	last_beat_seconds = 0.0
	beats_passed = 0
