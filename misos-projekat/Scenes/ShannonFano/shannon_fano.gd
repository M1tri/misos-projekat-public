class_name ShannonFanno
extends Control

var mainInput : LineEdit

var inputDisplay : InputDisplay

var symbolTableContainer : SymbolTableContainer

var shannonTreeVisualizer : ShannonTreeVisualizer

var notebook : CodingNotebook

var input_text : String = ""
var inputPos : int = -1

@onready var inputAnalysisTimer : Timer = $InputAnalysisTimer
@onready var treeTimer : Timer = $TreeTimer
@onready var start_button : Button = $GUI/HBoxContainer/InputAndCounting/InputMargin/Input/StartButton
@onready var codingTimer : Timer = $CodingTimer

@onready var coded_label : RicherLabel = $GUI/HBoxContainer/Tree/MarginContainer/VBoxContainer/Coded/VBoxContainer/Coded
@onready var decoded_label : RicherLabel = $GUI/HBoxContainer/Tree/MarginContainer/VBoxContainer/Coded/VBoxContainer/Decoded

@onready var text_count_label : Label = $GUI/HBoxContainer/InputAndCounting/InputMargin/Input/TextCount

var curr_node : ShannonTreeNode = null
var code_pos : int = -1

func _ready() -> void:
	print("Shannon")
	
	mainInput = get_tree().get_first_node_in_group("Input")
	mainInput.text_changed.connect(text_changed)
	
	inputDisplay = get_tree().get_first_node_in_group("InputDisplay")
	inputDisplay.set_new_input.connect(start_input_analysis)
	
	symbolTableContainer  = get_tree().get_first_node_in_group("SymbolTableContainer")
	symbolTableContainer.set_column_name(1, "Simbol")
	symbolTableContainer.set_column_name(2, "Broj")
	
	shannonTreeVisualizer = get_tree().get_first_node_in_group("ShannonTreeVisualizer")
	
	notebook = get_tree().get_first_node_in_group("ArithmeticNotebook")
	
	notebook.set_button_colors(
		{
			CodingNotebook.BUTTON_COLOR.NORMAL : Color(0.439, 0.769, 0.541),
			CodingNotebook.BUTTON_COLOR.HOVERED : Color(0.298, 0.565, 0.384),
			CodingNotebook.BUTTON_COLOR.DISABLED : Color(0.435, 0.765, 0.537),
		}
	)
	
	notebook.set_font_size(25)
	
	start_button.disabled = true

func text_changed(new_text : String):
	input_text = new_text
	
	if input_text.length() == 0:
		start_button.disabled = true
	else:
		start_button.disabled = false
	
	text_count_label.text = str(input_text.length()) + "/10"

func _on_start_button_pressed() -> void:
	if input_text.length() == 0:
		return
	
	inputDisplay.set_new_input_text(input_text)
	inputPos = 0
	
	var unique : Array[String] = []
	for c in input_text:
		if c not in unique:
			unique.append(c)
	
	symbolTableContainer.reset()
	symbolTableContainer.adjust_font_size(unique.size())
	
	shannonTreeVisualizer.reset()

func start_input_analysis():
	notebook.display_text(
		"Proces kodiranja Shannon-Fano algoritmom zasniva se na određivanju učestalosti simbola " +
		"u ulaznom nizu i njihovom postepenom razdvajanju u grupe. Pre samog formiranja koda " + 
		"potrebno je odrediti koliko se puta svaki simbol pojavljuje",
		2.0
	)
	await notebook.displayed_text
	
	await notebook.add_button("Prebroji simbole").pressed
	
	inputAnalysisTimer.start()

func _on_input_analysis_timer_timeout() -> void:
	next_char()

func next_char():
	if inputPos < 0 or inputPos >= input_text.length():
		inputDisplay.reset_highlight()
		
		notebook.clear_text()
		notebook.clear_buttons()
		
		notebook.display_text(
			"Nakon prebrojavanja, simboli se sortiraju prema " +
			"opadajućem broju pojavljivanja. Tako se najčešće zastupljeni simboli nalaze na početku liste, dok " + 
			"se ređi simboli nalaze na njenom kraju",
			2.0
		)
		
		await notebook.displayed_text
		
		await notebook.add_button("Sortiraj simbole").pressed
		
		symbolTableContainer.sort()
		
		await symbolTableContainer.sorted
		
		notebook.clear_buttons()
		notebook.clear_text()
		
		notebook.display_text(
			"Sledeći korak predstavlja formiranje stabla. ",
			1.0
		)
		
		await notebook.displayed_text
		
		var button : Button = notebook.add_button("Dalje")
		button.pressed.connect(show_tree)
		await button.pressed
		
		var root : ShannonTreeNode = shannonTreeVisualizer.calculate_shannon_tree(mainInput.text)
		
		shannonTreeVisualizer.DrawTree(root)
		shannonTreeVisualizer.NextStep()
		
		return
	
	var next : String = input_text[inputPos]
	
	symbolTableContainer.process_symbol(next)
	inputAnalysisTimer.start()
	inputDisplay.highlight_char(inputPos)
	inputPos += 1

func show_tree():
	notebook.clear_buttons()
	
	notebook.append_text(
		"Krećemo od čvora koji predstavlja sve simbole, ovaj čvor će biti koren stabla. ",
		1.0
	)
	
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	
	var finished : bool = false
	
	var step_count : int = 1
	while (not finished):
		var step_text : ShannonTreeVisualizer.StepText = shannonTreeVisualizer.GetStepText()
		
		notebook.clear_buttons()
		notebook.clear_text()
		
		var text : String = "U " + str(step_count) + ". koraku obrađujemo grupu simbola\n"
		text += step_text.full_array + "\n"
		text += "Ovu grupu delimo u dve podgrupe:\n" + step_text.left + " | " + step_text.right + "\n"
		
		notebook.display_text(
			text,
			2.0
		)
		
		await notebook.displayed_text
		await notebook.add_button("Dalje").pressed
		
		text = step_text.full_array + " → " + step_text.left + " | " + step_text.right
		text +=  "\nNa ovaj način početna grupa se deli na dve sa ukupnim brojem pojavljivanja "
		text += str(step_text.left_sum) + " i " + str(step_text.right_sum) + " respektivno. "
		text += "U stablu se formiraju dve grane iz početnog čvora, pri čemu se levoj grani dodeljuje 0, a desnoj 1."
		
		notebook.clear_buttons()
		notebook.clear_text()
		notebook.display_text(
			text,
			2.0
		)
		
		await notebook.displayed_text
		await notebook.add_button("Dalje").pressed
		
		finished = shannonTreeVisualizer.NextStep()
		step_count += 1
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Postupak se završava kada svaka grupa sadrži tačno jedan simbol. U čvorovima koji nisu " +
		"listovi prikazane su grupe simbola koje nastaju tokom uzastopnih podela, dok se u listovima " +
		"nalaze pojedinačni simboli.",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Na osnovu formiranog stabla mogu se odrediti kodne reči pojedinačnih simbola. Kod se " +
		"dobija praćenjem putanje od korena do lista i zapisivanjem vrednosti grana, pri čemu leva grana " + 
		"predstavlja 0, a desna 1",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Zapiši kodove").pressed
	
	var codes : Dictionary[String, String] = shannonTreeVisualizer.get_codes()
	
	for symbol in codes:
		shannonTreeVisualizer.light_up_leaf(symbol, 1.0)
		symbolTableContainer.change_symbol_counter_text(symbol, codes[symbol])
		symbolTableContainer.highlight_row(symbol, 1.0)
		await get_tree().create_timer(1.3).timeout
	
	symbolTableContainer.set_column_name(2, "Kod")
	inputPos = 0
	notebook.clear_buttons()
	notebook.add_button("Pređi na kodiranje").pressed.connect(show_coding)

func show_coding():
	notebook.clear_buttons()
	notebook.display_text(
		"Ove kodne reči se zatim koriste za predstavljanje simbola u procesu Shannon-Fano " +
		"kodiranja. Za dati ulazni niz, svaki simbol se zamenjuje odgovarajućom kodnom rečju. ",
		2.0
	)
	
	await notebook.displayed_text
	
	coded_label.set_new_text("")
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Prvi simbol ulaznog niza je " + input_text[0] + ", a njemu odgovara kod " +
		shannonTreeVisualizer.get_code(input_text[0]) + ". U prvom koraku kodiranja " +
		"taj kod pišemo na izlaz. ",
		2.0
	)
	
	await notebook.displayed_text
	
	var finished : bool = NextCodeStep()
	while (not finished):
		if inputPos == 1:
			notebook.clear_buttons()
			notebook.append_text(
				"Ovo nastavljamo dok nismo obradili čitav ulazni niz.",
				1.0
			)
			await notebook.add_button("Dalje").pressed
		
		finished = NextCodeStep()
		await get_tree().create_timer(1).timeout
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Ovakvim postupkomn kodiranja svaki simbol originalnog niza jednoznačno je predstavljen odgovarajućom " + 
		"Shannon-Fano kodnom rečju. ",
		2.0
	)
	
	await notebook.add_button("Dalje").pressed

	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Shannon-Fano stablo ne mora uvek imati potpuno isti oblik, jer način podele simbola " +
		"može zavisiti od izbora između podgrupa sa približno jednakim brojem pojavljivanja. Takođe, " +
		"vrednosti 0 i 1 mogu se dodeliti granama na različite načine.",
		2.0
	)
	
	await notebook.add_button("Dalje").pressed

	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"U ovom radu usvojeno je pravilo da leva grana ima vrednost 0, a desna 1, " + 
		"dok bi izbor leve grane kao 1, a desne kao 0 doveo do drugačijih kodnih reči, " +
		"princip kodiranja i dekodiranja bi ostao isti. Bitno je da se izabrano " +
		"pravilo dosledno primenjuje na celo stablo.",
		2.0
	)
	
	notebook.add_button("Pređi na dekodiranje").pressed.connect(show_decoding)

func show_decoding():
	notebook.clear_buttons()
	notebook.clear_text()
	
	curr_node = shannonTreeVisualizer.shannonTreeRoot
	code_pos = 0
	curr_node.highlight()
	
	notebook.display_text(
		"Dekodiranje predstavlja obrnut proces u odnosu na kodiranje. Cilj dekodiranja je da se na " +
		"osnovu binarnog niza i prethodno formiranog Shannon-Fano stabla ponovo dobije originalni niz " + 
		"simbola. Za razliku od kodiranja, tokom dekodiranja nije potrebno ponovo određivati broj " +
		"pojavljivanja simbola niti formirati stablo, već se koristi već postojeća struktura stabla.",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Dekodiranje započinje u korenu Shannon-Fano stabla. Binarni niz se čita redom, bit po " +
		"bit. Za svaki pročitani bit bira se odgovarajuća grana stabla. ",
		2.0
	)
	
	await notebook.displayed_text
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	
	notebook.display_text(
		"Kada se dođe do lista, pronađen je jedan simbol originalnog niza. Simbol koji se nalazi u " +
		"tom listu dodaje se u rezultat dekodiranja, a postupak se zatim ponavlja od korena stabla za " +
		"sledeći bit kompresovanog niza.",
		2.0
	)
	await notebook.displayed_text
	await notebook.add_button("Dekodiraj").pressed
	
	while (code_pos < coded_label.display_text.length()):
		var bit : String = coded_label.get_char(code_pos)
		coded_label.highlight_char(code_pos)
		
		curr_node.unhighlight()
		if bit == "0":
			curr_node = curr_node.leftChild
		elif bit == "1":
			curr_node = curr_node.rightChild
		
		curr_node.highlight()
		if curr_node.is_leaf():
			
			notebook.clear_buttons()
			notebook.clear_text()

			var symbol : String = curr_node.get_symbol()
			
			notebook.display_text(
				"Dosli smo do lista koji odgovara simbolu " + symbol + " " +
				"sada njega pisemo na izlaz i vracamo se na koren stabla",
				2.0
			)
			
			await notebook.displayed_text
			await notebook.add_button("Dalje").pressed
			
			decoded_label.add_char(symbol)
			
			curr_node.unhighlight()
			curr_node = shannonTreeVisualizer.shannonTreeRoot
			curr_node.highlight()
		
		await get_tree().create_timer(.5).timeout
		code_pos += 1
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	curr_node.unhighlight()
	
	notebook.display_text(
		"Došli smo do kraja kodiranog niza. Na ovaj način Shannon-Fano dekodiranje " + 
		"omogućava potpuno vraćanje originalnih podataka iz njihovog kompresovanog oblika, bez gubitka informacija.",
		2.0
	)

func NextCodeStep() -> bool:
	var symbol : String = input_text[inputPos]
	
	var delay : float = 0.5
	
	inputDisplay.highlight_char(inputPos)
	symbolTableContainer.highlight_row(symbol, delay)
	shannonTreeVisualizer.light_up_leaf(symbol, delay)
	
	coded_label.add_char(shannonTreeVisualizer.get_code(symbol))
	
	inputPos += 1
	
	return inputPos >= input_text.length()
