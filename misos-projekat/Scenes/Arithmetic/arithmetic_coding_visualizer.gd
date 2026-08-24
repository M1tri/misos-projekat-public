class_name ArithmeticCodingVisualizer
extends Control

const TOP_PADDING : int = 40

var number_lines : Array[ArithmeticNumberLine] = []
var numberLine_spacing : float

@warning_ignore("unused_signal")
signal processing_symbol(numberLine : ArithmeticNumberLine)

signal finished_step(start : float, end : float)
signal finished_coding(code : float)

signal finished_decoding_step

var other_lines : Array[Line2D] = []

var code : float

func _draw() -> void:
	draw_grid()

func draw_grid():
	var cell_size : Vector2i = Vector2i(25, 25)

	@warning_ignore("integer_division", "narrowing_conversion")
	var x_step_count : int = self.size.x / cell_size.x

	@warning_ignore("integer_division", "narrowing_conversion")
	var y_step_count : int = self.size.y / cell_size.y

	for x in range(0, x_step_count):
		draw_line(Vector2(x*cell_size.x, 0), Vector2(x*cell_size.x, self.size.y), Color.GRAY)

	for y in range(0, y_step_count):
		draw_line(Vector2(0, y*cell_size.y), Vector2(self.size.x, y*cell_size.y), Color.GRAY)

func reset():
	for n in number_lines:
		n.queue_free()
	number_lines.clear()
	
	for n in other_lines:
		n.queue_free()
	other_lines.clear()

func calculate_numberLine_spacing(total_lines : int):
	var total_space : float = (size.y - TOP_PADDING)
	var space_per_line : float = total_space / total_lines
	numberLine_spacing = space_per_line

func get_number_line_y_pos(prev_number_lines):
	return TOP_PADDING + prev_number_lines * numberLine_spacing

var message : String
var messsage_pos : int

var symbol_percentages : Dictionary[String, float] = {}
var points : Array[float] = []
var symbols : Array[String] = []

var decompression_step_count : int = -1

func beggin_compression(input_message : String):
	message = input_message
	messsage_pos = 0
	calculate_numberLine_spacing(message.length())
	
	for s in message:
		if s in symbol_percentages:
			symbol_percentages[s] += 1
		else:
			symbol_percentages[s] = 1
	
	for s in symbol_percentages:
		symbol_percentages[s] = symbol_percentages[s] / message.length()
	
	points = get_points(0, 1, symbol_percentages)
	symbols = symbol_percentages.keys()
	
	await draw_number_line(points, symbols)
	finished_step.emit(number_lines.back())

func next_coding_step():
	if messsage_pos != message.length()-1:
		var pos : int = symbols.find(message[messsage_pos])
		
		assert(pos != -1, "Should not happen, every symbol from message has to be here")
		
		await add_lines(number_lines.back().get_symbol_interval(message[messsage_pos]))
		
		var start : float = points[pos]
		var end : float = points[pos+1]
		
		points = get_points(start, end, symbol_percentages)
		await draw_number_line(points, symbols)
		finished_step.emit(number_lines.back())
	else:
		code = await number_lines.back().mark_interval_midpoint(message[message.length()-1])
		finished_coding.emit(code)
	messsage_pos += 1

func beggin_decompression():
	reset()
	
	decompression_step_count = 0
	
	points = get_points(0, 1, symbol_percentages)
	await draw_number_line(points, symbols)

func mark_code() -> ArithmeticNumberLine.SymbolInterval:
	await number_lines.back().mark_point(code)
	var code_interval : ArithmeticNumberLine.SymbolInterval = number_lines.back().get_point_interval(code)
	
	return code_interval

func next_decompression_step():
	var code_interval : ArithmeticNumberLine.SymbolInterval = number_lines.back().get_point_interval(code)	
	await add_lines([code_interval.start, code_interval.end])
	
	var start : float = code_interval.start_num
	var end : float = code_interval.end_num
	
	points = get_points(start, end, symbol_percentages)
	await draw_number_line(points, symbols)
	
	finished_decoding_step.emit()

func add_lines(symbolInterval : Array[float]):
		var lastNumberLine : ArithmeticNumberLine = number_lines.back()
		
		var subIntervalStart : Vector2 = Vector2(
			lastNumberLine.position.x + symbolInterval[0], 
			lastNumberLine.position.y
		)
		
		var subIntervalEnd : Vector2 = Vector2(
			lastNumberLine.position.x + symbolInterval[1], 
			lastNumberLine.position.y
		)
		
		var nextNumberLineStart : Vector2 = Vector2(
			size.x/10,
			get_number_line_y_pos(number_lines.size())
		)
		
		var nextNumberLineEnd : Vector2 = Vector2(
			size.x - size.x/10,
			get_number_line_y_pos(number_lines.size())
		)
		
		var subIntervalLine : Line2D = Line2D.new()
		
		subIntervalLine.default_color = Color.GREEN
		subIntervalLine.width = 6
		
		subIntervalLine.points = [
			subIntervalStart,
			subIntervalEnd
		]
		
		add_child(subIntervalLine)
		other_lines.append(subIntervalLine)
		
		var subIntervalFlashingTween : Tween = create_tween()
		
		for i in range(5):
				subIntervalFlashingTween.tween_property(
					subIntervalLine,
					"default_color",
					Color.GREEN if i % 2 == 0 else Color.BLACK,
					.5 
				)

		await subIntervalFlashingTween.finished
		
		var red_line : Line2D = Line2D.new()
		red_line.default_color = Color.GREEN
		red_line.width = 6
		
		red_line.points = [
			subIntervalStart,
			subIntervalEnd
		]
		
		add_child(red_line)
		other_lines.append(red_line)
		
		var direction : Vector2 = nextNumberLineStart-subIntervalStart
		var start_line_slope : float = abs(direction.angle_to(Vector2.DOWN))
		var start_line_length : float = remap(start_line_slope, 0, PI/2, 0.8, 0.95)
		draw_shortened_pointed_line(subIntervalStart, nextNumberLineStart, start_line_length, 2.0)
		
		direction = nextNumberLineEnd-subIntervalEnd
		var end_line_slope : float = abs(direction.angle_to(Vector2.DOWN))
		var end_line_length : float = remap(end_line_slope, 0, PI/2, 0.8, .95)
		draw_shortened_pointed_line(subIntervalEnd, nextNumberLineEnd, end_line_length, 2.0)
		
		var subIntervalLineTween : Tween = subIntervalLine.create_tween()
		await subIntervalLineTween.tween_method(
			func (t):
				subIntervalLine.points[0] = lerp(
					subIntervalStart,
					nextNumberLineStart,
					t
				)
				subIntervalLine.points[1] = lerp(
					subIntervalEnd,
					nextNumberLineEnd,
					t
				),
				0.0,
				1.0,
				2.0
		).finished

func draw_shortened_pointed_line(start : Vector2, end : Vector2, length_percentage : float, growth_time : float):
	if length_percentage > 1.0:
		length_percentage = 1.0
	
	var line : Line2D = Line2D.new()
	
	var lineDirection : Vector2 = end-start
	var lineEnd = start + length_percentage*lineDirection
	
	line.width = 4
	line.default_color = Color.RED
	line.points = [
		start, 
		start
	]
	
	add_child(line)
	other_lines.append(line)
	
	var lineTween : Tween = line.create_tween()
	await lineTween.tween_method(
		func (t):
			line.points[1] = lerp(
				start, 
				lineEnd, 
				t
			),
		0.0,
		1.0,
		growth_time
	).finished
	
	var arrow_dir : Vector2 = (lineEnd - start).normalized()
	var arrow_len : float = 20.0
	
	var arrow_tip1 : Vector2 = lineEnd + arrow_dir.rotated(deg_to_rad(180+45))*arrow_len
	var arrow_tip2 : Vector2 = lineEnd + arrow_dir.rotated(deg_to_rad(180-45))*arrow_len
	
	var arrow_line1 : Line2D = Line2D.new()
	
	arrow_line1.default_color = Color.RED
	arrow_line1.width = 3
	arrow_line1.points = [lineEnd, lineEnd]
	
	var arrow_line1Tween : Tween = create_tween()
	arrow_line1Tween.tween_method(
		func (t): arrow_line1.points[1] = lerp(lineEnd, arrow_tip1, t),
		0.0,
		1.0,
		.6
	)
	
	add_child(arrow_line1)
	other_lines.append(arrow_line1)
	
	var arrow_line2 : Line2D = Line2D.new()
	var arrow_line2Tween : Tween = create_tween()
		
	arrow_line2Tween.tween_method(
		func (t): arrow_line2.points[1] = lerp(lineEnd, arrow_tip2, t),
		0.0,
		1.0,
		.6
	)
	
	arrow_line2.default_color = Color.RED
	arrow_line2.width = 3
	arrow_line2.points = [lineEnd, arrow_tip2]
	
	add_child(arrow_line2)
	other_lines.append(arrow_line2)

@warning_ignore("shadowed_variable")
func get_points(start : float, end : float, symbol_percentages) -> Array[float]:
	@warning_ignore("shadowed_variable")
	var points : Array[float] = []
	points.append(start)
	
	var index : int = 1
	for s in symbol_percentages:
		points.append(points[index-1] + (end-start) * symbol_percentages[s])
		#print(s + " : " + str(points[index]))
		index += 1
	
	return points

@warning_ignore("shadowed_variable")
func draw_number_line(points : Array[float], symbols : Array[String]):
	var numberLine : ArithmeticNumberLine = ArithmeticNumberLine.new()
	numberLine.position.y = get_number_line_y_pos(number_lines.size())
	
	numberLine.position.x = size.x/10.0
	numberLine.lineLength = size.x - 2*(size.x/10)
	
	add_child(numberLine)
	number_lines.append(numberLine)
	numberLine.draw_number_line(points, symbols)
	
	await numberLine.finished_drawing
