class_name ShannonTreeVisualizer
extends Control

const Y_STEP = 150
const X_STEP = 100

const INT_MAX : int = 9223372036854775807

const shannon_tree_node_scene :PackedScene = preload("res://misos-projekat/Scenes/ShannonFano/tree_node.tscn")

class Step:
	var nodesToAdd : Array[ShannonTreeNode]
	
	func _init() -> void:
		nodesToAdd = []
	
	func add(node : ShannonTreeNode):
		nodesToAdd.append(node)

var codes : Dictionary[String, String] = {}

var current_leaf : int = 0
var leaf_count : int = 0

var tree_nodes : Array[ShannonTreeNode] = []
var sequence : Array[Step] = []
var sequence_pos : int = -1

var step_texts : Array[String] = []

var lines : Array[Line2D] = []
var lineLabels : Array[Label] = []

var shannonTreeRoot : ShannonTreeNode = null

func reset():
	for tree_node in tree_nodes:
		tree_node.queue_free()
	
	tree_nodes.clear()
	sequence.clear()
	sequence_pos = -1
	
	for line in lines:
		line.queue_free()
	lines.clear()
	
	queue_redraw()
	shannonTreeRoot = null

func DrawTree(root : ShannonTreeNode):
	reset()
	shannonTreeRoot = root
	
	leaf_count = CountLeaves(root)
	current_leaf = 0
	
	AssignPositions(root, 0)
	
	var firstStep : Step = Step.new()
	firstStep.add(root)
	sequence.append(firstStep)
	
	CalculateSequence(root, 0)
	sequence_pos = 0

func CountLeaves(node : ShannonTreeNode) -> int:
	if node.leftChild == null and node.rightChild == null:
		return 1
	
	var count = 0
	
	if node.leftChild:
		count += CountLeaves(node.leftChild)
	
	if node.rightChild:
		count += CountLeaves(node.rightChild)
	
	return count

func AssignPositions(node : ShannonTreeNode, depth : int):
	if node.leftChild:
		AssignPositions(node.leftChild, depth + 1)
	
	if node.leftChild == null and node.rightChild == null:
		node.target_pos = Vector2(
			(current_leaf - leaf_count / 2.0) * X_STEP + size.x / 2,
			50 + depth * Y_STEP
		)
		
		current_leaf += 1
	
	if node.rightChild:
		AssignPositions(node.rightChild, depth + 1)
	
	if node.leftChild and node.rightChild:
		node.target_pos = Vector2(
			(node.leftChild.target_pos.x + node.rightChild.target_pos.x) / 2,
			50 + depth * Y_STEP
		)

func CalculateSequence(node : ShannonTreeNode, depth : int):
	node.radius -= 2*depth
	
	if node.leftChild == null and node.rightChild == null:
		return
	
	var step : Step = Step.new()
	if (node.leftChild):
		node.leftChild.position = node.target_pos
		step.add(node.leftChild)
	
	if (node.rightChild):
		node.rightChild.position = node.target_pos
		step.add(node.rightChild)
	
	sequence.append(step)
	
	if (node.leftChild):
		CalculateSequence(node.leftChild, depth+1)
	
	if (node.rightChild):
		CalculateSequence(node.rightChild, depth+1)

func GetStepText() -> String:
	return step_texts[sequence_pos]

func NextStep() -> bool:
	for node : ShannonTreeNode in sequence[sequence_pos].nodesToAdd: 
		node.draw_line.connect(draw_line_between_nodes)
		add_child(node)
		tree_nodes.append(node)
	
	sequence_pos += 1
	return sequence_pos == -1 or sequence_pos >= sequence.size()

func get_code(symbol : String) -> String:
	if symbol not in codes:
		return ""
	return codes[symbol]

func move_tree(dx : float, dy : float):
	if shannonTreeRoot == null:
		return
		
	for line in lines:
		line.queue_free()
	lines.clear()
	
	for label in lineLabels:
		label.queue_free()
	lineLabels.clear()
	
	move_tree_internal(dx, dy, shannonTreeRoot)

func move_tree_internal(dx : float, dy : float, node : ShannonTreeNode):
	node.position = node.position + Vector2(dx, dy)
	node.target_pos = node.position
	
	if node.leftChild:
		move_tree_internal(dx, dy, node.leftChild)
		draw_line_between_nodes(node, node.leftChild, "0", Vector2(-10, -10))
	
	if node.rightChild:
		move_tree_internal(dx, dy, node.rightChild)
		draw_line_between_nodes(node, node.rightChild, "1", Vector2(10, -10))

func light_up_leaf(symbol : String, delay : float):
	if shannonTreeRoot == null:
		return
	
	light_up_leaf_internal(symbol, shannonTreeRoot, delay)

func light_up_leaf_internal(symbol : String, node : ShannonTreeNode, delay : float) -> bool:
	if node.is_leaf() and node.get_symbol().contains(symbol):
		node.light_up(delay)
		return true
	
	if node.leftChild != null and light_up_leaf_internal(symbol, node.leftChild, delay):
		return true
	
	if node.rightChild != null and light_up_leaf_internal(symbol, node.rightChild, delay):
		return true
	
	return false

func draw_line_between_nodes(
	node1 : ShannonTreeNode, 
	node2 : ShannonTreeNode, 
	lineText : String,
	labelOffset : Vector2):
	var direction = (node2.target_pos - node1.target_pos).normalized()
	
	var start = node1.target_pos + direction*node1.radius
	var end = node2.target_pos - direction*node2.radius
	
	var line : Line2D = Line2D.new()
	line.default_color = Color.BLACK
	line.width = 2
	
	add_child(line)
	
	var middle : Vector2 = (start + end) / 2
	
	middle.x += labelOffset.x
	middle.y += labelOffset.y
	
	line.points = [start, start]
	var lineTween : Tween = line.create_tween()
	lineTween.tween_method(
		func(t):
			line.points[1] = lerp(start, end, t),
			0.0,
			1.0,
			.5
	).finished.connect(
		func():
			add_line_label(middle, lineText)
	)
	
	lines.append(line)

func add_line_label(pos : Vector2, text : String):
	var lineLabel : Label = Label.new()
	lineLabel.add_theme_font_size_override("font_size", 18)
	lineLabel.add_theme_color_override("font_color", Color.REBECCA_PURPLE)
	
	lineLabel.text = text
	lineLabel.position = pos
	
	add_child(lineLabel)
	lineLabel.position -= lineLabel.size/2
	var target_y : float = lineLabel.position.y
	
	lineLabel.position.y += 10
	lineLabel.modulate.a = 0
	
	var pos_tween : Tween = lineLabel.create_tween()
	pos_tween.tween_property(
		lineLabel,
		"position:y",
		target_y,
		.5
	)
	
	var alpha_tween : Tween = lineLabel.create_tween()
	alpha_tween.tween_property(
		lineLabel,
		"modulate:a",
		1.0,
		.5
	)
	
	lineLabels.append(lineLabel)

class ShannonSymbol:
	var text : String
	var frequency : int
	
	func _init(_text : String, _frequency : int) -> void:
		text = _text
		frequency = _frequency

func calculate_shannon_tree(message : String) -> ShannonTreeNode:
	var symbolFrequencies : Dictionary[String, int] = {}
	
	for s in message:
		if s in symbolFrequencies:
			symbolFrequencies[s] += 1
		else:
			codes[s] = ""
			symbolFrequencies[s] = 1
	
	var symbols : Array[ShannonSymbol] = []
	for s in symbolFrequencies:
		symbols.append(ShannonSymbol.new(s, symbolFrequencies[s]))
	
	symbols.sort_custom(
		func (s1 : ShannonSymbol, s2: ShannonSymbol):
			return s1.frequency > s2.frequency
			)
	
	step_texts.append("Krecemo od root")
	var root : ShannonTreeNode = shannon_fanno(symbols)
	shannonTreeRoot = root
	move_tree(0, 25)
	return root

func shannon_fanno(symbols : Array[ShannonSymbol]) -> ShannonTreeNode:
	if (symbols.size() == 1):
		var leaf : ShannonTreeNode = shannon_tree_node_scene.instantiate()
		leaf.text = symbols[0].text + "\n" + codes[symbols[0].text]
		return leaf
	
	var split : int = 1
	var best_split : int = 1
	var best_diff : int = INT_MAX
	
	while (split < symbols.size()-1):
		
		var left_sum : int = 0
		for i in range(0, split):
			left_sum += symbols[i].frequency
		
		var right_sum : int = 0
		for i in range(split, symbols.size()):
			right_sum += symbols[i].frequency
		
		var diff : int = abs(left_sum - right_sum)
		
		if (diff < best_diff):
			best_diff = diff
			best_split = split
			split += 1
		else:
			break
	
	var left : Array[ShannonSymbol] = []
	var right : Array[ShannonSymbol] = []
	
	for i in range(0, best_split):
		left.append(symbols[i])
		codes[symbols[i].text] += "0"
	
	for i in range(best_split, symbols.size()):
		right.append(symbols[i])
		codes[symbols[i].text] += "1"
	
	var text : String = ""
	for s in symbols:
		text += s.text
	
	var node : ShannonTreeNode = shannon_tree_node_scene.instantiate()
	node.text = text
	
	var step_text : String = str(step_texts.size()+1) + ": "
	step_text += arr_to_str(symbols) + " → "
	step_text += arr_to_str(left) + " [[color=red]" + str(arr_sum(left)) + "[/color]]"
	step_text += " | " + arr_to_str(right) + " [[color=red]" + str(arr_sum(right)) + "[/color]]"
	
	step_texts.append(
		 step_text
		)
	
	node.leftChild = shannon_fanno(left)
	node.rightChild = shannon_fanno(right)
	
	return node

func arr_to_str(array : Array[ShannonSymbol]) -> String:
	var ret : String = ""
	for i in range(0, array.size()-1):
		ret += array[i].text + " "
	ret += array.back().text
	return ret 

func arr_sum(array : Array[ShannonSymbol]) -> int:
	var sum : int = 0
	for s in array:
		sum += s.frequency
	return sum
