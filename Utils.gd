extends Node


class_name Util


static func is_valid_fraction(s:String)->bool:
	var split: = s.split("-", false, 2)
	if split.size() == 1:
		return split[0].is_valid_float()
	elif split.size() == 2:
		if split[1] as float == 0:
			return false
		return split[0].is_valid_float() and split[1].is_valid_float()
	elif split.size() == 3:
		if split[2] as float == 0:
			return false
		return split[0].is_valid_float() and split[1].is_valid_float() and split[2].is_valid_float()
	else :
		return false


static func frac_to_float(s:String)->float:
	if not is_valid_fraction(s):return NAN
	var split: = s.split("-", false, 2)
	if split.size() == 1:
		if not s.begins_with("-"):return split[0] as float
		else :return 1.0 / (split[0] as float)
	elif split.size() == 2:
		if split[1] as float == 0:
			return NAN
		return (split[0] as float) / (split[1] as float)
	elif split.size() == 3:
		if split[2] as float == 0:
			return NAN
		return (split[0] as float) + ((split[1] as float) / (split[2] as float))
	else :
		return NAN


static func frac_to_frac(s:String)->Fraction:
	if not is_valid_fraction(s):return null
	var split: = s.split("-", false, 2)
	if split.size() == 1:
		if not s.begins_with("-"):return Fraction.new(split[0] as float, 1.0)
		else :return Fraction.new(1.0, split[0] as float)
	elif split.size() == 2:
		if split[1] as float == 0:
			return null
		return Fraction.new(split[0] as float, split[1] as float)
	elif split.size() == 3:
		if split[2] as float == 0:
			return null
		var frac: = Fraction.new(split[1] as float, split[2] as float)
		frac.integer = split[0] as float
		return frac
	else :
		return null


static func get_key_string(k:int)->String:
	return char(k).to_lower()
