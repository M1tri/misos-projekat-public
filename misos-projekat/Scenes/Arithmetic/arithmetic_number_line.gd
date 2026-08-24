class_name ArithmeticNumberLine
extends Node2D

signal finished_drawing

class SymbolInterval:
	var start : float
	var end : float
	
	var start_num : float
	var end_num : float
	
	func _init(_start : float, _end: float, _start_num: float, _end_num: float) -> void:
		start = _start
		end = _end
		start_num = _start_num
		end_num = _end_num

const TOTAL_HEIGHT : int = 50

var lineLength : float = 200
var symbol_subintervals : Dictionary[String, SymbolInterval] = {}

var interval_start : float
var interval_end : float

func draw_number_line(points : Array[float], symbols : Array[String]):
	assert(symbols.size() == points.size()-1)
	
	interval_start = points.front()
	interval_end = points.back()
	
	add_vertical_line(0, 40)
	add_label(Vector2(0, 0), Vector2(0, 40), str(points[0]).pad_decimals(6))
	
	var intervalEnd : Line2D = add_vertical_line(0, 40)
	
	var intervalEndTween : Tween = create_tween()
	intervalEndTween.tween_property(
		intervalEnd,
		"position:x",
		lineLength,
		1.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished.connect(
		func():
			add_label(
			Vector2(lineLength, 0), 
			Vector2(lineLength, 40), 
			str(points.back()).pad_decimals(6)
		)
	)
	
	var baseLine : Line2D = Line2D.new()
	
	baseLine.points = [Vector2(0, 0), Vector2(0, 0)]
	baseLine.default_color = Color.BLACK
	baseLine.width = 6
	
	var baseLineTween : Tween = create_tween()
	baseLineTween.tween_method(
		func(t):
			baseLine.points[1] = Vector2(t, 0),
			0,
			lineLength,
			1.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	add_child(baseLine)
	
	await baseLineTween.finished
	
	mark_points(points, symbols)

func mark_points(points : Array[float], symbols : Array[String]):
	var start : float = points.front()
	var end : float = points.back()
	
	var intervalSize : float = end-start
	
	var prev_x : float = 0.0
	for i in range(1, points.size()-1):
		var x_pos : float = ((points[i] - start) / intervalSize) * lineLength
		var line : Line2D = add_vertical_line(x_pos, 0)
		var lineTween : Tween = line.create_tween()
		
		var tween_index : int = i
		lineTween.tween_method(
			func(t):
				line.points[0].y = -t/2
				line.points[1].y = t/2,
			0,
			20,
			1.6
		).set_trans(Tween.TRANS_BACK).finished.connect(
			func(): 
				add_label(
					Vector2(x_pos, 0), 
					Vector2(x_pos, 20), 
					str(points[i]).pad_decimals(6)).finished.connect(
						func():
							if tween_index == points.size()-2:
								finished_drawing.emit()
							)
					)
				
		add_label(
			Vector2((prev_x+x_pos)/2, 0), 
			Vector2((prev_x+x_pos)/2, -20), 
			symbols[i-1]
		) 
		
		symbol_subintervals[symbols[i-1]] = SymbolInterval.new(prev_x, x_pos, points[i-1], points[i])
		prev_x = x_pos
		
		await get_tree().create_timer(0.2).timeout
	
	add_label(
		Vector2((prev_x+lineLength)/2, 0), 
		Vector2((prev_x+lineLength)/2, -20), 
		symbols.back()
	)
		
	symbol_subintervals[symbols.back()] = SymbolInterval.new(
		prev_x,
		lineLength, 
		points[-2],
		points[-1]
	)

func add_vertical_line(x_pos : float, total_height : float) -> Line2D:
	var line : Line2D = Line2D.new()
	line.points = [Vector2(x_pos, -total_height/2), Vector2(x_pos, total_height/2)]
	line.width = 6
	line.default_color = Color.BLACK
	add_child(line)
	
	return line

func add_label(start_pos : Vector2, end_pos : Vector2, text : String) -> Tween:
	var label : Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.BLACK)
	add_child(label)
	label.position = start_pos - label.size/2
	var labelPosTween : Tween = label.create_tween()
	
	labelPosTween.tween_property(
		label, 
		"position", 
		end_pos-label.size/2, 
		.5
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	label.modulate.a = 0
	
	var labelAlphaTween : Tween = label.create_tween()
	labelAlphaTween.tween_property(
		label, 
		"modulate:a", 
		1.0, 
		.5
	)
	
	return labelAlphaTween

func get_symbol_interval(symbol : String) -> Array[float]:
	if symbol in symbol_subintervals:
		return [symbol_subintervals[symbol].start, symbol_subintervals[symbol].end]
	return []

func get_symbol_numeric_interval(symbol : String) -> Array[float]:
	if symbol in symbol_subintervals:
		return [symbol_subintervals[symbol].start_num, symbol_subintervals[symbol].end_num]
	return []


func mark_interval_midpoint(symbol : String) -> float:
	if symbol not in symbol_subintervals:
		return -1
	
	var interval : SymbolInterval = symbol_subintervals[symbol]
	
	var midPoint : float = interval.start + (interval.end - interval.start) / 2
	
	var circle : Polygon2D = Polygon2D.new()
	circle.color = Color.RED
	var circlePoints : Array[Vector2] = []
	var seg : int = 32
	var angle_step : float = 2*PI / seg
	
	var point_radius : float = 5
	
	var make_circle = func (r):
			circlePoints.clear()
			for i in range(seg+1):
				circlePoints.append(r * Vector2(cos(i*angle_step), sin(i*angle_step)))
			circle.polygon = circlePoints
	
	make_circle.call(point_radius)
	
	circle.polygon = circlePoints
	
	circle.position.x = interval.start
	
	add_child(circle)
	
	var circleTween : Tween = circle.create_tween()
	
	circleTween.tween_property(
		circle,
		"position:x",
		interval.end,
		2.0
	).set_trans(Tween.TRANS_ELASTIC)
	
	circleTween.tween_property(
		circle,
		"position:x",
		midPoint,
		1.0
	).set_trans(Tween.TRANS_ELASTIC)
	
	circleTween.tween_method(
		func (r):
			make_circle.call(r)
			circle.polygon = circlePoints
			,
			point_radius,
			2*point_radius,
			0.8
	).set_trans(Tween.TRANS_BACK)
	
	await circleTween.tween_method(
		func (r):
			make_circle.call(r)
			circle.polygon = circlePoints
			,
			2*point_radius,
			1.5*point_radius,
			0.8
	).set_trans(Tween.TRANS_BACK).finished
	
	var midPointNum : float = interval.start_num + (interval.end_num-interval.start_num)/2
	add_label(Vector2(midPoint, 0), Vector2(midPoint, 20), str(midPointNum).pad_decimals(6))
	
	return midPointNum

func mark_point(value : float):
	if value < interval_start or value > interval_end:
		return
	
	var interval_size : float = interval_end-interval_start
	
	var x_cord : float = ((value-interval_start) / interval_size) * lineLength
	
	var circle : Polygon2D = Polygon2D.new()
	circle.color = Color.RED
	var circlePoints : Array[Vector2] = []
	var seg : int = 32
	var angle_step : float = 2*PI / seg
	
	var point_radius : float = 5
	
	circlePoints.clear()
	for i in range(seg+1):
		circlePoints.append(point_radius * Vector2(cos(i*angle_step), sin(i*angle_step)))
	circle.polygon = circlePoints
	
	circle.position.x = x_cord
	add_child(circle)

func get_point_interval(point : float) -> SymbolInterval:
	for interval : SymbolInterval in symbol_subintervals.values():
		if point >= interval.start_num and point <= interval.end_num:
			return interval
	return null
