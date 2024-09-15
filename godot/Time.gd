extends RefCounted

#class_name TimeUnit
#
#enum UNITS {
	#SECOND, 
	#MINUTE, 
	#BEAT, 
#}
#
#var bpm:float = - 1
#var amount:float = 0.0
#
#func _init(set_bpm:float, set_amount:float):
	#bpm = set_bpm
	#amount = set_amount
#
#static func new_from_seconds(set_bpm: float, seconds: float) -> TimeUnit:
	#var set_amount = seconds * (set_bpm / 60.0)
	#return TimeUnit.new(set_bpm, set_amount)
#
#func get_time_in_seconds()->float:
	#if bpm <= 0.0:
		#print("Error: Unset BPM")
		#return - 1.0
	#return (60.0 / bpm) * amount
#
#func get_time_in_minutes()->float:
	#if bpm <= 0.0:
		#print("Error: Unset BPM")
		#return - 1.0
	#return bpm * amount
#
#func get_time_in_beats()->float:
	#if bpm <= 0.0:
		#print("Error: Unset BPM")
		#return - 1.0
	#return amount
#
#
#func is_greater_than(time_unit):
	#return get_time_in_seconds() > time_unit.get_time_in_seconds()
#
#func is_lesser_than(time_unit):
	#return get_time_in_seconds() < time_unit.get_time_in_seconds()
#
#func is_equal_to(time_unit):
	#return get_time_in_seconds() == time_unit.get_time_in_seconds()
