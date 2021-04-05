tool
extends Node

# If you don't need the whole package of jTools, you can easily deactivate some parts.
# Restart of the plugin / GoDot is needed to apply changes.
const enable_jSaveManager = true
const enable_jTable = true
const enable_jList = true
const enable_jAudioManager = true
const enable_jSettings = true
const enable_jEssentials = true

## jAudioManager ###############################################################
# Set this to false, if you want to deactivate jAudioManager's bus system.
# jAudioManager will also work without it's own bus system.
const enable_jAudioManager_bus = true 

# Optional, you could define a the bus ids for the game and music bus, which 
# jAudioManager should use
const game_bus_id = 1
const music_bus_id = 2

## jTable ######################################################################
# Here you can add (custom) nodes which should be supported by the jTable.

func get_value_of(node : Node):
# Examples (These are already implemented):
#	if node is LineEdit:
#		return node.text
#	if node is SpinBox:
#		return node.value

	print_debug("Node Type of " + node.name + " in jTable currently not supported. Add me!")
	return 0

func set_value_to(node : Node, value):
# Examples (These are already implemented):
#	if node is LineEdit:
#		node.text = value
#		return
#	if node is SpinBox:
#		node.value = value
#		return

	print_debug("Node Type of " + node.name + " in jTable currently not supported. Add me!")
