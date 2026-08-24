class_name ShannonTreeNode
extends Node2D

signal draw_line(node1 : ShannonTreeNode, node2 : ShannonTreeNode)

var target_pos : Vector2

var leftChild : ShannonTreeNode = null
var rightChild : ShannonTreeNode = null

var text : String = ""

const DEFAULT_RADIUS : int = 48
var radius : float = DEFAULT_RADIUS

@onready var body : Polygon2D = $Polygon2D
@onready var label : Label = $Label

@onready var outline : Line2D = $Line2D

signal line_to_parent(node : ShannonTreeNode)

func _ready() -> void:
	label.text = text
	var tween = create_tween()
	tween.tween_property(
		self, 
		"position", 
		target_pos, 
		0.8
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished.connect(
		func (): line_to_parent.emit(self)
	)
	
	if leftChild:
		leftChild.line_to_parent.connect(draw_line_to_child)
	
	if rightChild:
		rightChild.line_to_parent.connect(draw_line_to_child)
	
	draw_body(radius, Color.BLACK)

func draw_line_to_child(child : ShannonTreeNode):
	var bit : String = "0" if child == leftChild else "1" # :(
	var dx : float = -10 if child == leftChild else 10 # :( :( :(
	
	draw_line.emit(self, child, bit, Vector2(dx, -10))

func draw_body(r : float, color : Color):
	var points = PackedVector2Array()
	var seg : int = 32
	
	var step : float = 2*PI/seg
	for i in range(seg+1):
		var angle = i * step
		points.append((r) * Vector2(cos(angle), sin(angle)))
	
	outline.points = points
	outline.default_color = color
	outline.width = 4
	outline.antialiased = true
	
	body.polygon = points
	body.color = Color.GREEN if is_leaf() else Color.WHITE

func light_up(delay):
	outline.default_color = Color.RED
	
	var tween : Tween = create_tween()
	tween.tween_method(
		func (t):
			draw_body(lerp(DEFAULT_RADIUS+10, DEFAULT_RADIUS, t), lerp(Color.RED, Color.BLACK, t)),
			0.0,
			1.0,
			delay
	)

func highlight():
	draw_body(DEFAULT_RADIUS+10, Color.RED)

func unhighlight():
	draw_body(DEFAULT_RADIUS, Color.BLACK)

func is_leaf() -> bool:
	return self.leftChild == null and self.rightChild == null

func get_symbol() -> String:
	if is_leaf():
		return label.text[0]
		
	return label.text
