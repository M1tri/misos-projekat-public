class_name LZW
extends Control

const alphabet : String = "abcdefghijklmnopqrstuvwxyz"

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
	
	notebook.set_font_size(26)
	
	start_button.disabled = true

func start_input_analysis():
	input_pos = 0

	notebook.display_text(
		"Osnovna ideja LZW algoritma jeste korišćenje rečnika podnizova. Na početku procesa " +
		"rečnik sadrži pojedinačne karaktere, dok se tokom obrade u njega dodaju duže sekvence " +
		"karaktera koje se pojavljuju u ulaznom nizu. Kada se određeni podniz prvi put prepozna, on se " + 
		"dodaje u rečnik i dobija odgovarajući kod. Ako se isti podniz kasnije ponovo pojavi, umesto " +
		"njegovog potpunog zapisa koristi se ranije dodeljeni kod.",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	
	notebook.display_text(
		"1) Kodiranje pomoću LZW algoritma započinje inicijalizacijom rečnika, koji na početku " +
		"sadrži pojedinačne karaktere. U većini implementacija rečnik se inicijalizuje sa svih 255 " +
		"ASCII karaktera, u ovom demonstrativnom programu smatramo da rečnik već sadrži sve pojedinačne " +
		"karaktere koje korisnici mogu uneti u ulazni niz, sa svojim odgovarajućim ASCII kodom.",
		2.0
	)
	
	await notebook.displayed_text
	notebook.add_button("Kodiraj").pressed.connect(show_coding)

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
	
	if not input_text.is_empty():
		var two_unique : bool = false
		for i in range(1, input_text.length()):
			if input_text[i] != input_text[0]:
				two_unique = true
				break
		if two_unique:
			start_button.disabled = false
		else:
			start_button.disabled = true
	else:
		start_button.disabled = true
	
	text_count_label.text = str(input_text.length()) + "/12"

func _on_start_button_pressed() -> void:
	start_button.disabled = true
	input.editable = false
	inputDisplay.set_new_input_text(input_text)

func reset():
	notebook.clear_buttons()
	notebook.clear_text()
	
	lzw_dict.reset()
	lzw_step_table.reset()
	inputDisplay.erase()
	
	input.editable = true
	input.text = ""
	input_text = ""
	text_count_label.text = "0/12"
	
	codes.clear()
	code_pos = 0
	
	coded.reset()
	decoded.reset()

func show_coding():
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"2) Tokom kodiranja koriste se dve oznake. P predstavlja trenutno posmatrani podniz, dok C " +
		"predstavlja sledeći karakter iz ulaznog niza. Na početku se prvi karakter ulaznog niza postavlja u " +
		"P. Zatim se uzima sledeći karakter i označava sa C. Posmatra se podniz formiran spajanjem P i C, " + 
		"odnosno P + C. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Ukoliko se podniz P + C već nalazi u rečniku, on se može dalje proširivati, pa se vrednost P postavlja na P + C. " +
		"Zatim se uzima sledeći karakter iz ulaznog niza. Ovo se ponavlja dok se formirani podniz nalazi u rečniku. " +
		"Kada se prvi put naiđe na podniz P + C koji se ne nalazi u rečniku, generiše se izlazni kod za P. " + 
		"Nakon toga se novi podniz P + C dodaje u rečnik na prvu slobodnu poziciju, a P se postavlja na karakter C. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Pokreni kodiranje").pressed
	
	p = input_text[0]
	input_pos = 1
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Prvi karakter ulaznog niza je [color=red]" + p + "[/color], pa se početna sekvenca P postavlja na [color=red]" + p + "[/color].",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	notebook.clear_buttons()
	
	var finished_coding : bool = false
	while (not finished_coding):
		finished_coding = await next_coding_step()
		notebook.clear_buttons()
		notebook.clear_text()
	
	var last_step_text : String = "U poslednjem koraku više nema karaktera koji bi se dodao na P, pa se na izlaz prosleđuje "
	last_step_text += "kod za poslednji formirani podniz. "
	
	last_step_text += "U ovom slučaju poslednji formiran podniz P je [color=red]" + p + "[/color], a "
	last_step_text += "njegov kod je " + str(lzw_dict.get_code(p)) + " i on se za kraj ispisuje na izlaz."
	
	notebook.display_text(
		last_step_text,
		2.0
	)
	await notebook.displayed_text
	
	notebook.add_button("Pređi na dekodiranje").pressed.connect(start_decoding)

func next_coding_step() -> bool:
	inputDisplay.highlight_char(input_pos)
	var c : String = input_text[input_pos]
	
	var step_text : String = ""
	var notebook_text : String = ""
	
	notebook_text += "Trenutna vrednost P je [color=red]" + p + "[/color], "
	notebook_text += "sledeći karakter sa ulaza, odnosno C, je [color=blue]" + c + "[/color]. "
	
	if not lzw_dict.contains(p+c):
		var output_code : String = str(lzw_dict.get_code(p))
		var representing : String = p
		var string : String = p+c
		
		lzw_dict.add_symbol(string)
		var code_word : String = str(lzw_dict.get_code(string))
		
		notebook_text += "Pošto se sekvenca P + C = [color=green]" + p + c + "[/color] ne nalazi u rečniku "
		notebook_text += "na izlaz se ispisuje kod od P, što je S(P) = " + output_code + ". "
		notebook_text += "U rečnik se dodaje [color=green]" + p + c + "[/color] i dobija kod " + code_word + ". "
		notebook_text += "Sada je vrednost P = [color=blue]" + c + "[/color]. "
		
		step_text += "P = " + "[color=red]" + p + "[/color]" 
		step_text += ", C = " + "[color=blue]" + c + "[/color] | "
		step_text += "P + C = " + "[color=green]" + p + c + "[/color] (NIJE U REČNIKU) | "
		step_text += "Na izlazu kod za P: " + output_code + " | "
		step_text += "P = " + "[color=blue]" + c + "[/color]"
		
		codes.append(lzw_dict.get_code(p))
		coded.add_substr(" " + output_code)
		p = c
		
		lzw_dict.add_row([output_code, representing, string, code_word])
	else:
		
		notebook_text += "Pošto se sekvenca P + C = [color=green]" + p + c + "[/color] nalazi u rečniku "
		notebook_text += "P se postavlja na P + C = [color=green]" + p + c + "[/color]. "
		
		step_text += "P = " + "[color=red]" + p + "[/color]" 
		step_text += ", C = " + "[color=blue]" + c + "[/color] | "
		step_text += "P + C = " + "[color=green]" + p + c + "[/color] (JESTE U REČNIKU) | "
		step_text += "P = " + "[color=green]" + p + c + "[/color]"
		
		p = p+c
	
	lzw_step_table.add_step(step_text)
	
	notebook.display_text(notebook_text, 2.0)
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	
	input_pos += 1
	var finished : bool = input_pos >= input_text.length() 
	
	if finished:
		coded.add_substr(" " + str(lzw_dict.get_code(p)))
		codes.append(lzw_dict.get_code(p))
		
		notebook.clear_text()
		notebook.clear_buttons()
		inputDisplay.reset_highlight()
	
	return finished

func start_decoding():
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"3) Postupak LZW dekodiranja zasniva se na ponovnom formiranju rečnika koji je korišćen " +
		"tokom kodiranja. Rečnik formiran tokom kodiranja ne prenosi se zajedno sa kompresovanim " +
		"nizom, već ga dekoder samostalno ponovo kreira tokom procesa dekompresije. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	notebook.clear_buttons()
	
	lzw_dict.reset()
	lzw_dict.set_columns(["Izlazni simbol", "Kod", "Kod", "Simbol"])
	code_pos = 0
	lzw_step_table.reset()
	
	notebook.append_text(
		"Na početku procesa dekoder raspolaže istim rečnikom koji je koder koristio " + 
		"na početku kodiranja. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.append_text(
		"Ulaz u dekoder predstavlja niz kodova dobijenih tokom procesa " + 
		"kompresije. Najpre se uzima prvi kod iz kompresovanog niza i pronalazi mu se odgovarajući " +
		"simbol ili sekvenca u rečniku. Dobijena sekvenca se ispisuje kao deo originalnog niza, a njen kod " +
		"se pamti kao prethodno obrađeni kod. Zatim se uzima sledeći kod i proverava da li se on već " +
		"nalazi u rečniku. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.append_text(
		"Ukoliko se novi kod nalazi u rečniku, određuje se sekvenca koju taj kod predstavlja. " + 
		"Ta sekvenca se dodaje na izlaz, a njen prvi karakter koristi se za formiranje novog unosa u rečniku. " +
		"Novi unos nastaje spajanjem sekvence koja odgovara prethodno obrađenom kodu i prvog " +
		"karaktera sekvence koja odgovara trenutnom kodu. Nakon toga trenutni kod postaje prethodni " +
		"kod i postupak se ponavlja za sledeći kod. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	old = codes[code_pos]
	last_highlighted = coded.highlight_substr(str(old), 0)
	var s : String = lzw_dict.get_symbol(old)
	decoded.add_substr(s)
	code_pos += 1
	
	lzw_step_table.add_step("Old = [color=red]" + str(old) + "[/color] | S = [color=blue]" + s + "[/color]")
	
	var first_step_text : String = ""
	first_step_text += "Prvi kod u kompresovanom nizu je [color=red]" + str(codes[0]) + "[/color], "
	first_step_text += "Što odgovara karakteru [color=red]" + s + "[/color]. "
	first_step_text += "Zbog toga se karakter [color=red]" + s + "[/color] prosleđuje na izlaz, "
	first_step_text += "a kod [color=red]" + str(codes[0]) + "[/color] se pamti kao prethodno obrađeni kod, "
	first_step_text += "u oznaci old = [color=red]" + str(codes[0]) + "[/color]. "
	
	notebook.display_text(
		first_step_text,
		2.0
	)
	
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
		"Može se uočiti da se tokom dekodiranja rečnik formira istim redosledom kao i tokom " + 
		"kodiranja. Iako se uz kompresovani niz ne prenosi kompletan rečnik, dekoder ga može ponovo " + 
		"formirati na osnovu primljenih kodova i unapred definisanog početnog skupa karaktera. " +
		"Upravo ova osobina omogućava da se originalni podaci u potpunosti rekonstruišu bez gubitka " +
		"informacija.",
		2.0
	)
	
	notebook.add_button("Ponovo").pressed.connect(reset)

func next_decode_step() -> bool:
	var new : int = codes[code_pos]
	last_highlighted = coded.highlight_substr(str(new), last_highlighted)
	
	var s : String
	
	var notebook_text : String = ""
	
	notebook_text += "Trenutni kod, odnosno [color=blue]New[/color], je "
	notebook_text += "[color=blue]" + str(new) + "[/color]. "
	
	if not lzw_dict.containts_code(new):
		s = lzw_dict.get_symbol(old)
		s += s[0]
		
		notebook_text += "Kod [color=blue]" + str(new) + "[/color] se još uvek ne nalazi u rečniku. "
		notebook_text += "Zbog toga se koristi posebni slučaj LZW dekodiranja. "
		notebook_text += "Za [color=red]Old = " + str(old) + "[/color] dobijamo "
		notebook_text += "S(Old) = [color=red]" + lzw_dict.get_symbol(old) + "[/color]. "
		notebook_text += "Prvi karakter te sekvence dodajemo na njen kraj, "
		notebook_text += "pa dobijamo S = [color=green]" + s + "[/color]. "
		
	else:
		s = lzw_dict.get_symbol(new)
		
		notebook_text += "Kod [color=blue]" + str(new) + "[/color] se nalazi u rečniku, "
		notebook_text += "pa iz njega dobijamo sekvencu "
		notebook_text += "S = [color=green]" + s + "[/color]. "
	
	notebook.clear_buttons()
	notebook.clear_text()
	notebook.display_text(
		notebook_text,
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	var c : String = s[0]
	
	notebook_text = ""
	notebook_text += "Prvi karakter sekvence S je "
	notebook_text += "C = [color=blue]" + c + "[/color]. "
	
	decoded.add_substr(s)
	
	var old_symbol : String = lzw_dict.get_symbol(old)
	var new_symbol : String = lzw_dict.get_symbol(old) + c 
	
	lzw_dict.add_symbol(new_symbol)
	
	var output_symbol : String = s
	var output_code : String = str(lzw_dict.get_code(s))
	var new_symbol_code : String = str(lzw_dict.get_code(new_symbol))
	
	notebook_text += "Sekvenca S = [color=green]" + s + "[/color] se dodaje na izlaz. "
	notebook_text += "Zatim se u rečnik dodaje "
	notebook_text += "[color=green]" + old_symbol + c + "[/color] "
	notebook_text += "jer se formira spajanjem S(Old) = "
	notebook_text += "[color=red]" + old_symbol + "[/color] "
	notebook_text += "i prvog karaktera C = "
	notebook_text += "[color=blue]" + c + "[/color]. "
	
	notebook_text += "Nova sekvenca u rečniku je "
	notebook_text += "[color=green]" + new_symbol + "[/color] "
	notebook_text += "sa kodom " + new_symbol_code + ". "
	
	notebook_text += "Na kraju se [color=red]Old[/color] postavlja na "
	notebook_text += "[color=blue]" + str(new) + "[/color]."
	
	lzw_dict.add_row([output_symbol, output_code, new_symbol_code, new_symbol])
	
	old = new
	
	lzw_step_table.add_step(
		"Old = [color=red]" + str(old) + "[/color] | S = [color=green]" + s + "[/color] | New = [color=blue]" + str(new) + "[/color] | C = " + c
	)
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		notebook_text,
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	code_pos += 1
	var finished : bool = code_pos >= codes.size()
	return finished
