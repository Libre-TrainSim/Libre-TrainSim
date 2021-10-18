extends Node
class_name SafetySystem

var requires_emergency_braking = false

func enable_emergency_brakes():
	requires_emergency_braking = true

func release_emergency_brakes():
	requires_emergency_braking = false
