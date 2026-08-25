class_name InputDisplay
extends RichTextLabel

signal set_new_input

var inputText : String = ""
var textPos : int = -1

var eraser : Eraser
var eraserPanel : MarginContainer
var eraser_default_pos : Vector2

func _ready() -> void:
	for child in get_children():
		if child is Sprite2D:
			eraser = child
			eraser_default_pos = eraser.position
		elif child is MarginContainer:
			eraserPanel = child

func erase():
	var eraserTween : Tween = create_tween()
	
	eraser.start_rotating()
	@warning_ignore("integer_division")
	eraserTween.tween_property(
		eraser, 
		"position:x", 
		eraser.texture.get_width()/2, 
		1.8
	)
	
	var eraserPanelTween : Tween = create_tween()
	eraserPanelTween.tween_property(
		eraserPanel,
		"theme_override_constants/margin_left",
		8,
		1.8
	)
	
	@warning_ignore("integer_division")
	await eraserTween.tween_property(
		eraser, 
		"position:x",
		eraser_default_pos.x, 
		0.5
	).finished
	
	inputText = ""
	self.text = "a"
	self.visible_characters = 0
	eraserPanel.size = self.size
	@warning_ignore("narrowing_conversion")
	eraserPanel.add_theme_constant_override("margin_left", eraser.position.x)
	
	eraser.stop_rotating()

func set_new_input_text(new_input_text : String):
	if inputText.length() != 0:
		await erase()
	
	inputText = new_input_text
	textPos = 0
	finish_setting_input()

func finish_setting_input():
	self.text = inputText
	var total_chars : int = self.get_total_character_count()
	self.visible_characters = 0
	
	var tween : Tween = create_tween()
	tween.tween_property(self, "visible_characters", total_chars, 1.0).finished.connect(
		func (): 
			set_new_input.emit()
			)

func highlight_char(char_pos : int):
	if char_pos < 0 or char_pos >= inputText.length():
		return
	
	var new_label_text : String = ""
	for i in range(0, inputText.length()):
		var letter : String = inputText[i]
		if i == char_pos:
			letter = "[color=red]" + letter + "[/color]"
		new_label_text += letter
	
	self.text = new_label_text

func reset_highlight():
	self.text = inputText
