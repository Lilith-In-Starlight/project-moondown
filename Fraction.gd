extends Reference

class_name Fraction

const TYPE := "fraction"

var integer := 0.0
var enumerator := 1.0
var denominator := 1.0


func _init(enumer: float = 0.0, denomin: float = 1.0):
	enumerator = enumer
	denominator = denomin
	simplify()


func get_as_float() -> float:
	return integer + enumerator / denominator


func add(num):
	var was_mixed := is_mixed()
	to_fract()
	enumerator = enumerator * num.denominator + denominator * num.enumerator
	denominator *= num.denominator
	simplify()
	if was_mixed:
		to_mixed()


func added(num):
	var ret = duplicate()
	ret.add(num)
	return ret


func subtract(num):
	var was_mixed := is_mixed()
	to_fract()
	enumerator = enumerator * num.denominator - denominator * num.enumerator
	denominator *= num.denominator
	simplify()
	if was_mixed:
		to_mixed()


func subtracted(num):
	var ret = duplicate()
	ret.subtract(num)
	return ret


func multiply(num):
	var was_mixed := is_mixed()
	to_fract()
	enumerator *= num.enumerator
	denominator *= num.denominator
	simplify()
	if was_mixed:
		to_mixed()


func multiplied(num):
	var ret = duplicate()
	ret.multiply(num)
	return ret


func fmultiply(num: float):
	var was_mixed := is_mixed()
	to_fract()
	enumerator *= num
	simplify()
	if was_mixed:
		to_mixed()


func fmultiplied(num: float):
	var ret = duplicate()
	ret.fmultiply(num)
	return ret


func simplify():
	var gcd := 1.0
	for number in range(2, denominator + 1):
		if (
			denominator / float(number) == int(denominator / number)
			and enumerator / float(number) == int(enumerator / number)
		):
			gcd = number
	enumerator /= gcd
	denominator /= gcd


func to_mixed():
	if integer != 0:
		return
	if enumerator < denominator:
		return

	integer = int(enumerator / denominator) as float
	enumerator = fmod(enumerator, denominator)
	simplify()


func as_mixed():
	simplify()
	var ret = duplicate()
	ret.to_mixed()
	return ret


func to_fract():
	if integer == 0:
		return

	enumerator += integer * denominator
	integer = 0
	simplify()


func as_fract():
	simplify()
	var ret = duplicate()
	ret.to_fract()
	return ret


func is_mixed() -> bool:
	return integer != 0


func greater_than(num) -> bool:
	var m1 = as_mixed()
	var m2 = num.as_mixed()
	if m1.integer > m2.integer:
		return true

	return m1.enumerator * m2.denominator > m2.enumerator * m1.denominator


func as_string() -> String:
	simplify()
	if not is_mixed():
		if denominator == 1.0:
			return str(enumerator)
		elif enumerator == 0:
			return "0"
		return "%s/%s" % [enumerator, denominator]
	else:
		if enumerator == 0.0:
			return str(integer)
		return "%s %s/%s" % [integer, enumerator, denominator]


func as_float() -> float:
	simplify()
	if not is_mixed():
		return enumerator / float(denominator)
	else:
		return enumerator / float(denominator) + integer


func duplicate():
	var ret = get_script().new()
	ret.integer = integer
	ret.enumerator = enumerator
	ret.denominator = denominator

	return ret


func as_dict() -> Dictionary:
	var data := {
		"type": TYPE,
		"enum": enumerator,
		"denom": denominator,
	}
	if integer != 0.0:
		data["int"] = integer
	return data


func from_dict(dict: Dictionary):
	enumerator = dict.enum
	denominator = dict.denom
	if dict.has("int"):
		integer = dict.int
