class_name LZWDictionary
extends VBoxContainer

var alphabet : String = "abcdefghijklmnopqrstuvwxyz"
var dict : Dictionary[String, int] = {}
var next_code : int
var rows : Array[LZWTabelRow] = []

var font = load("res://misos-projekat/assets/fonts/AnnieUseYourTelescope-Regular.ttf")

@onready var header : HBoxContainer = $Header

func _ready() -> void:
	init_dict()

func set_columns(column_names : Array[String]):
	for column in header.get_children():
		column.queue_free()
	
	for column in column_names:
		var column_label : Label = Label.new()
		
		column_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		column_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		column_label.add_theme_color_override("font_color", Color.BLACK)
		column_label.add_theme_font_override("font", font)
		
		
		var style : StyleBoxFlat = StyleBoxFlat.new()
		
		style.draw_center = false
		
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		
		style.border_color = Color.BLACK
		
		column_label.add_theme_stylebox_override("normal", style)
		
		column_label.text = column
		header.add_child(column_label)

func init_dict():
	var start_ascii : int = 65
	for letter in alphabet:
		dict[letter] = start_ascii
		start_ascii += 1
	next_code = 256

func reset():
	dict.clear()
	init_dict()
	
	for row in rows:
		row.queue_free()
	rows.clear()

func contains(symbol : String) -> bool:
	return symbol in dict

func get_code(symbol : String) -> int:
	if symbol not in dict:
		return -1
	return dict[symbol]

func containts_code(code : int) -> bool:
	for symbol in dict:
		if dict[symbol] == code:
			return true
	return false

func get_symbol(code : int) -> String:
	for symbol in dict:
		if dict[symbol] == code:
			return symbol
			
	return ""

func add_symbol(symbol : String):
	dict[symbol] = next_code
	next_code += 1

func add_row(columns : Array[String]):
	var row : LZWTabelRow = LZWTabelRow.new(columns)
	add_child(row)
	rows.append(row)
