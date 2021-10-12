extends Control

func _ready():
	## Load Table data
	var tableData = jSaveManager.get_value("tableSettings") # Load Table from File.
	if tableData != null:
		$Table/jTable.set_data(tableData)

	## Load jList data
	$Page2/jListExample2/jList.set_data(jSaveManager.get_value("jListExample2", []))


	## Play Music: (The music also plays while level loading ;)
	jAudioManager.play_music("res://addons/jean28518.jTools/example/SampleMusic.ogg")

## Attention! Every jTable needs at least one connection to the save_pressed signal!
func _on_jTable_saved_pressed(tableData):
	# dataTable is a dictionary with single arras.
	# e.g.:
	# tableData = {
	# 	"street": [ "Gubener Straße", "Büsingstrasse", "Karl-Liebknecht-Strasse" ],
	# 	"city": [ "Bad Tölz", "Gilching", "Kaltenkirchen" ],
	# 	"firstName": [ "Laura", "Kevin", "Monika" ],
	# 	"gender": [ 1, 0, 0 ],
	# 	"housenumber": [ "51", "94", "23" ],
	# 	"lastName": [ "Hoch", "Egger", "Schweitzer" ],
	# 	"postalCode": [ 83633.0, 82205.0, 24560.0 ]
	# }

	jSaveManager.save_value("tableSettings", tableData)

	print("Saved Table Data successfully. \nHint: For saving you have to care yourself. See example.gd for required code.")

## Option Button ###############################################################
# You just need to call this function jSettings.openSettings(),
# and the settings window opens. Completely irrelevant from where you call this.

func _on_Options_pressed():
	jSettings.open_window()


## Easy Save/Load Example ######################################################
func _on_SaveSingleValue_pressed():
	jSaveManager.save_value("exampleValue", $ColorRect/LineEdit.text)


func _on_Load_pressed():
	if jSaveManager.get_value("exampleValue") != null:
		$ColorRect/LineEdit.text = jSaveManager.get_value("exampleValue")

func _on_ClearExampleValue_pressed():
	$ColorRect/LineEdit.text = ""


func _on_Quit_pressed():
	get_tree().quit()

## Play Ingame Sound ###########################################################
func _on_PlaySound_pressed():
	jAudioManager.play_game_sound("res://addons/jean28518.jTools/example/SampleSound.ogg")

func _on_PlayDelayedSound_pressed():
	jEssentials.call_delayed($PlayDelayedSound/seconds.value, jAudioManager, "play_game_sound", ["res://addons/jean28518.jTools/example/SampleSound.ogg"])


## jList #######################################################################
#func _ready():
#	$Page2/jListExample2/jList.set_data(jSaveManager.get_value("jListExample2", []))

# If the Save Button is enabled, jTable needs at least one connection to the save_pressed signal!
# You have to care about yourself for saving. But you can do this very easy with jSaveManager:
func _on_jListExample2_user_pressed_save(data):
	jSaveManager.save_value("jListExample2", data)
	print("Saved jList Data successfully. \nHint: For saving you have to care yourself. See example.gd for required code.")

func _on_jListExample1_user_selected_entry(entry_name):
	print("User selected " + entry_name)

## (Pages) #####################################################################
func _on_Page1_pressed():
	$Table.show()
	$SaveLoadExample.show()
	$PlayDelayedSound.show()
	$Page2.hide()

func _on_Page2_pressed():
	$Table.hide()
	$SaveLoadExample.hide()
	$PlayDelayedSound.hide()
	$Page2.show()

