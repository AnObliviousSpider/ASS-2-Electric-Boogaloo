extends Node2D

class_name PeggleCannon


# EYE

@onready var eye_pupil: Sprite2D = $Eye/EyePupil


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

@export_range(2, 100, 1)
var trajectory_point_count: int = 40

@export_range(0.1, 5.0, 0.05)
var trajectory_duration: float = 1.0

@export_range(10.0, 500.0, 5.0)
var trajectory_max_length: float = 100.0

@export_range(1.0, 30.0, 0.5)
var trajectory_dot_spacing: float = 8.0

@export_range(0.5, 10.0, 0.25)
var trajectory_dot_radius: float = 1.5

@export var player_trajectory_dot_colour: Color = (
	Color("54cea7")
)

@export var enemy_trajectory_dot_colour: Color = (
	Color("ff82bd")
)

# Walls use layer 1.
# Pegs use layer 2.
@export_flags_2d_physics
var trajectory_collision_mask: int = 3

@export_range(0.0, 1.5, 0.05)
var trajectory_bounce_strength: float = 0.8

@export_range(0, 10, 1)
var trajectory_max_bounces: int = 3

@export_range(0.1, 5.0, 0.1)
var trajectory_collision_offset: float = 1.0


# BARREL POSITIONS

@export var centre_barrel_position: Vector2 = (
	Vector2(0.0, 13.0)
)

@export var negative_turn_position: Vector2 = (
	Vector2(10.0, 10.0)
)

@export var positive_turn_position: Vector2 = (
	Vector2(-10.0, 10.0)
)


# RECOIL

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


# TURN SWAP

@export_range(0.1, 5.0, 0.05)
var turn_swap_pause_duration: float = 2.0


# AI THINKING

@export_range(0.1, 5.0, 0.05)
var ai_thinking_duration: float = 1.0

@export_range(0.05, 3.0, 0.05)
var ai_thinking_settle_duration: float = 0.4

@export_range(0.5, 20.0, 0.5)
var ai_thinking_oscillation_speed: float = 2.5

@export_range(0.0, 1.0, 0.05)
var ai_thinking_oscillation_extent: float = 0.6


# BARREL FADE

@export_range(0.05, 3.0, 0.05)
var barrel_fade_out_duration: float = 0.3

@export_range(0.05, 3.0, 0.05)
var barrel_fade_in_duration: float = 0.3


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


# INPUT LOCK

# When true, the cannon cannot aim, calculate
# trajectories, think for the AI or fire.
var cannon_locked: bool = false


# SHOT DATA

var last_shoot_direction: Vector2 = Vector2.DOWN

# TRAJECTORY DATA

var trajectory_points: Array[Vector2] = []
var trajectory_visible: bool = true

var trajectory_dot_colour: Color = (
	player_trajectory_dot_colour
)


# TWEEN DATA

var recoil_tween: Tween
var barrel_fade_tween: Tween


func _ready() -> void:
	rotation = 0.0

	barrel.rotation = 0.0
	barrel.position = centre_barrel_position

	flash_cooldown.timeout.connect(
		_on_flash_cooldown_timeout
	)

	queue_redraw()


func lock_cannon() -> void:
	cannon_locked = true

	# Immediately remove the aiming guide.
	trajectory_visible = false
	trajectory_points.clear()

	queue_redraw()


func unlock_cannon() -> void:
	cannon_locked = false


func is_cannon_locked() -> bool:
	return cannon_locked


func _draw() -> void:
	if not trajectory_visible:
		return

	if trajectory_points.size() < 2:
		return

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

		distance_until_next_dot = (
			distance_along_segment
				- segment_length
		)


func aim_at(
	target_position: Vector2,
	show_trajectory: bool = true,
	is_player_turn: bool = true
) -> void:
	if cannon_locked:
		return

	var target_angle: float = (
		get_clamped_aim_angle(
			target_position
		)
	)

	_apply_aim_angle(
		target_angle,
		show_trajectory,
		is_player_turn
	)


func get_clamped_aim_angle(
	target_position: Vector2
) -> float:
	var target_direction: Vector2 = (
		barrel.global_position.direction_to(
			target_position
		)
	)

	var target_angle: float = (
		Vector2.DOWN.angle_to(
			target_direction
		)
	)

	return clampf(
		target_angle,
		deg_to_rad(minimum_turn_angle),
		deg_to_rad(maximum_turn_angle)
	)


func _apply_aim_angle(
	angle: float,
	show_trajectory: bool,
	is_player_turn: bool
) -> void:
	if cannon_locked:
		return

	trajectory_dot_colour = (
		player_trajectory_dot_colour
		if is_player_turn
		else enemy_trajectory_dot_colour
	)

	barrel.rotation = angle

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
	return Vector2.DOWN.rotated(
		barrel.global_rotation
	).normalized()


func update_trajectory_points() -> void:
	if cannon_locked:
		trajectory_points.clear()
		trajectory_visible = false
		queue_redraw()
		return

	trajectory_points.clear()

	var start_position: Vector2 = (
		firing_point.global_position
			+ shoot_offset
	)

	var initial_velocity: Vector2 = (
		get_shoot_direction()
			* shoot_strength
			/ ball_mass
	)

	var default_gravity: float = float(
		ProjectSettings.get_setting(
			"physics/2d/default_gravity",
			980.0
		)
	)

	var gravity_direction: Vector2 = (
		ProjectSettings.get_setting(
			"physics/2d/default_gravity_vector",
			Vector2.DOWN
		)
	)

	var gravity_acceleration: Vector2 = (
		gravity_direction.normalized()
			* default_gravity
			* ball_gravity_scale
	)

	var safe_point_count: int = maxi(
		trajectory_point_count,
		2
	)

	var step_duration: float = (
		trajectory_duration
			/ float(safe_point_count - 1)
	)

	var current_position: Vector2 = (
		start_position
	)

	var current_velocity: Vector2 = (
		initial_velocity
	)

	var travelled_distance: float = 0.0
	var bounce_count: int = 0

	var space_state: PhysicsDirectSpaceState2D = (
		get_world_2d().direct_space_state
	)

	trajectory_points.append(
		to_local(current_position)
	)

	for _index: int in range(
		1,
		safe_point_count
	):
		current_velocity += (
			gravity_acceleration
				* step_duration
		)

		var predicted_position: Vector2 = (
			current_position
				+ current_velocity
					* step_duration
		)

		var ray_query := (
			PhysicsRayQueryParameters2D.create(
				current_position,
				predicted_position,
				trajectory_collision_mask
			)
		)

		ray_query.collide_with_bodies = true
		ray_query.collide_with_areas = false

		var collision: Dictionary = (
			space_state.intersect_ray(
				ray_query
			)
		)

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
			segment_end = collision.get(
				"position",
				predicted_position
			)

			collision_normal = collision.get(
				"normal",
				Vector2.ZERO
			)

		var segment_length: float = (
			current_position.distance_to(
				segment_end
			)
		)

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
			if (
				collision_normal == Vector2.ZERO
				or bounce_count
					>= trajectory_max_bounces
			):
				break

			current_velocity = (
				current_velocity.bounce(
					collision_normal
				)
				* trajectory_bounce_strength
			)

			current_position = (
				segment_end
					+ collision_normal
						* trajectory_collision_offset
			)

			bounce_count += 1

		else:
			current_position = (
				predicted_position
			)

	queue_redraw()


func play_turn_swap() -> void:
	await get_tree().create_timer(
		turn_swap_pause_duration
	).timeout

	fade_barrel_in()


func think_and_aim_at(
	target_position: Vector2
) -> void:
	if cannon_locked:
		return

	var target_angle: float = (
		get_clamped_aim_angle(
			target_position
		)
	)

	var min_angle: float = deg_to_rad(
		minimum_turn_angle
	)

	var max_angle: float = deg_to_rad(
		maximum_turn_angle
	)

	var oscillation_centre: float = (
		(min_angle + max_angle) / 2.0
	)

	var oscillation_extent: float = (
		(max_angle - min_angle)
			/ 2.0
			* ai_thinking_oscillation_extent
	)

	var elapsed_time: float = 0.0

	while elapsed_time < ai_thinking_duration:
		if cannon_locked:
			return

		var frame_delta: float = (
			get_process_delta_time()
		)

		elapsed_time += frame_delta

		var oscillation_angle: float = (
			oscillation_centre
				+ sin(
					elapsed_time
						* ai_thinking_oscillation_speed
				)
				* oscillation_extent
		)

		_apply_aim_angle(
			oscillation_angle,
			true,
			false
		)

		await get_tree().process_frame

	var start_angle: float = barrel.rotation

	var safe_settle_duration: float = maxf(
		ai_thinking_settle_duration,
		0.001
	)

	var settle_elapsed: float = 0.0

	while settle_elapsed < safe_settle_duration:
		if cannon_locked:
			return

		var frame_delta: float = (
			get_process_delta_time()
		)

		settle_elapsed += frame_delta

		var lerp_amount: float = clampf(
			settle_elapsed / safe_settle_duration,
			0.0,
			1.0
		)

		var eased_amount: float = (
			lerp_amount
				* lerp_amount
				* (3.0 - 2.0 * lerp_amount)
		)

		var current_angle: float = lerp(
			start_angle,
			target_angle,
			eased_amount
		)

		_apply_aim_angle(
			current_angle,
			true,
			false
		)

		await get_tree().process_frame

	if cannon_locked:
		return

	_apply_aim_angle(
		target_angle,
		true,
		false
	)


func fire() -> RigidBody2D:
	if cannon_locked:
		return null

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
	if cannon_locked:
		return null

	return _spawn_ball(
		spawn_position + shoot_offset,
		direction
	)


func _spawn_ball(
	spawn_position: Vector2,
	direction: Vector2
) -> RigidBody2D:
	if cannon_locked:
		return null

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
	var current_alpha: float = (
		barrel.modulate.a
	)

	barrel.modulate = Color(
		2.0,
		2.0,
		2.0,
		current_alpha
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

	_fade_barrel_out_after_recoil()


func play_recoil() -> void:
	if recoil_tween != null:
		if recoil_tween.is_valid():
			recoil_tween.kill()

	var resting_position: Vector2 = (
		barrel.position
	)

	var recoil_position: Vector2 = (
		resting_position.move_toward(
			Vector2.ZERO,
			recoil_distance
		)
	)

	recoil_tween = create_tween()

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


func _fade_barrel_out_after_recoil() -> void:
	if (
		recoil_tween != null
		and recoil_tween.is_valid()
	):
		await recoil_tween.finished

	fade_barrel_out()


func fade_barrel_out() -> void:
	if barrel_fade_tween != null:
		if barrel_fade_tween.is_valid():
			barrel_fade_tween.kill()

		barrel_fade_tween = null

	barrel_fade_tween = create_tween()
	barrel_fade_tween.set_parallel(
		true
	)

	barrel_fade_tween.tween_property(
		barrel,
		"modulate:a",
		0.0,
		barrel_fade_out_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)

	barrel_fade_tween.tween_property(
		eye_pupil,
		"modulate:a",
		0.0,
		barrel_fade_out_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_IN
	)


func fade_barrel_in() -> void:
	if barrel_fade_tween != null:
		if barrel_fade_tween.is_valid():
			barrel_fade_tween.kill()

		barrel_fade_tween = null

	barrel_fade_tween = create_tween()
	barrel_fade_tween.set_parallel(
		true
	)

	barrel_fade_tween.tween_property(
		barrel,
		"modulate:a",
		1.0,
		barrel_fade_in_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)

	barrel_fade_tween.tween_property(
		eye_pupil,
		"modulate:a",
		1.0,
		barrel_fade_in_duration
	).set_trans(
		Tween.TRANS_SINE
	).set_ease(
		Tween.EASE_OUT
	)


func _on_flash_cooldown_timeout() -> void:
	var current_alpha: float = (
		barrel.modulate.a
	)

	barrel.modulate = Color(
		1.0,
		1.0,
		1.0,
		current_alpha
	)

	animation_player.play(
		"RESET"
	)
