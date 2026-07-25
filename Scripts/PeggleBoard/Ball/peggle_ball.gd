extends RigidBody2D


# SCENES

@export var ball_dot: PackedScene


# TEXTURES

@export var ball_textures: Array[Texture2D] = []


# AUDIO

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

	sprite_2d.texture = (
		ball_textures.pick_random()
	)


func _integrate_forces(
	state: PhysicsDirectBodyState2D
) -> void:
	for contact_index: int in range(
		state.get_contact_count()
	):
		var contact_normal: Vector2 = (
			state.get_contact_local_normal(
				contact_index
			)
		)

		if absf(contact_normal.y) < 0.1:
			if ball_hit_wall_sound != null:
				SfxPlayer.play(
					ball_hit_wall_sound
				)

			break


func _on_dot_cooldown_timeout() -> void:
	if ball_dot == null:
		push_warning(
			"No ball dot scene has been assigned."
		)
		return

	var dot_instance: Node2D = (
		ball_dot.instantiate() as Node2D
	)

	if dot_instance == null:
		push_error(
			"The ball dot scene must have "
			+ "a Node2D root."
		)
		return

	get_tree().current_scene.add_child(
		dot_instance
	)

	dot_instance.global_position = (
		global_position
	)

func _physics_process(delta: float) -> void:
	if global_position.y > 1500:
		queue_free()

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
