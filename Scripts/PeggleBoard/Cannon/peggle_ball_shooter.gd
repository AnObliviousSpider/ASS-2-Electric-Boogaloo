extends Node2D

class_name PeggleCannon


#Eyes
@onready var eye: AnimatedSprite2D = $Eye


# BALL

@export var ball_scene: PackedScene

@export_range(0.0, 4.0, 0.05)
var ball_gravity_scale: float = 0.35

@export_range(0.1, 10.0, 0.1)
var ball_mass: float = 1.0


# SHOOTING

@export var shoot_offset: Vector2 = Vector2.ZERO

@export_range(0.0, 2000.0, 10.0)
var shoot_strength: float = 225.0

@export_range(-180, 0, 1)
var minimum_turn_angle: float = -45.0

@export_range(0, 180, 1)
var maximum_turn_angle: float = 45.0


# TRAJECTORY DOTS

# More points make the predicted path more accurate.
@export_range(2, 100, 1)
var trajectory_point_count: int = 40

# How far into the future we try to predict.
@export_range(0.1, 5.0, 0.05)
var trajectory_duration: float = 1.0

# The dotted line cannot become longer than this.
@export_range(10.0, 500.0, 5.0)
var trajectory_max_length: float = 100.0

# Distance between each visible dot.
@export_range(1.0, 30.0, 0.5)
var trajectory_dot_spacing: float = 8.0

# Size of each visible dot.
@export_range(0.5, 10.0, 0.25)
var trajectory_dot_radius: float = 1.5

@export var trajectory_dot_colour: Color = (
	Color(1.0, 1.0, 1.0, 0.75)
)

# Walls are on layer 1.
# Pegs are on layer 2.
# Layers 1 and 2 together produce mask value 3.
@export_flags_2d_physics
var trajectory_collision_mask: int = 3

# How much speed the predicted ball keeps
# after hitting something.
@export_range(0.0, 1.5, 0.05)
var trajectory_bounce_strength: float = 0.8

# Prevent the prediction from bouncing forever.
@export_range(0, 10, 1)
var trajectory_max_bounces: int = 3

# Move slightly away from a surface after a bounce.
# This prevents the next check from hitting
# the exact same surface immediately.
@export_range(0.1, 5.0, 0.1)
var trajectory_collision_offset: float = 1.0


# BARREL POSITIONS

@export var centre_barrel_position: Vector2 = (
	Vector2(0.0, 13.0)
)

# Barrel position at -45 degrees.
@export var negative_turn_position: Vector2 = (
	Vector2(10.0, 10.0)
)

# Barrel position at 45 degrees.
@export var positive_turn_position: Vector2 = (
	Vector2(-10.0, 10.0)
)


# RECOIL

# The barrel moves four pixels toward the origin.
@export_range(0.0, 10.0, 0.25)
var recoil_distance: float = 4.0

@export_range(0.01, 1.0, 0.01)
var recoil_back_duration: float = 0.06

@export_range(0.01, 1.0, 0.01)
var recoil_return_duration: float = 0.10


# AUDIO

@export var cannon_fire_sfx: AudioStream

@export_range(0.1, 2.0, 0.01)
var minimum_fire_pitch: float = 0.6

@export_range(0.1, 2.0, 0.01)
var maximum_fire_pitch: float = 0.7

@export_range(0.1, 2.0, 0.01)
var rare_fire_pitch: float = 0.5

@export_range(0.0, 1.0, 0.01)
var rare_fire_pitch_chance: float = 0.08


# NODES

@onready var barrel: Sprite2D = (
	$PeggleBallBarrel
)

@onready var firing_point: Node2D = (
	$PeggleBallBarrel/PeggleBallFiringPoint
)

@onready var flash_cooldown: Timer = (
	$FlashCooldown
)

@onready var animation_player: AnimationPlayer = (
	$PeggleBallAnimationPlayer
)


# SHOT DATA

var last_shoot_direction: Vector2 = Vector2.DOWN


# TRAJECTORY DATA

# This stores all the corners of the predicted path.
var trajectory_points: Array[Vector2] = []

var trajectory_visible: bool = true


# RECOIL DATA

var recoil_tween: Tween


func _ready() -> void:
	rotation = 0.0

	barrel.rotation = 0.0
	barrel.position = centre_barrel_position

	flash_cooldown.timeout.connect(
		_on_flash_cooldown_timeout
	)

	queue_redraw()


func _draw() -> void:
	if not trajectory_visible:
		return

	if trajectory_points.size() < 2:
		return

	# We have a list of positions forming the path.
	# This loop walks along that path and draws
	# a small circle every few pixels.
	var distance_until_next_dot: float = 0.0

	for index: int in range(
		trajectory_points.size() - 1
	):
		var segment_start: Vector2 = (
			trajectory_points[index]
		)

		var segment_end: Vector2 = (
			trajectory_points[index + 1]
		)

		var segment_length: float = (
			segment_start.distance_to(
				segment_end
			)
		)

		if segment_length <= 0.0:
			continue

		var segment_direction: Vector2 = (
			segment_start.direction_to(
				segment_end
			)
		)

		var distance_along_segment: float = (
			distance_until_next_dot
		)

		# Keep moving along this little part
		# of the path and place dots.
		while distance_along_segment <= segment_length:
			var dot_position: Vector2 = (
				segment_start
					+ segment_direction
						* distance_along_segment
			)

			draw_circle(
				dot_position,
				trajectory_dot_radius,
				trajectory_dot_colour
			)

			distance_along_segment += (
				trajectory_dot_spacing
			)

		# Remember how far away the next dot is.
		# This keeps the spacing even across corners.
		distance_until_next_dot = (
			distance_along_segment
				- segment_length
		)


func aim_at(
	target_position: Vector2,
	show_trajectory: bool = true
) -> void:
	var target_direction: Vector2 = (
		barrel.global_position
		.direction_to(target_position)
	)

	# The barrel points down at zero degrees.
	# This finds how far left or right it must turn.
	var target_angle: float = (
		Vector2.DOWN.angle_to(
			target_direction
		)
	)

	# Do not let the barrel turn farther
	# than the allowed angles.
	barrel.rotation = clampf(
		target_angle,
		deg_to_rad(minimum_turn_angle),
		deg_to_rad(maximum_turn_angle)
	)

	update_barrel_position()

	trajectory_visible = show_trajectory

	if show_trajectory:
		update_trajectory_points()

	else:
		trajectory_points.clear()
		queue_redraw()


func update_barrel_position() -> void:
	if recoil_tween != null:
		if recoil_tween.is_valid():
			recoil_tween.kill()

		recoil_tween = null

	if barrel.rotation < 0.0:
		var negative_limit: float = absf(
			deg_to_rad(minimum_turn_angle)
		)

		var turn_amount: float = 0.0

		if negative_limit > 0.0:
			turn_amount = clampf(
				absf(barrel.rotation)
					/ negative_limit,
				0.0,
				1.0
			)

		barrel.position = (
			centre_barrel_position.lerp(
				negative_turn_position,
				turn_amount
			)
		)

	else:
		var positive_limit: float = absf(
			deg_to_rad(maximum_turn_angle)
		)

		var turn_amount: float = 0.0

		if positive_limit > 0.0:
			turn_amount = clampf(
				barrel.rotation
					/ positive_limit,
				0.0,
				1.0
			)

		barrel.position = (
			centre_barrel_position.lerp(
				positive_turn_position,
				turn_amount
			)
		)


func get_shoot_direction() -> Vector2:
	# DOWN is the direction at zero rotation.
	# Rotating it gives us the direction
	# the barrel currently points.
	return Vector2.DOWN.rotated(
		barrel.global_rotation
	).normalized()


func update_trajectory_points() -> void:
	trajectory_points.clear()

	# Start the prediction at the barrel opening.
	var start_position: Vector2 = (
		firing_point.global_position
			+ shoot_offset
	)

	# Work out how fast the ball begins moving.
	# More shooting strength means more speed.
	# More mass means less speed from the same push.
	var initial_velocity: Vector2 = (
		get_shoot_direction()
			* shoot_strength
			/ ball_mass
	)

	# Ask the project how strong normal gravity is.
	var default_gravity: float = float(
		ProjectSettings.get_setting(
			"physics/2d/default_gravity",
			980.0
		)
	)

	# Ask which direction gravity pulls.
	# This is normally straight down.
	var gravity_direction: Vector2 = (
		ProjectSettings.get_setting(
			"physics/2d/default_gravity_vector",
			Vector2.DOWN
		)
	)

	# Make gravity weaker or stronger using
	# the same gravity scale as the real ball.
	var gravity_acceleration: Vector2 = (
		gravity_direction.normalized()
			* default_gravity
			* ball_gravity_scale
	)

	# We need at least two points to make a path.
	var safe_point_count: int = maxi(
		trajectory_point_count,
		2
	)

	# Split the future into lots of tiny time steps.
	# Smaller steps usually make the prediction better.
	var step_duration: float = (
		trajectory_duration
			/ float(safe_point_count - 1)
	)

	# Begin at the barrel with the firing velocity.
	var current_position: Vector2 = (
		start_position
	)

	var current_velocity: Vector2 = (
		initial_velocity
	)

	var travelled_distance: float = 0.0
	var bounce_count: int = 0

	# This lets us ask Godot whether something
	# exists between two positions.
	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)

	# Store the first point at the barrel opening.
	trajectory_points.append(
		to_local(current_position)
	)

	for _index: int in range(
		1,
		safe_point_count
	):
		# Gravity changes the ball's velocity
		# a little bit during every time step.
		current_velocity += (
			gravity_acceleration
				* step_duration
		)

		# Guess where the ball will be
		# after this tiny amount of time.
		var predicted_position: Vector2 = (
			current_position
				+ current_velocity
					* step_duration
		)

		# Draw an invisible test ray between
		# the current and predicted positions.
		# The ray checks for walls and pegs.
		var ray_query := (
			PhysicsRayQueryParameters2D.create(
				current_position,
				predicted_position,
				trajectory_collision_mask
			)
		)

		ray_query.collide_with_bodies = true
		ray_query.collide_with_areas = false

		# Ask Godot whether the test ray
		# touched anything.
		var collision: Dictionary = (
			space_state.intersect_ray(
				ray_query
			)
		)

		# If nothing was hit, the segment ends
		# at our predicted position.
		var segment_end: Vector2 = (
			predicted_position
		)

		var collision_normal: Vector2 = (
			Vector2.ZERO
		)

		var did_collide: bool = (
			not collision.is_empty()
		)

		if did_collide:
			# Stop this part of the path
			# exactly where the collision happened.
			segment_end = collision.get(
				"position",
				predicted_position
			)

			# The normal points away from
			# the surface we just hit.
			collision_normal = collision.get(
				"normal",
				Vector2.ZERO
			)

		var segment_length: float = (
			current_position.distance_to(
				segment_end
			)
		)

		# Do not allow the preview to become
		# longer than the chosen maximum.
		if (
			travelled_distance
				+ segment_length
			>= trajectory_max_length
		):
			var remaining_distance: float = (
				trajectory_max_length
					- travelled_distance
			)

			var final_position: Vector2 = (
				current_position
			)

			if segment_length > 0.0:
				final_position += (
					current_position.direction_to(
						segment_end
					)
					* remaining_distance
				)

			trajectory_points.append(
				to_local(final_position)
			)

			break

		travelled_distance += segment_length

		trajectory_points.append(
			to_local(segment_end)
		)

		if did_collide:
			# Stop if we have already predicted
			# the maximum number of bounces.
			if (
				collision_normal == Vector2.ZERO
				or bounce_count
					>= trajectory_max_bounces
			):
				break

			# Bounce the velocity away from
			# the surface that was hit.
			current_velocity = (
				current_velocity.bounce(
					collision_normal
				)
				* trajectory_bounce_strength
			)

			# Move one tiny step away from the surface.
			# Otherwise the next ray might immediately
			# hit the same surface again.
			current_position = (
				segment_end
					+ collision_normal
						* trajectory_collision_offset
			)

			bounce_count += 1

		else:
			# Nothing was hit, so accept
			# the predicted position.
			current_position = (
				predicted_position
			)

	# Tell Godot to draw the new dots.
	queue_redraw()


func fire_at(
	_target_position: Vector2
) -> RigidBody2D:
	if ball_scene == null:
		push_error(
			"No ball scene was assigned to the cannon."
		)
		return null

	last_shoot_direction = (
		get_shoot_direction()
	)

	var spawned_ball: RigidBody2D = (
		_spawn_ball(
			firing_point.global_position
				+ shoot_offset,
			last_shoot_direction
		)
	)

	if spawned_ball == null:
		return null

	trajectory_visible = false
	trajectory_points.clear()
	queue_redraw()

	apply_fire_effects()

	return spawned_ball


func fire_extra_ball(
	spawn_position: Vector2,
	direction: Vector2
) -> RigidBody2D:
	return _spawn_ball(
		spawn_position + shoot_offset,
		direction
	)


func _spawn_ball(
	spawn_position: Vector2,
	direction: Vector2
) -> RigidBody2D:
	if ball_scene == null:
		push_error(
			"No ball scene was assigned to the cannon."
		)
		return null

	var instance: Node = (
		ball_scene.instantiate()
	)

	if not instance is RigidBody2D:
		push_error(
			"The assigned ball scene must use "
			+ "a RigidBody2D root."
		)

		instance.queue_free()
		return null

	var spawned_ball := (
		instance as RigidBody2D
	)

	get_tree().current_scene.add_child(
		spawned_ball
	)

	spawned_ball.global_position = (
		spawn_position
	)

	spawned_ball.mass = ball_mass
	spawned_ball.gravity_scale = ball_gravity_scale

	spawned_ball.apply_central_impulse(
		shoot_strength
			* direction.normalized()
	)

	return spawned_ball


func apply_fire_effects() -> void:
	barrel.modulate = Color(
		2,
		2,
		2
	)

	if animation_player.is_playing():
		animation_player.play(
			"RESET"
		)

	animation_player.play(
		"CANNON_FIRE"
	)

	play_recoil()

	flash_cooldown.start()

	if cannon_fire_sfx != null:
		SfxPlayer.play(
			cannon_fire_sfx,
			false,
			false,
			0.5,
			false,
			0.0,
			0.0,
			false,
			null,
			get_random_fire_pitch()
		)


func play_recoil() -> void:
	if recoil_tween != null:
		if recoil_tween.is_valid():
			recoil_tween.kill()

	# Remember where the barrel was before firing.
	var resting_position: Vector2 = (
		barrel.position
	)

	# Move four pixels closer to the cannon's origin.
	var recoil_position: Vector2 = (
		resting_position.move_toward(
			Vector2.ZERO,
			recoil_distance
		)
	)

	recoil_tween = create_tween()

	# Quickly kick backward.
	recoil_tween.tween_property(
		barrel,
		"position",
		recoil_position,
		recoil_back_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# Then spring back to the aimed position.
	recoil_tween.tween_property(
		barrel,
		"position",
		resting_position,
		recoil_return_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func get_random_fire_pitch() -> float:
	if randf() < rare_fire_pitch_chance:
		return rare_fire_pitch

	return randf_range(
		minimum_fire_pitch,
		maximum_fire_pitch
	)


func _on_flash_cooldown_timeout() -> void:
	barrel.modulate = Color.WHITE

	animation_player.play(
		"RESET"
	)
