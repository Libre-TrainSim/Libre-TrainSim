class_name ColoredItemList
extends ItemList


export var odd_color := Color(0.301961, 0.611765, 0.768627, 0.411765)
export var even_color := Color(0.705882, 0.772549, 0.878431, 0.360784)


func add_item(text: String, icon: Texture = null, selectable := true) -> void:
	.add_item(text, icon, selectable)
	set_item_custom_bg_color(get_item_count() - 1, even_color if get_item_count() % 2 == 0 else odd_color)

