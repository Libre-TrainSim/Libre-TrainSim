extends Node
class_name SafetySystem

var requires_emergency_braking: bool = false


func enable_emergency_brakes() -> void:
	requires_emergency_braking = true


func release_emergency_brakes() -> void:
	requires_emergency_braking = false
