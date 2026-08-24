class_name LZW
extends Control

var inputDisplay : InputDisplay

var input : LineEdit

@onready var start_button : Button = $GUI/HBoxContainer/Visualization/MarginContainer/Input/ButtonMargin/StartButton
var notebook : CodingNotebook
var lzw_dict : LZWDictionary
var lzw_step_table : LZWStepTable

var input_text : String = ""
var input_pos : int = -1

var p : String = ""

var codes : Array[int] = []
var code_pos : int = -1
var old : int
var started_decoding : bool = false
var last_highlighted : int = -1

@onready var text_count_label : Label = $GUI/HBoxContainer/Visualization/MarginContainer/Input/TextCount

@onready var coding_timer : Timer = $CodingTimer
@onready var decoding_timer : Timer = $DecodingTimer

@onready var coded : RicherLabel = $GUI/HBoxContainer/Visualization/Board/VBoxContainer/MarginContainer/HBoxContainer/Coded
@onready var decoded : RicherLabel = $GUI/HBoxContainer/Visualization/Board/VBoxContainer/MarginContainer/HBoxContainer/Decoded

func _ready() -> void:
	print("LZW")
	
	inputDisplay = get_tree().get_first_node_in_group("InputDisplay")
	inputDisplay.set_new_input.connect(start_input_analysis)
	
	input = get_tree().get_first_node_in_group("Input")
	input.text_changed.connect(input_changed)
	
	lzw_dict = get_tree().get_first_node_in_group("LZWDict")
	lzw_dict.set_columns(["Izlazni kod", "Simbol", "Simbol", "Kod"])
	
	lzw_step_table = get_tree().get_first_node_in_group("LZWStepTable")
	
	notebook = get_tree().get_first_node_in_group("ArithmeticNotebook")
	
	notebook.set_button_colors(
		{
			CodingNotebook.BUTTON_COLOR.NORMAL : Color(0.851, 0.51, 0.51),
			CodingNotebook.BUTTON_COLOR.HOVERED : Color(0.733, 0.369, 0.376),
			CodingNotebook.BUTTON_COLOR.DISABLED : Color(0.882, 0.584, 0.576),
		}
	)
	
	start_button.disabled = true

func start_input_analysis():
	input_pos = 0
	
	notebook.display_text("Ajde da krenemo lmao", 2.0)
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	show_coding()

func input_changed(new_text : String):
	input_text = new_text
	
	if input_text.length() == 0:
		start_button.disabled = true
	else:
		start_button.disabled = false
	
	text_count_label.text = str(input_text.length()) + "/12"

func _on_start_button_pressed() -> void:
	inputDisplay.set_new_input_text(input_text)

func _on_coding_timer_timeout() -> void:
	pass

func show_coding():
	notebook.clear_buttons()
	notebook.clear_text()
	
	var finished_coding : bool = false
	while (not finished_coding):
		finished_coding = await next_coding_step()
		notebook.clear_buttons()
		notebook.clear_text()
	
	notebook.display_text(
		"Ce se jedu neka govna za poslednji korak",
		2.0
	)
	await notebook.displayed_text
	
	notebook.add_button("Dalje").pressed.connect(start_decoding)

func next_coding_step() -> bool:
	inputDisplay.highlight_char(input_pos)
	var c : String = input_text[input_pos]

	var step_text : String = ""

	if not lzw_dict.contains(p+c):
		var output_code : String = str(lzw_dict.get_code(p))
		var representing : String = p
		var string : String = p+c
		
		lzw_dict.add_symbol(string)
		var code_word : String = str(lzw_dict.get_code(string))
		
		step_text += "P = " + "[color=red]" + p + "[/color]" 
		step_text += ", C = " + "[color=blue]" + c + "[/color] | "
		step_text += "P + C = " + "[color=green]" + p + c + "[/color] (NIJE U REČNIKU) | "
		step_text += "Na izlazu kod za P: " + output_code + " | "
		step_text += "P = " + "[color=blue]" + c + "[/color]"
		
		codes.append(lzw_dict.get_code(p))
		coded.add_substr(" " + output_code)
		p = c
		
		lzw_dict.add_row([output_code, representing, code_word, string])
	else:
		step_text += "P = " + "[color=red]" + p + "[/color]" 
		step_text += ", C = " + "[color=blue]" + c + "[/color] | "
		step_text += "P + C = " + "[color=green]" + p + c + "[/color] (JESTE U REČNIKU) | "
		step_text += "P = " + "[color=green]" + p + c + "[/color]"
		
		p = p+c
	
	lzw_step_table.add_step(step_text)
	
	notebook.display_text(step_text, 2.0)
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	
	input_pos += 1
	var finished : bool = input_pos >= input_text.length() 
	
	if finished:
		coded.add_substr(" " + str(lzw_dict.get_code(p)))
		codes.append(lzw_dict.get_code(p))
		
		notebook.clear_text()
		notebook.clear_buttons()
	
	return finished

func start_decoding():
	lzw_dict.reset()
	lzw_dict.set_columns(["Izlazni simbol", "Kod", "Kod", "Simbol"])
	code_pos = 0
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	lzw_step_table.reset()
	
	old = codes[code_pos]
	last_highlighted = coded.highlight_substr(str(old), 0)
	var s : String = lzw_dict.get_symbol(old)
	decoded.add_substr(s)
	code_pos += 1
	
	notebook.display_text(
		"Da se izjedu neka govna za ovaj prvi korak\n" +
		"Old= " + str(old) + ", S= " + s,
		2.0
	)
	lzw_step_table.add_step("Old= " + str(old) + ", S= " + s)
	
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	
	if code_pos < codes.size():
		show_decoding()

func show_decoding():
	var finished_decoding : bool
	
	while (not finished_decoding):
		finished_decoding = await next_decode_step()
		notebook.clear_buttons()
		notebook.clear_text()
	
	notebook.display_text(
		"Da se izjedu neka govna za kraj",
		2.0
	)

func _on_decoding_timer_timeout() -> void:
	pass

func next_decode_step() -> bool:
	var new : int = codes[code_pos]
	last_highlighted = coded.highlight_substr(str(new), last_highlighted)
	
	var s : String
	if not lzw_dict.containts_code(new):
		s = lzw_dict.get_symbol(old)
		s += s[0]
	else:
		s = lzw_dict.get_symbol(new)
	
	var c : String = s[0]
	decoded.add_substr(s)
	var new_symbol : String = lzw_dict.get_symbol(old) + c 
	lzw_dict.add_symbol(new_symbol)
	
	var output_symbol : String = s
	var output_code : String = str(lzw_dict.get_code(s))
	var new_symbol_code : String = str(lzw_dict.get_code(new_symbol))
	
	lzw_dict.add_row([output_symbol, output_code, new_symbol, new_symbol_code])
	
	old = new
	
	lzw_step_table.add_step(
		"Old= " + str(old) + ", S= " + s + ", New= " + str(new) + ", C= " + c
	)
	
	notebook.display_text(
		"Old= " + str(old) + ", S= " + s + ", New= " + str(new) + ", C= " + c,
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	code_pos += 1
	var finished : bool = code_pos >= codes.size()
	return finished

func _on_start_decoding_pressed() -> void:
	start_decoding()
