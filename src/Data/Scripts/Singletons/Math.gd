extends Node

# Get Next Position from a point on a circle after a specific Distance.
#Used for Building Rails, and driving on rail.
## Circle:
func get_next_pos(radius: float, pos: Vector3, world_rot: float, distance: float) -> Vector3:
	# Straigt
	if radius == 0:
		return pos + Vector3(cos(world_rot)*distance, 0, -sin(world_rot)*distance)
	# Curve
	var rad: float = distance / radius + world_rot
	return rad_to_coord(radius, pos, rad, world_rot)

# Calculate aut from radius of circle, the rotation of the object, and a specific Distande the next rotation of the object.
#Used for Building Rails, and driving on rail.
func get_next_rad(radius: float, world_rot: float, distance: float) -> float:
	# Straight:
	if radius == 0:
		return world_rot
	# Curve:
	return distance / radius + world_rot


# Calculates from the radius of the circle, the position and rotation from the object the center of the circle.
# Whith that the Function returns in the end the position after for example 2 degrees on "driving" on the rail.
# only used by get_next_pos()
func rad_to_coord(radius: float, pos: Vector3, rad: float, world_rot: float) -> Vector3:
	var center = pos - Vector3(sin(world_rot) * radius,0,cos(world_rot) * radius)
	var a = cos(rad) * radius
	var b = sin(rad) * radius
	return center + Vector3(b, 0, a)


## converts m/s to km/h
func speed_to_kmh(speed: float) -> float:
	return speed*3.6


func kmh_to_speed(speed: float) -> float:
	return speed/3.6


func norm_rad(radians: float) -> float:
	return fmod(radians, PI)


# returns the shortest distance in between the 2 rotations in radians
func angle_distance_rad(rad1: float, rad2: float) -> float:
	var norm1 = norm_rad(rad1)
	var norm2 = norm_rad(rad2)
	return PI - abs(abs(norm1 - norm2) - PI)


# Gets A Dict like {"name": [], "position" : []}, returns the array of the signal
func sort_signals(signal_table: Dictionary, forward: bool = true) -> Array:
	var signal_t: Dictionary = signal_table.duplicate(true)
	var export_t: Array = []

	for _a in range(0, signal_t["name"].size()):
		var minimum = 0
		for i in range(0, signal_t["name"].size()):
			if signal_t["position"][i] < signal_t["position"][minimum]:
				minimum = i
		export_t.append(signal_t["name"][minimum])
		signal_t["name"].remove(minimum)
		signal_t["position"].remove(minimum)

	if forward:
		return export_t
	else:
		export_t.invert()
		return export_t


func time_to_string(time: Array) -> String:
	var hour = String(time[0])
	var minute = String(time[1])
	var second = String(time[2])
	if hour.length() == 1:
		hour = "0" + hour
	if minute.length() == 1:
		minute = "0" + minute
	if second.length() == 1:
		second = "0" + second
	return (hour + ":" + minute +":" + second)

func seconds_to_string(time_seconds: int) -> String:
	# warning-ignore:integer_division
	# warning-ignore:integer_division
	return "%02d:%02d:%02d" % [time_seconds/3600, (time_seconds/60)%60, time_seconds%60]


func distance_to_string(distance: float) -> String:
	if distance > 10000:
		return String(int(distance/1000)) + " km"
	if distance > 1000:
		return String(int(distance/100)/10.0) + " km"
	if distance > 100:
		return String((int(distance/100))*100) + " m"
	else:
		return String(int(int(distance-10)/10.0)*10) + " m"

func time_to_seconds(time: Array) -> int:
	return time[2] + time[1] * 60 + time[0] * 3600

func seconds_to_time(seconds: int) -> Array:
	var time: Array = [0, 0, 0]
	time[0] = seconds/3600 # warning-ignore: integer_division
	seconds -= time[0] * 3600
	time[1] = seconds/60 # warning-ignore: integer_division
	seconds -= time[1] * 60
	time[2] = seconds
	return time
