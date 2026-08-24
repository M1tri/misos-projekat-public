class_name Eraser
extends Sprite2D

const ANGLE_STEP : float = deg_to_rad(5)

var direction : int = 1
var angleLimit : float = deg_to_rad(30)

var is_rotating : bool = false

func start_rotating():
	is_rotating = true
	direction = 1
	rotation = 0
	change_rotation_direction()

func stop_rotating():
	is_rotating = false

func change_rotation_direction():
	if not is_rotating:
		rotation = 0
		return
	
	direction *= -1
	var tween : Tween = create_tween()
	tween.tween_property(
		self, 
		"rotation", 
		direction*angleLimit, 
		1.0
		).finished.connect(change_rotation_direction)
