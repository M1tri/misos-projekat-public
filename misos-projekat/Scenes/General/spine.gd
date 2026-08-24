extends Panel

const HOLE_RADIUS : float = 8
const HOLE_PADDING : float = 12

const LINE_WIDTH : float = 6

func _draw() -> void:
	var circle_x : float = self.size.x/2
	var space_for_holes : float = self.size.y - 2*HOLE_RADIUS
	@warning_ignore("narrowing_conversion")
	var holes_count : int = space_for_holes / (2*HOLE_RADIUS + HOLE_PADDING)
	
	for i in range(0, holes_count):
		var circle_y : float = 2*HOLE_RADIUS+HOLE_PADDING + i*(2*HOLE_RADIUS+HOLE_PADDING)
		draw_circle(Vector2(circle_x, circle_y), HOLE_RADIUS, Color.BLACK)
		draw_circle(Vector2(circle_x, circle_y), LINE_WIDTH/2, Color.GRAY)
		draw_line(Vector2(circle_x, circle_y), Vector2(0, circle_y), Color.GRAY, LINE_WIDTH)
