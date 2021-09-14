extends VBoxContainer

export(NodePath) var developers_vbox
export(NodePath) var contributors_vbox
export(NodePath) var translators_vbox
export(Resource) var authors = authors as Authors

export(PackedScene) var label := preload("res://Resources/Basic/UI/AboutAuthorLabel.tscn")
export(PackedScene) var language_label := preload("res://Resources/Basic/UI/AboutLanguageLabel.tscn")


func _ready() -> void:
	_clear_box(developers_vbox)
	_clear_box(contributors_vbox)
	_clear_box(translators_vbox)

	show_authors(authors.developers, developers_vbox)
	show_authors(authors.contributors, contributors_vbox)
	show_translators()


func _clear_box(box_path: NodePath) -> void:
	for n in get_node(box_path).get_children():
		n.queue_free()


func show_authors(data: Array, path_to_parent: NodePath) -> void:
	for entry in data:
		var author_label := label.instance() as Label
		author_label.text = str(entry).strip_edges()
		get_node(path_to_parent).add_child(author_label)


func show_translators() -> void:
	for translators in authors.translators:
		var language := language_label.instance() as Label
		language.text = translators[0]
		get_node(translators_vbox).add_child(language)
		show_authors(translators.slice(1, -1), translators_vbox)
