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
		"Prvi korak je da vidimo koji sve karakteri ima u ulaz i " +
		"kolko puta se koji javlja",
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
			"Nakon prebrojavanja neophodno je sortirati listu simbolu " +
			"po broju pojavljivanja od najcesceg do najredjeg simbola",
			2.0
		)
		
		await notebook.displayed_text
		
		await notebook.add_button("Sortiraj simbole").pressed
		
		symbolTableContainer.sort()
		
		await symbolTableContainer.sorted
		
		notebook.clear_buttons()
		notebook.clear_text()
		
		notebook.display_text(
			"Nakon sortiranja liste mozemo da krenemo sa crtanjem stabla",
			2.0
		)
		
		await notebook.displayed_text
		
		var button : Button = notebook.add_button("Crtaj stablo")
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
	notebook.clear_text()
	notebook.clear_buttons()
	
	notebook.display_text(
		"Krecemo od cvora koji predstavlja sve simbole, ovaj cvor ce biti koren stabla",
		2.0
	)
	
	await notebook.displayed_text
	
	await notebook.add_button("Dalje").pressed
	
	var finished : bool = false
	
	while (not finished):
		var step_text : String = shannonTreeVisualizer.GetStepText()
		
		notebook.clear_buttons()
		notebook.clear_text()
		
		notebook.display_text(
			step_text,
			2.0
		)
		
		await notebook.displayed_text
		await notebook.add_button("Dalje").pressed
		
		finished = shannonTreeVisualizer.NextStep()
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Gotovo je sad se treba kodira",
		2.0
	)
	
	inputPos = 0
	notebook.add_button("Kodiraj").pressed.connect(show_coding)

func show_coding():
	notebook.clear_buttons()
	notebook.display_text(
		"Kodiranje je izuzetno prosto jer kodove simbola smo dobili tokom " +
		"formiranja stabla i odatle direktno citamo kod za svaki simbol iz ulaza " +
		"i to pisemo na izlaz",
		2.0
	)
	
	await notebook.displayed_text
	symbolTableContainer.set_column_name(2, "Kod")
	for symbol in input_text:
		symbolTableContainer.change_symbol_counter_text(symbol, shannonTreeVisualizer.get_code(symbol))
	
	coded_label.set_new_text("")
	
	await notebook.add_button("Dalje").pressed
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	var finished : bool = NextCodeStep()
	while (not finished):
		notebook.clear_buttons()
		await notebook.add_button("Dalje").pressed
		finished = NextCodeStep()
	
	notebook.clear_buttons()
	notebook.clear_text()
	
	notebook.display_text(
		"Sad se treba pokazuje dekodiranje",
		2.0
	)
	
	notebook.add_button("Dalje").pressed.connect(show_decoding)

func show_decoding():
	notebook.clear_buttons()
	notebook.clear_text()
	
	curr_node = shannonTreeVisualizer.shannonTreeRoot
	code_pos = 0
	curr_node.highlight()
	
	notebook.display_text(
		"Dekodiranje se radi tako sto se ide bit po bit kroz kodirani podatak " +
		"i kad je 0 ide se levo kad je 1 desno krece se od root kad se dodje do list " +
		"znaci da se taj simbol dekodirao i onda se opet nastavlja od root ce smisli " +
		"pookie bolji tekst ja nju volim mnogo",
		2.0
	)
	
	await notebook.displayed_text
	
	await notebook.add_button("Ajde dekodiraj").pressed
	
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
		"Da se izjedu neka govna za kraj",
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
