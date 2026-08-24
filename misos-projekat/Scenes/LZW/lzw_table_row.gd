class_name LZWTabelRow
extends HBoxContainer

var column_texts : Array[String]

var font = load("res://misos-projekat/assets/fonts/AnnieUseYourTelescope-Regular.ttf")

func _init(column_texts_ : Array[String]) -> void:
	column_texts = column_texts_

func _ready() -> void:
	self.add_theme_constant_override("separation", 0)
	for text in column_texts:
		add_child(make_label(text))

func make_label(text : String) -> Label:
	var label : Label = Label.new()
	
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var style : StyleBoxFlat = StyleBoxFlat.new()
	style.draw_center = false
	
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	
	style.border_color = Color.BLACK
	
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_font_override("font", font)
	
	return label
