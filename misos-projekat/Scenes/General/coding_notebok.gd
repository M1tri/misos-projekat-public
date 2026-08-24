class_name CodingNotebook
extends VBoxContainer

var text_label : RichTextLabel
var buttons_container : HBoxContainer

signal displayed_text

var button_font = load("res://misos-projekat/assets/fonts/Quicksand/static/Quicksand-Bold.ttf")

enum BUTTON_COLOR{
	NORMAL = 0,
	HOVERED = 1,
	DISABLED = 2
}

var button_colors : Dictionary[BUTTON_COLOR, Color] = {
	BUTTON_COLOR.NORMAL : Color.WHITE, 
	BUTTON_COLOR.HOVERED : Color.WHITE, 
	BUTTON_COLOR.DISABLED : Color.WHITE
}

func _ready() -> void:
	for child in get_children():
		if child is RichTextLabel:
			text_label = child as RichTextLabel
		elif child is HBoxContainer:
			buttons_container = child as HBoxContainer

func set_button_colors(colors : Dictionary[BUTTON_COLOR, Color]):
	for color in colors:
		button_colors[color] = colors[color]

func set_font_size(font_size : int):
	text_label.add_theme_font_size_override("normal_font_size", font_size)

func display_text(text : String, duration : float):
	text_label.text = text
	var char_count : int = text_label.get_total_character_count()
	text_label.visible_characters = 0
	
	var visible_chars_tween : Tween = text_label.create_tween()
	visible_chars_tween.tween_property(
		text_label,
		"visible_characters",
		char_count,
		duration
	).finished.connect(func (): displayed_text.emit())

func append_text(text : String, duration : float):
	var old_char_count : int = text_label.get_total_character_count()
	text_label.append_text(text)
	
	var char_count : int = text_label.get_total_character_count()
	text_label.visible_characters = old_char_count

	var visible_chars_tween : Tween = text_label.create_tween()
	visible_chars_tween.tween_property(
		text_label,
		"visible_characters",
		char_count,
		duration
	).finished.connect(func (): displayed_text.emit())

func clear_text():
	text_label.text = ""

func add_button(button_text : String, one_press : bool = true) -> Button:
	var button : Button = Button.new()
	
	button.custom_minimum_size.x = 50
	
	button.add_theme_color_override("font_color", Color.BLACK)
	
	var button_normal_style : StyleBoxFlat = StyleBoxFlat.new()
	
	button_normal_style.bg_color = button_colors[BUTTON_COLOR.NORMAL]
	
	button_normal_style.border_width_bottom = 2
	button_normal_style.border_width_left = 2
	button_normal_style.border_width_right = 2
	button_normal_style.border_width_top = 2
	
	button_normal_style.corner_radius_bottom_left = 4
	button_normal_style.corner_radius_bottom_right = 4
	button_normal_style.corner_radius_top_left = 4
	button_normal_style.corner_radius_top_right = 4
	
	button_normal_style.shadow_size = 4
	button_normal_style.shadow_offset = Vector2(4, 4)
	
	button.add_theme_stylebox_override("normal", button_normal_style)
	
	var button_hover_style : StyleBoxFlat = StyleBoxFlat.new()
	
	button_hover_style.bg_color = button_colors[BUTTON_COLOR.HOVERED]
	
	button_hover_style.border_width_bottom = 2
	button_hover_style.border_width_left = 2
	button_hover_style.border_width_right = 2
	button_hover_style.border_width_top = 2
	
	button_hover_style.corner_radius_bottom_left = 4
	button_hover_style.corner_radius_bottom_right = 4
	button_hover_style.corner_radius_top_left = 4
	button_hover_style.corner_radius_top_right = 4
	
	button_hover_style.shadow_size = 4
	button_hover_style.shadow_offset = Vector2(4, 4)
	
	button.add_theme_stylebox_override("hover", button_hover_style)
	
	var button_disabled_style : StyleBoxFlat = StyleBoxFlat.new()
	
	button_disabled_style.bg_color = button_colors[BUTTON_COLOR.DISABLED]
	
	button_disabled_style.border_width_bottom = 2
	button_disabled_style.border_width_left = 2
	button_disabled_style.border_width_right = 2
	button_disabled_style.border_width_top = 2
	
	button_disabled_style.corner_radius_bottom_left = 4
	button_disabled_style.corner_radius_bottom_right = 4
	button_disabled_style.corner_radius_top_left = 4
	button_disabled_style.corner_radius_top_right = 4
	
	button.add_theme_stylebox_override("disabled", button_disabled_style)
	
	button.add_theme_font_override("font", button_font)

	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	button.text = button_text
	
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buttons_container.add_child(button)
	
	if one_press:
		button.pressed.connect(func(): button.disabled = true)
	
	return button

func clear_buttons():
	for button in buttons_container.get_children():
		button.queue_free()
