extends RigidBody2D

# EXPORTED VARIABLES
@export var rocket_speed: float

func _ready() -> void:
	apply_impulse(Vector2.UP * rocket_speed)
