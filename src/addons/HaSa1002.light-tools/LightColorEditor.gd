tool
extends EditorProperty
class_name LightColorEditor


var enable_cb := CheckButton.new()
var temperature := EditorSpinSlider.new()
var color_filter := make_color_button()
var color := make_color_button()

var vbox := VBoxContainer.new()

var temperature_hbox := make_hbox("Temperature")
var color_filter_hbox := make_hbox("Color Filter")
var color_hbox := make_hbox("Color")

var updating := false


func _init():
	label = "Use Color Temperature"
	enable_cb.align = Button.ALIGN_LEFT
	enable_cb.connect("toggled", self, "_on_enable_cb_toggled")
	add_child(enable_cb)
	add_focusable(enable_cb)
	add_focusable(color)
	add_focusable(color_filter)
	add_focusable(temperature)

	temperature.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	temperature.min_value = 1000
	temperature.max_value = 40_000
	temperature.connect("value_changed", self, "_on_temperature_changed")
	temperature_hbox.add_child(temperature)

	color_filter.connect("color_changed", self, "_on_color_filter_changed")
	color_filter_hbox.add_child(color_filter)

	color.connect("color_changed", self, "_on_color_changed")
	color_hbox.add_child(color)

	vbox.size_flags_horizontal = VBoxContainer.SIZE_EXPAND_FILL
	vbox.add_child(temperature_hbox)
	vbox.add_child(color_filter_hbox)
	vbox.add_child(color_hbox)

	add_child(vbox)
	set_bottom_editor(vbox)


func update_property():
	updating = true
	label = "Use color temperature"
	var obj := get_edited_object()
	if !obj.has_meta("use_color_temperature"):
		obj.set_meta("use_color_temperature", true)
	enable_cb.pressed = obj.get_meta("use_color_temperature")
	_on_enable_cb_toggled(enable_cb.pressed)

	if !obj.has_meta("color_temperature"):
		obj.set_meta("color_temperature", 6500)
	temperature.value = obj.get_meta("color_temperature")

	if !obj.has_meta("color_filter"):
		obj.set_meta("color_filter", Color(1, 1, 1, 0))
	color_filter.color = obj.get_meta("color_filter")
	color.color = obj.get(get_edited_property())

	updating = false


func _on_enable_cb_toggled(state: bool):
	if updating:
		return
	color_filter_hbox.visible = state
	temperature_hbox.visible = state
	get_edited_object().set_meta("use_color_temperature", state)
	var obj := get_edited_object()
	if enable_cb.pressed:
		var cfilter := color_filter.color
		obj[get_edited_property()] = calculate_color(temperature.value) \
				.blend(cfilter * cfilter.a)
	else:
		obj[get_edited_property()] = color.color
	emit_changed(get_edited_property(), obj[get_edited_property()])


func _on_color_filter_changed(filter_color: Color):
	if updating:
		return
	var obj := get_edited_object()
	obj.set_meta("color_filter", filter_color)
	obj[get_edited_property()] = calculate_color(temperature.value) \
			.blend(filter_color * filter_color.a)
	emit_changed(get_edited_property(), obj[get_edited_property()])


func _on_temperature_changed(kelvin: int):
	if updating:
		return
	var obj := get_edited_object()
	obj.set_meta("color_temperature", kelvin)
	var cfilter := color_filter.color
	obj[get_edited_property()] = calculate_color(kelvin).blend(cfilter * cfilter.a)
	emit_changed(get_edited_property(), obj[get_edited_property()])


func _on_color_changed(lcolor: Color):
	if updating:
		return
	var obj := get_edited_object()
	if enable_cb.pressed:
		lcolor = obj[get_edited_property()]
		color.set_deferred("color", lcolor)
	obj[get_edited_property()] = lcolor
	emit_changed(get_edited_property(), obj[get_edited_property()])


static func make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


static func make_hbox(text: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_child(make_label(text))
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return hbox


static func make_color_button() -> ColorPickerButton:
	var btn := ColorPickerButton.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.flat = true
	return btn


static func calculate_color(temperature: int) -> Color:
	var light_color := Color.white
	var t = temperature / 100.0
	if t <= 66:
		light_color.r = 1.0
		var green = 99.4708025861 * log(t) - 161.1195681661
		if green < 0:
			light_color.g = 0
		elif green > 255:
			light_color.g = 1.0
		else:
			light_color.g = green / 255

	else:
		var red = t - 60
		red = 329.698727446 * pow(red, -0.1332047592)
		if red < 0:
			light_color.r = 0
		elif red > 255:
			light_color.r = 1.0
		else:
			light_color.r = red / 255
		var green = 288.1221695283 * pow(t - 60, -0.0755148492)
		if green < 0:
			light_color.g = 0
		elif green > 255:
			light_color.g = 1.0
		else:
			light_color.g = green / 255

	if t >= 66:
		light_color.b = 1.0
		return light_color
	if t <= 19:
		light_color.b = 0
		return light_color
	var blue = 138.5177312231 * log(t - 10) - 305.0447927307
	if blue < 0:
		light_color.b = 0
	elif blue > 255:
		light_color.b = 1.0
	else:
		light_color.b = blue / 255
	return light_color
