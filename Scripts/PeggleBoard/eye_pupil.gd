extends Sprite2D


@export var horizontal_limit: float = 12.0
@export var vertical_limit: float = 8.0
@export var follow_speed: float = 15.0
@export_range(0.0, 1.0) var follow_amount: float = 0.5


func _process(delta: float) -> void:
	var mouse_local: Vector2 = get_parent().to_local(
		get_global_mouse_position()
	)

	var target_position: Vector2 = mouse_local

	var ellipse_position := Vector2(
		target_position.x / horizontal_limit,
		target_position.y / vertical_limit
	)

	if ellipse_position.length() > 1.0:
		ellipse_position = ellipse_position.normalized()

	target_position = Vector2(
		ellipse_position.x * horizontal_limit,
		ellipse_position.y * vertical_limit
	)

	# Move only partway towards the cursor.
	target_position *= follow_amount

	position = position.lerp(
		target_position,
		1.0 - exp(-follow_speed * delta)
	)
