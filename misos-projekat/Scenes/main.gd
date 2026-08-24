extends Control

var shannon_fano_scene : PackedScene = preload("res://misos-projekat/Scenes/ShannonFano/shannon_fano.tscn")
var arithmetic_coding_scene : PackedScene = preload("res://misos-projekat/Scenes/Arithmetic/arithmetic_coding.tscn")
var lzw_coding_scene : PackedScene = preload("res://misos-projekat/Scenes/LZW/lzw_coding.tscn")

var selected_coder_instance : Control = null
@onready var vbox : VBoxContainer = $VBoxContainer

@onready var lzw_button : Button = $VBoxContainer/PanelContainer/MarginContainer/Navbar/LZWButton
@onready var shannon_button : Button = $VBoxContainer/PanelContainer/MarginContainer/Navbar/ShannonButton
@onready var arithemtic_button : Button = $VBoxContainer/PanelContainer/MarginContainer/Navbar/ArithemticButton

var disabled_button : Button

func _ready() -> void:
	selected_coder_instance = lzw_coding_scene.instantiate()
	selected_coder_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_coder_instance.size_flags_stretch_ratio = 30.0
	
	lzw_button.disabled = true
	disabled_button = lzw_button
	
	vbox.add_child(selected_coder_instance)

func _on_shannon_button_pressed() -> void:
	if selected_coder_instance != null:
		selected_coder_instance.free()
	
	selected_coder_instance = shannon_fano_scene.instantiate()
	selected_coder_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_coder_instance.size_flags_stretch_ratio = 30.0
	
	disabled_button.disabled = false
	shannon_button.disabled = true
	disabled_button = shannon_button
	vbox.add_child(selected_coder_instance)
	

func _on_arithemtic_button_pressed() -> void:
	if selected_coder_instance != null:
		selected_coder_instance.free()
	
	selected_coder_instance = arithmetic_coding_scene.instantiate()
	selected_coder_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_coder_instance.size_flags_stretch_ratio = 30.0
	
	disabled_button.disabled = false
	arithemtic_button.disabled = true
	disabled_button = arithemtic_button
	vbox.add_child(selected_coder_instance)

func _on_lzw_button_pressed() -> void:
	if selected_coder_instance != null:
		selected_coder_instance.free()
	
	selected_coder_instance = lzw_coding_scene.instantiate()
	selected_coder_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	selected_coder_instance.size_flags_stretch_ratio = 30.0
	
	disabled_button.disabled = false
	lzw_button.disabled = true
	disabled_button = lzw_button
	
	vbox.add_child(selected_coder_instance)

func _on_quit_pressed() -> void:
	get_tree().quit(0)
