extends RigidBody2D


# TEXTURES

@export var ball_textures: Array[Texture2D] = []

@export var ball_hit_wall_sound: AudioStream



# NODES

@onready var collision_shape_2d: CollisionShape2D = (
	$CollisionShape2D
)

@onready var sprite_2d: Sprite2D = (
	$Sprite2D
)


func _ready() -> void:
	if ball_textures.is_empty():
		push_warning(
			"No ball textures have been assigned."
		)
		return

	sprite_2d.texture = ball_textures.pick_random()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):

		if abs(state.get_contact_local_normal(i).y) < 0.1: 
			SfxPlayer.play(ball_hit_wall_sound)
			break



func ghost_ball():
	collision_mask=1+3
	await get_tree().create_timer(1).timeout
	collision_mask=1+2+3
	# Choose the texture once when the ball spawns.
	sprite_2d.texture = (
		ball_textures.pick_random()
	)


func ghost_ball() -> void:
	# Collide with walls and other balls,
	# but temporarily ignore pegs.
	set_collision_mask_value(
		1,
		true
	)

	set_collision_mask_value(
		2,
		false
	)

	set_collision_mask_value(
		3,
		true
	)

	await get_tree().create_timer(
		1.0
	).timeout

	if not is_instance_valid(self):
		return

	# Restore collisions with walls,
	# pegs, and other balls.
	set_collision_mask_value(
		1,
		true
	)

	set_collision_mask_value(
		2,
		true
	)

	set_collision_mask_value(
		3,
		true
	)
