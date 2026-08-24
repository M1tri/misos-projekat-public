class_name InputAnalysis
extends Control

@onready var label : RichTextLabel = $RichTextLabel

var text : String

func _ready() -> void:
	pass

func set_text(new_text):
	text = new_text
	label.text = text

func highlight_letter(textPos : int):
	if textPos >= text.length():
		return
	
	var new_label_text : String = ""
	
	for i in range(0, text.length()):
		var letter : String = text[i]
		if i == textPos:
			letter = "[color=red]" + letter + "[/color]"
		new_label_text += letter
	
	label.text = new_label_text
