extends Reference


class_name Selection


var start: = Vector2(0, - 1)
var end: = Vector2(2, - 1)


func organize():
	if start.x > end.x:
		var k: = end.x
		end.x = start.x
		start.x = k
	elif start.y > end.y:
		var k: = end.y
		end.y = start.y
		start.y = k


func has_point(point:Vector2)->bool:
	return point.x >= start.x and point.x <= end.x and point.y >= start.y and point.y <= end.y
