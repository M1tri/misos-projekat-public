class_name LZWStepTable
extends VBoxContainer

var rows : Array[RichTextLabel] = []

var font = load("res://misos-projekat/assets/fonts/AnnieUseYourTelescope-Regular.ttf")

func add_step(text : String):
	var label : RichTextLabel = RichTextLabel.new()
	
	label.fit_content = true
	label.bbcode_enabled = true
	
	var label_text : String = str(rows.size()+1) + ") "
	label_text += text
	
	label.text = label_text
	
	label.add_theme_font_override("normal_font", font)
	label.add_theme_font_size_override("normal_font_size", 28)
	label.add_theme_color_override("default_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(label)
	rows.append(label)

func reset():
	for step in rows:
		step.queue_free()
	rows.clear()
