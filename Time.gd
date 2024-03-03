extends Reference

class_name TimeUnit

enum UNITS{
	SECOND, 
	MINUTE, 
	BEAT, 
}

var bpm:float = - 1
var amount:float = 0.0
var unit:int = - 1

func _init(set_bpm:float, set_unit:int, set_amount:float)->void :
	bpm = set_bpm
	amount = set_amount
	unit = set_unit

func get_time_in_seconds()->float:
	match unit:
		UNITS.SECOND:
			return amount
		UNITS.MINUTE:
			return amount * 60.0
		UNITS.BEAT:
			if bpm <= 0.0:
				print("Error: Unset BPM")
				return - 1.0
			return amount * bpm / 60.0
		_:
			print("Error: Unset units")
			return - 1.0


func get_time_in_minutes()->float:
	match unit:
		UNITS.SECOND:
			return amount / 60.0
		UNITS.MINUTE:
			return amount
		UNITS.BEAT:
			if bpm <= 0.0:
				print("Error: Unset BPM")
				return - 1.0
			return bpm * amount
		_:
			print("Error: Unset units")
			return - 1.0



func get_time_in_beats()->float:
	if bpm <= 0.0:
		print("Error: Unset BPM")
		return - 1.0
	
	match unit:
		UNITS.SECOND:
			return amount * (bpm / 60.0)
		UNITS.MINUTE:
			return amount / bpm
		UNITS.BEAT:
			return amount
		_:
			print("Error: Unset units")
			return - 1.0


func is_greater_than(time_unit):
	return get_time_in_seconds() > time_unit.get_time_in_seconds()

func is_lesser_than(time_unit):
	return get_time_in_seconds() < time_unit.get_time_in_seconds()

func is_equal_to(time_unit):
	return get_time_in_seconds() == time_unit.get_time_in_seconds()
