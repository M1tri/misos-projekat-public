extends Panel

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
