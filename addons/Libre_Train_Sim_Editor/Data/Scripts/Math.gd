extends Node

# Get Next Position from a point on a circle after a specific Distance. 
#Used for Building Rails, and driving on rail.
## Circle:
func getNextPos(radius, pos, worldRot, distance):#  Vector3 position, float worldRot, float distance):
	# Straigt
	if radius == 0:
		return pos + Vector3(cos(deg2rad(worldRot))*distance, 0, -sin(deg2rad(worldRot))*distance) ##!!!!
	# Curve
	var extend = radius * 2.0 * PI
	var degree = distance / extend * 360    + worldRot
	return degreeToCoordinate(radius, pos, degree, worldRot)

# Calculate aut from radius of circle, the rotation of the object, and a specific Distande the next rotation of the object.
#Used for Building Rails, and driving on rail.
func getNextDeg(radius, worldRot, distance):
	# Straight:
	if radius == 0: 
		return worldRot
	# Curve:
	var extend = radius * 2.0 * PI
	return distance / extend * 360    + worldRot


# Calculates from the radius of the circle, the position and rotation from the object the middlepoint of the circle.
# Whith that the Function returns in the end the position after for example 2 degrees on "driving" on the rail.
# only used sed by getNextPos()
func degreeToCoordinate(radius, pos, degree, worldRot):
	degree = float(degree)
	var mittelpunkt = pos - Vector3(sin(deg2rad(worldRot)) * radius,0,cos(deg2rad(worldRot)) * radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return mittelpunkt + Vector3(b, 0, a)

## converts m/s to km/h
func speedToKmH(speed):
	return speed*3.6
	
func kmHToSpeed(speed):
	return speed/3.6
	
func normDeg(degree):
	while degree > 360.0:
		degree -= 360.0
	while degree < 0.0:
		degree += 360.0
	return degree


func sort_signals(signalTable, forward = true):
	var signalT = [signalTable.values(), signalTable.keys()]
	var exportT = [] 
	for a in range(0, signalT[0].size()):
		var minimum = 0
		for i in range(0, signalT[0].size()):
			if signalT[0][i] < signalT[0][minimum]:
				minimum = i
		exportT.append(signalT[1][minimum])
		signalT[0].remove(minimum)
		signalT[1].remove(minimum)
	if forward:
		return exportT
	else:
		exportT.invert()
		return exportT
		
		
