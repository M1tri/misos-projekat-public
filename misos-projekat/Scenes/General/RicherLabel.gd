class_name RicherLabel
extends RichTextLabel

var display_text : String = ""

var font = load("res://misos-projekat/assets/fonts/AnnieUseYourTelescope-Regular.ttf")

func _ready() -> void:
	add_theme_font_override("normal_font", font)

func set_new_text(new_text : String):
	display_text = new_text

func highlight_char(char_pos : int):
	if char_pos < 0 or char_pos >= display_text.length():
		return
	
	var new_label_text : String = ""
	for i in range(0, display_text.length()):
		var letter : String = display_text[i]
		if i == char_pos:
			letter = "[color=red]" + letter + "[/color]"
		new_label_text += letter
	
	self.text = new_label_text

func add_substr(substr : String):
	display_text += substr
	self.text = display_text

func highlight_substr(substr : String, from : int) -> int:
	var substr_start : int = display_text.find(substr, from)
	if substr_start == -1:
		return -1
	
	var new_text : String = ""
	for i in range(0, display_text.length()):
		if i == substr_start:
			new_text += "[color=red]"
		elif i == substr_start+substr.length():
			new_text += "[/color]"
		
		new_text += display_text[i]
	
	self.text = new_text
	return substr_start+substr.length()

func get_char(char_pos : int) -> String:
	if char_pos < 0 or char_pos >= display_text.length():
		return ""
	
	return display_text[char_pos]

func add_char(new_char : String):
	display_text += new_char
	self.text = display_text

func turn_off_highlight():
	self.text = display_text
