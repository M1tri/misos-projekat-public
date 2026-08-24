class_name Arithmetic
extends Control

const alphabet : String = "abcdefghijklmnopqrstuvwxyz"

var symbolTable : SymbolTableContainer

var inputDisplay : InputDisplay

var input : LineEdit

@onready var start_button : Button = $GUI/HBoxContainer/InputAndVisual/Input/HBoxContainer/StartButton

@onready var inputAnalysisTimer : Timer = $InputAnalysisTimer

var arithmeticCodingVisualizer : ArithmeticCodingVisualizer

var notebook : CodingNotebook

var input_text : String = ""
var input_pos : int = -1

@onready var text_count_label : Label = $GUI/HBoxContainer/InputAndVisual/Input/HBoxContainer/TextCount

func _ready() -> void:
	print("Arithmetic")
	
	symbolTable = get_tree().get_first_node_in_group("SymbolTableContainer")
	symbolTable.set_column_name(1, "Simbol")
	symbolTable.set_column_name(2, "Broj")
	
	inputDisplay = get_tree().get_first_node_in_group("InputDisplay")
	inputDisplay.set_new_input.connect(start_input_analysis)
	
	input = get_tree().get_first_node_in_group("Input")
	input.text_changed.connect(input_changed)
	
	arithmeticCodingVisualizer = get_tree().get_first_node_in_group("ACV")
	arithmeticCodingVisualizer.finished_step.connect(next_code_step)
	arithmeticCodingVisualizer.finished_coding.connect(finish_coding)
	
	notebook = get_tree().get_first_node_in_group("ArithmeticNotebook")
	
	notebook.set_button_colors(
		{
			CodingNotebook.BUTTON_COLOR.NORMAL : Color(0.439, 0.608, 0.82),
			CodingNotebook.BUTTON_COLOR.HOVERED : Color(0.294, 0.463, 0.675),
			CodingNotebook.BUTTON_COLOR.DISABLED : Color(0.51, 0.663, 0.859),
		}
	)
	
	notebook.set_font_size(24)
	
	start_button.disabled = true

func input_changed(new_text : String):
	var old_caret_pos := input.caret_column
	var filtered_text := ""
	
	for c in new_text:
		if c in alphabet:
			filtered_text += c
	
	var new_caret_pos := 0
	for i in range(min(old_caret_pos, new_text.length())):
		var c := new_text[i]
		if c >= "a" and c <= "z":
			new_caret_pos += 1
	
	if filtered_text != new_text:
		input.set_text(filtered_text)
		input.caret_column = new_caret_pos
	
	input_text = filtered_text
	
	start_button.disabled = input_text.is_empty()
	text_count_label.text = str(input_text.length()) + "/6"

func _on_start_button_pressed() -> void:
	symbolTable.reset()
	symbolTable.adjust_font_size(input_text.length())
	arithmeticCodingVisualizer.reset()
	inputDisplay.set_new_input_text(input_text)

func start_input_analysis():
	notebook.display_text(
		"1) Za svaki simbol određuje se broj njegovih pojavljivanja u ulaznom nizu.",
		2.0
		)
	
	await notebook.displayed_text
	
	var button_begin : Button = notebook.add_button("Započni brojanje")
	await button_begin.pressed
	
	input_pos = 0
	inputAnalysisTimer.start()
	
func _on_input_analysis_timer_timeout() -> void:
	if input_pos >= input_text.length():
		finish_input_analysis()
		return
	
	var nextChar : String = input_text[input_pos]
	
	symbolTable.process_symbol(nextChar)
	inputDisplay.highlight_char(input_pos)
	
	input_pos += 1
	
	inputAnalysisTimer.start()

func finish_input_analysis():
	inputDisplay.reset_highlight()
	
	notebook.clear_text()
	notebook.clear_buttons()
	
	notebook.display_text(
		"2) Nakon toga, neophodno je da odredimo verovatnoće za svaki simbol. " +
		"Verovatnoća simbola dobija se deljenjem broja njegovih pojavljivanja " + 
		"sa ukupnim brojem simbola u ulaznom nizu.\n\tP(s) = broj pojavljivanja simbola / ukupan broj simbola",
		2.0
	)
	
	await notebook.displayed_text
	
	var button : Button = notebook.add_button("Odredi verovatnoće")
	
	await button.pressed
	
	var count : Dictionary[String, float] = {}
	for c in input_text:
		if c in count:
			count[c] += 1.0
		else:
			count[c] = 1.0
	
	var first_count : int = count[input_text[0]] as int
	for c in count:
		count[c] = count[c] / input_text.length()
	
	notebook.display_text(
		"Na primer za simbol " + input_text[0] + ", broj njegovih pojavljivanja je " + 
		str(first_count) + ", a ulazni niz je dužine " + str(input_text.length()) + ", pa je na osnovu formule:" +
		"\n\tP(" + input_text[0] + ") = " + str(first_count) + " / " + str(input_text.length()) + " = " 
		+ str(count[input_text[0]]).pad_decimals(2),
		2.0
	)
	
	await notebook.displayed_text
	symbolTable.change_symbol_counter_text(input_text[0], str(count[input_text[0]]).pad_decimals(2))
	
	notebook.clear_buttons()
	button = notebook.add_button("Završi računanje verovatnoća")
	
	await button.pressed
	symbolTable.set_column_name(2, "P(S)")
	
	for c in count:
		symbolTable.change_symbol_counter_text(c, str(count[c]).pad_decimals(2))
	
	notebook.clear_text()
	notebook.clear_buttons()
	
	notebook.display_text(
		"3) Početni interval [0,1) deli se prema verovatnoćama simbola. " +
		"Za svaki simbol izračunava dužina podintervala po formuli:\n" +
		"(G−D)⋅P(s)\nG - gornja granica intervala\nD - donja granica intervala " + 
		"Dodavanjem te dužine na trenutnu donju granicu dobija se gornja granica podintervala. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	var unique : Array[String] = count.keys()
	
	const max_primer : int = 2
	var prev : float = 0
	for i in range(0, unique.size()):
		if i >= max_primer:
			break
		var cur : String = unique[i]
		
		var msg : String = ""
		msg += "Simbol " + str(cur) + ":\n"
		msg += "Trenutna donja granica: " + str(prev) + "\n"
		msg += "(G - D) * P(" + cur + ") = (1 - 0) * " + str(count[cur]).pad_decimals(2) + " = " + str(count[cur]).pad_decimals(2) + "\n"
		var new : float = prev + count[cur]
		msg += str(prev).pad_decimals(2) + " + " + str(count[cur]).pad_decimals(2) + " = " + str(new).pad_decimals(2)
		prev = new
		
		notebook.clear_buttons()
		notebook.display_text(
			msg,
			2.0
		)
		await notebook.displayed_text
		await notebook.add_button("Dalje").pressed
	
	arithmeticCodingVisualizer.beggin_compression(input_text)
	input_pos = 0

func next_code_step(number_line : ArithmeticNumberLine):
	inputDisplay.highlight_char(input_pos)
	notebook.clear_text()
	notebook.clear_buttons()
	
	if input_pos == input_text.length()-1:
		notebook.display_text(
			"5) Došli smo do poslednjeg simbola u nizu a to je " + input_text[input_pos] + ". " +
			"Potrebno je da izaberemo bilo koji broj iz njegovog podintervala i taj broj će " +
			"jednoznačno predstavljati ulazni niz. Ovde se, radi ilustracije, bira sredina intervala.",
			3.0
		)
		await notebook.displayed_text
		
		await notebook.add_button("Odredi sredinu").pressed
		arithmeticCodingVisualizer.next_coding_step()
		return
	
	if input_pos == 0:
		notebook.display_text(
			"4) Za svaki simbol bira se njegov podinterval, koji postaje novi trenutni interval " +
			"i ponovo se deli prema verovatnoćama simbola. Tako se interval postepeno sužava.",
			1.0
		)
		await notebook.displayed_text
		await notebook.add_button("Dalje").pressed
		notebook.clear_buttons()
	
	notebook.clear_text()
	
	var curr : String = input_text[input_pos]
	
	var subinterval : Array[float] = number_line.get_symbol_numeric_interval(curr)
	notebook.display_text(
		"Sada obrađujemo simbol " + curr + " i ulazimo u njegov podinterval. " +
		"Podintervali se određuju po istom principu samo je sada " + 
		"\nD = " + str(subinterval[0]).pad_decimals(6) + "\nG = " + str(subinterval[1]).pad_decimals(6),
		2.0
	)
	
	var button : Button = notebook.add_button("Uđi u podinterval za simbol " + curr)
	
	await button.pressed
	arithmeticCodingVisualizer.next_coding_step()
	input_pos += 1

var coded_message : float
func finish_coding(code : float):
	coded_message = code
	notebook.append_text(
		"\nKod za niz [color=red]" + input_text + "[/color] je: " + str(code).pad_decimals(6),
		2.0
	)
	
	await notebook.displayed_text
	notebook.clear_buttons()
	notebook.add_button("Dalje").pressed.connect(begin_decoding)

func begin_decoding():
	notebook.clear_text()
	notebook.clear_buttons()
	
	notebook.display_text(
		"Da bi dekodiranje bilo uspešno, neophodno je koristiti iste verovatnoće i isti " +
		"raspored podintervala koji su korišćeni prilikom kodiranja. Takođe, u ovoj implementaciji " +
		"potrebno je znati i dužinu poruke koja se dekodira, dok neke druge koriste poseban terminalni simbol.",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.display_text(
		"Proces dekodiranja se zasniva na postepenom određivanju simbola. " +
		"U svakom koraku bira se odgovarajući podinterval u kome se nalazi kodna vrednost. " +
		"Postupak se ponavlja sve dok se ne dobiju svi simboli originalne poruke.",
		2.0
	)
	
	notebook.clear_buttons()
	inputDisplay.reset_highlight()
	await notebook.add_button("Pokreni dekodiranje").pressed
	
	await arithmeticCodingVisualizer.beggin_decompression()
	show_decoding()

func show_decoding():
	notebook.clear_text()
	notebook.clear_buttons()
	
	var code_str : String = str(coded_message).pad_decimals(6)
	var subinterval_str : String = "[0, 1)"
	
	for i in range(input_text.length()):
		notebook.display_text(
			"Prvo delimo trenutni interval " + subinterval_str + " na podintervale, zatim tražimo kom podintervalu pripada " +
			code_str,
			2.0
		)
		
		await notebook.add_button("Odredi podinterval").pressed
		
		var subinterval : ArithmeticNumberLine.SymbolInterval = await arithmeticCodingVisualizer.mark_code()
		
		subinterval_str = "[" + str(subinterval.start_num).pad_decimals(6) + ", " + str(subinterval.end_num).pad_decimals(6) + ")"
		
		notebook.clear_text()
		notebook.clear_buttons()
		
		notebook.display_text(
			"Kodna vrednost " + code_str + " nalazi se u podintervalu " + subinterval_str + " pa se kao sledeći simbol određuje " + subinterval.symbol + ". ",
			2.0
		)
		
		await notebook.displayed_text
		
		if i == input_text.length()-1:
			await notebook.add_button("Dalje").pressed
			break
		
		notebook.append_text(
			"Trenutni interval sada postaje " + subinterval_str + " i nastavljamo postupak.",
			2.0
		)
		
		await notebook.displayed_text
		arithmeticCodingVisualizer.next_decompression_step()
		
		await arithmeticCodingVisualizer.finished_decoding_step
		
	notebook.clear_text()
	notebook.clear_buttons()
	
	notebook.display_text(
		"Na ovaj način aritmetičko dekodiranje omogućava potpuno vraćanje originalne poruke iz" + 
		"kompresovane vrednosti, bez gubitka informacija.",
		2.0
	)
	
	notebook.add_button("Ponovo")

func highlight(text_pos : int):
	inputDisplay.highlight_char(text_pos)
