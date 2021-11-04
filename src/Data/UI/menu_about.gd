extends Control


export(Resource) var authors = authors as Authors
export(PackedScene) var label := preload("res://Data/UI/AboutAuthorLabel.tscn")
export(PackedScene) var language_label := preload("res://Data/UI/AboutLanguageLabel.tscn")


onready var developers_vbox := $Control/ScrollContainer/VBoxAbout/Developers/Developers
onready var contributors_vbox := $Control/ScrollContainer/VBoxAbout/Contributors/Contributors
onready var translators_vbox := $Control/ScrollContainer/VBoxAbout/Translators/Translators
func _ready() -> void:
	_clear_box(developers_vbox)
	_clear_box(contributors_vbox)
	_clear_box(translators_vbox)

	show_authors(authors.developers, developers_vbox)
	show_authors(authors.contributors, contributors_vbox)
	show_translators()


func _clear_box(box_path: Control) -> void:
	for node in box_path.get_children():
		node.queue_free()


func show_authors(data: Array, parent: Control) -> void:
	for entry in data:
		var author_label := label.instance() as Label
		author_label.text = entry
		parent.add_child(author_label)


func show_translators() -> void:
	for translators in authors.translators:
		var language := language_label.instance() as Label
		language.text = translators[0]
		translators_vbox.add_child(language)
		show_authors(translators.slice(1, -1), translators_vbox)


func _on_Back_pressed() -> void:
	hide()
