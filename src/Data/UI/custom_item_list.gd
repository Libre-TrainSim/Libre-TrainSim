class_name CustomItemList
extends ScrollContainer


var even_theme := preload("res://Data/UI/styles/label_list_even.tres") as Theme
var odd_theme := preload("res://Data/UI/styles/label_list_odd.tres") as Theme
var item_count := 1


func add_item(item: String) -> void:
	var label := Label.new()
	label.text = item
	label.theme = even_theme if item_count % 2 == 0 else odd_theme
	$Items.add_child(label)
	item_count += 1


func clear_items() -> void:
	for child in $Items.get_children():
		child.queue_free()
	item_count = 1
