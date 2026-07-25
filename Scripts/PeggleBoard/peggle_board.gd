extends Node2D


enum Turn {
	PLAYER,
	AI
}


const FULL_BAR_FRACTION: float = 0.75

@export var STARTING_BALL_COUNT: int = 20

const WIN_SCENE_KEY: String = "win_screen"
const LOSS_SCENE_KEY: String = "loss_screen"
const TRY_AGAIN_SCENE_KEY: String = "try_again_screen"
const END_SCREEN_TRANSITION_DURATION: float = 0.2


# COLLISION INFORMATION
# Layer 1: Walls
# Layer 2: Pegs
# Layer 3: Ball
# Layer 4: Bin


# PEG LEVELS
# Assign PegsLevel1 through PegsLevel5 in order.

@export var peg_levels: Array[Node2D] = []


# AUDIO
@export_group("Audio")

# Emotions Int
# 1. Happy
# 2. Sad/Dejected
# 3. Flirty - ADD THIS PLEASE!!
# 4. Angry
@export var peg_hit_sfx: AudioStream
@export var cannon_fire_sfx: AudioStream
@export var sfx_max_scale: float
@export var bin_emotion_sfx: Array[AudioStream]

# CANNON NODES

@onready var peggle_ball_shooter: Node2D = (
	$PeggleBallShooter
)


# BALL REMOVAL NODES

@onready var endzone: Area2D = $Endzone
@onready var ball_bin: PeggleBallBin = %Bin
@onready var bins: Node2D = $Bins


# INTERFACE NODES

@onready var player_progress_bar: ProgressBar = (
	$ProgressBar
)

@onready var ai_progress_bar: ProgressBar = (
	$ProgressBar2
)
@onready var ball_bar: ProgressBar = $BallBar
@onready var counting_label: Label = $CountingLabel

@onready var bounce_once: StaticBody2D = $BounceOnce

# SHOOTING
@export_group("Shooting") # to break out of audio group
@export var shoot_offset: Vector2 = Vector2.ZERO
@export var shoot_strength: float = 100.0
@export_range(0, 180, 1) var left_turn_limit: int = 165
@export_range(0, 180, 1) var right_turn_limit: int = 15


@export_group("") # to break out of group

# AI

@export var ai_aim_time: float = 0.75


# PROGRESS BARS

@export var progress_bar_duration: float = 0.75


# ROUND STATE

var current_turn: int = Turn.PLAYER
var ball_in_play: bool = false
var resolving_ball: bool = false
var game_ended: bool = false


# PEG DATA

var active_peg_level: Node2D
var all_pegs: Array[Node] = []
var total_peg_count: int = 0
var peg_hit_count: int = 0

var pegs_hit: int = 0
var peg_hit_volume: float # decibels

var progress_tween: Tween


# POWER-UPS

var is_ghost_ball: bool = false
var is_split_ball: bool = false
var is_bounce_once: bool = false
var is_ai_ball_smol = 0

# SPAWNED BALLS
var new_ball: RigidBody2D
var split_ball: RigidBody2D


func _ready() -> void:
	endzone.body_entered.connect(
		destroy_ball
	)
	endzone.body_entered.connect(
		missed_bin
	)
	GameData.ball_entered_bin.connect(
		destroy_ball
	)
	EventBus.peg_hit_sound_update.connect(play_peg_hit_sound)

	for child: Node in bins.get_children():
		if child.has_signal("ball_caught"):
			child.ball_caught.connect(
				catch_ball
			)

	setup_ball_counter()

	show_peg_level(
		LevelManager.level
	)

	reset_current_round()


func _process(_delta: float) -> void:
	if game_ended:
		return

	if resolving_ball:
		return

	if (
		current_turn == Turn.PLAYER
		and not ball_in_play
	):
		# Show the trajectory while the
		# player aims with the mouse.
		cannon.aim_at(
			get_global_mouse_position(),
			true
		)


func _input(event: InputEvent) -> void:
	if game_ended:
		return

	if resolving_ball:
		return

	if current_turn != Turn.PLAYER:
		return

	if ball_in_play:
		return

	if event.is_action_pressed(
		"action_primary"
	):
		if not DialogueManager._dialogue_box_displayed:
			fire_ball(
				get_global_mouse_position()
			)


func setup_ball_counter() -> void:
	GameData.ensure_ball_counter(
		STARTING_BALL_COUNT
	)

	update_ball_counter()


func use_ball() -> void:
	GameData.use_ball()

	update_ball_counter()


func refund_ball() -> void:
	GameData.refund_ball()

	update_ball_counter()


func update_ball_counter() -> void:
	ball_bar.min_value = 0.0

	ball_bar.max_value = float(
		GameData.maximum_ball_count
	)

	ball_bar.value = float(
		GameData.balls_remaining
	)

	counting_label.text = str(
		GameData.balls_remaining
	)


func show_peg_level(
	level_number: int
) -> void:
	if peg_levels.is_empty():
		push_error(
			"No peg level nodes were assigned."
		)
		return

	var level_index: int = clampi(
		level_number - 1,
		0,
		peg_levels.size() - 1
	)

	for index: int in range(
		peg_levels.size()
	):
		var peg_level: Node2D = (
			peg_levels[index]
		)

		if peg_level == null:
			continue

		var is_active: bool = (
			index == level_index
		)

		peg_level.visible = is_active

		if is_active:
			peg_level.process_mode = (
				Node.PROCESS_MODE_INHERIT
			)

		else:
			peg_level.process_mode = (
				Node.PROCESS_MODE_DISABLED
			)

		_set_level_collisions_enabled(
			peg_level,
			is_active
		)

	active_peg_level = (
		peg_levels[level_index]
	)

	refresh_pegs()

func play_peg_hit_sound() -> void:
	if peg_hit_sfx != null:
		var sfx_pitch_scale = 1 + pegs_hit*0.1
		if sfx_pitch_scale > sfx_max_scale:
			sfx_pitch_scale = sfx_max_scale
		
		SfxPlayer.play(
			peg_hit_sfx,
			false,
			false,
			0.0,
			false,
			peg_hit_volume,
			0.0,
			false,
			null,
			sfx_pitch_scale
		)

	pegs_hit += 1

func _set_level_collisions_enabled(
	node: Node,
	enabled: bool
) -> void:
	for child: Node in node.get_children():
		if child is CollisionShape2D:
			child.set_deferred(
				"disabled",
				not enabled
			)

		elif child is CollisionPolygon2D:
			child.set_deferred(
				"disabled",
				not enabled
			)

		_set_level_collisions_enabled(
			child,
			enabled
		)


func refresh_pegs() -> void:
	all_pegs.clear()
	total_peg_count = 0

	if active_peg_level == null:
		return

	_collect_pegs(
		active_peg_level
	)

	total_peg_count = all_pegs.size()

	if all_pegs.is_empty():
		push_warning(
			"The active peg level contains no pegs."
		)


func _collect_pegs(node: Node) -> void:
	for child: Node in node.get_children():
		if child.is_in_group("pegs"):
			all_pegs.append(
				child
			)

		_collect_pegs(
			child
		)


func reset_current_round() -> void:
	if progress_tween != null:
		progress_tween.kill()
		progress_tween = null

	refresh_pegs()

	for peg: Node in all_pegs:
		if peg.has_method("reset_peg"):
			peg.call(
				"reset_peg"
			)

	player_progress_bar.min_value = 0.0
	player_progress_bar.max_value = 100.0
	player_progress_bar.value = 0.0

	ai_progress_bar.min_value = 0.0
	ai_progress_bar.max_value = 100.0
	ai_progress_bar.value = 0.0

	current_turn = Turn.PLAYER
	ball_in_play = false
	resolving_ball = false


func get_progress_values() -> Vector2:
	refresh_pegs()

	var player_peg_count: int = 0
	var ai_peg_count: int = 0

	for peg: Node in all_pegs:
		if not is_instance_valid(peg):
			continue

		if not peg.has_method(
			"get_claimed_turn"
		):
			continue

		var claimed_turn: int = int(
			peg.call(
				"get_claimed_turn"
			)
		)

		if claimed_turn == Turn.PLAYER:
			player_peg_count += 1

		elif claimed_turn == Turn.AI:
			ai_peg_count += 1

	return Vector2(
		get_progress_percentage(
			player_peg_count
		),
		get_progress_percentage(
			ai_peg_count
		)
	)


func animate_progress_bars() -> void:
	if game_ended:
		return

	var progress_values: Vector2 = (
		get_progress_values()
	)

	if progress_tween != null:
		progress_tween.kill()

	progress_tween = create_tween()
	progress_tween.set_parallel(
		true
	)

	progress_tween.tween_property(
		player_progress_bar,
		"value",
		progress_values.x,
		progress_bar_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	progress_tween.tween_property(
		ai_progress_bar,
		"value",
		progress_values.y,
		progress_bar_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await progress_tween.finished

	check_for_winner()


func get_progress_percentage(
	claimed_peg_count: int
) -> float:
	if total_peg_count <= 0:
		return 0.0

	var pegs_required_for_full_bar: int = maxi(
		int(
			ceil(
				float(total_peg_count)
					* FULL_BAR_FRACTION
			)
		),
		1
	)

	return clampf(
		float(claimed_peg_count)
			/ float(
				pegs_required_for_full_bar
			)
			* 100.0,
		0.0,
		100.0
	)


func check_for_winner() -> void:
	if (
		player_progress_bar.value
		>= player_progress_bar.max_value
	):
		if (
			LevelManager.level
			< LevelManager.MAX_LEVEL
		):
			advance_to_next_peg_level()

		else:
			end_game(
				WIN_SCENE_KEY
			)

	elif (
		ai_progress_bar.value
		>= ai_progress_bar.max_value
	):
		if GameData.balls_remaining <= 0:
			end_game(
				LOSS_SCENE_KEY
			)

		else:
			end_game(
				TRY_AGAIN_SCENE_KEY
			)


func advance_to_next_peg_level() -> void:
	if game_ended:
		return

	game_ended = true

	await fade_out_board()

	LevelManager.set_level(
		LevelManager.level + 1
	)

	show_peg_level(
		LevelManager.level
	)

	reset_current_round()

	game_ended = false

	EventBus.dialogue_level_triggered.emit(
		LevelManager.level
	)


func restart_current_peg_level() -> void:
	if game_ended:
		return

	game_ended = true

	await fade_out_board()

	show_peg_level(
		LevelManager.level
	)

	reset_current_round()

	game_ended = false

	EventBus.dialogue_level_triggered.emit(
		LevelManager.level
	)


func fade_out_board() -> void:
	var current_level_scene: Node = (
		get_tree().current_scene
	)

	if current_level_scene.has_method(
		"fade_out_peggle_board"
	):
		await current_level_scene.call(
			"fade_out_peggle_board"
		)


func end_game(scene_key: String) -> void:
	if game_ended:
		return

	game_ended = true

	await fade_out_board()

	if scene_key == WIN_SCENE_KEY:
		SceneManager.go(
			WIN_SCENE_KEY,
			END_SCREEN_TRANSITION_DURATION,
			true
		)

	else:
		SceneManager.go(
			scene_key,
			END_SCREEN_TRANSITION_DURATION
		)


func fire_ball(
	target_position: Vector2
) -> void:
	if game_ended:
		return

	if resolving_ball:
		return

	if GameData.balls_remaining <= 0:
		end_game(
			LOSS_SCENE_KEY
		)
		return

	var fired_ball: RigidBody2D = (
		cannon.fire_at(
			target_position
		)
	)

	if fired_ball == null:
		return

	fired_ball.body_entered.connect(
		func(body: Node) -> void:
			_on_ball_body_entered(
				fired_ball,
				body
			)
	)
	
	if is_ghost_ball:
		is_ghost_ball = false

		if fired_ball.has_method(
			"ghost_ball"
		):
			fired_ball.call(
				"ghost_ball"
			)
		if is_ai_ball_smol == 2:
			is_ai_ball_smol -= 1

		elif is_ai_ball_smol == 1:
			is_ai_ball_smol -= 1
			new_ball.get_node("Sprite2D").scale = Vector2(0.1, 0.1)
			new_ball.get_node("CollisionShape2D").shape.radius *= 0.5

		else:
			new_ball.get_node("Sprite2D").scale = Vector2(0.2,0.2)
			new_ball.get_node("CollisionShape2D").shape.radius =3

	if is_bounce_once:
		is_bounce_once=false
		bounce_once.bounce_once()

	configure_ball(
		fired_ball,
		current_turn
	)

	ball_in_play = true

	use_ball()


func configure_ball(
	fired_ball: RigidBody2D,
	turn_owner: int
) -> void:
	fired_ball.set_meta(
		"is_peggle_ball",
		true
	)

	fired_ball.set_meta(
		"ball_resolved",
		false
	)

	fired_ball.set_meta(
		"ball_owner",
		get_ball_owner(
			turn_owner
		)
	)

	fired_ball.set_meta(
		"turn_owner",
		turn_owner
	)


func get_ball_owner(
	turn_owner: int
) -> String:
	if turn_owner == Turn.PLAYER:
		return "player"

	return "ai"


func catch_ball(
	body: Node2D,
	bin_emotion: int
) -> void:
	resolve_ball(
		body,
		true
	)
	
	# SFX
	SfxPlayer.play(bin_emotion_sfx[bin_emotion])

func destroy_ball(
	body: Node2D
) -> void:
	resolve_ball(
		body,
		false
	)

func missed_bin(_body: Node2D) -> void:
	# ball was destroyed by endzone instead of bin
	GameData.current_emotion = 4

func resolve_ball(
	body: Node2D,
	should_refund: bool
) -> void:
	if (
		body.get_meta(
			"is_peggle_ball",
			false
		) != true
	):
		return

	if (
		body.get_meta(
			"ball_resolved",
			false
		) == true
	):
		return

	body.set_meta(
		"ball_resolved",
		true
	)

	var finished_turn: int = int(
		body.get_meta(
			"turn_owner",
			current_turn
		)
	)
	
	pegs_hit = 0 # reset peg sound
	body.queue_free()

	ball_in_play = false
	resolving_ball = true

	if should_refund:
		refund_ball()

	else:
		var percentage_left: float = 0.0

		if GameData.maximum_ball_count > 0:
			percentage_left = (
				float(
					GameData.balls_remaining
				)
				/ float(
					GameData.maximum_ball_count
				)
				* 100.0
			)

		EventBus.balls_left_percentage_changed.emit(
			percentage_left
		)

	finish_ball_resolution(
		finished_turn
	)


func finish_ball_resolution(
	finished_turn: int
) -> void:
	await get_tree().process_frame

	await animate_progress_bars()

	if game_ended:
		resolving_ball = false
		return

	if GameData.balls_remaining <= 0:
		resolving_ball = false

		end_game(
			LOSS_SCENE_KEY
		)
		return

	if finished_turn == Turn.PLAYER:
		current_turn = Turn.AI
		resolving_ball = false

		start_ai_turn()

	else:
		current_turn = Turn.PLAYER
		EventBus.dialogue_mood_hide.emit()
		resolving_ball = false


func start_ai_turn() -> void:
	if game_ended:
		return

	if resolving_ball:
		return

	refresh_pegs()

	if all_pegs.is_empty():
		current_turn = Turn.PLAYER
		return

	var target_peg := (
		all_pegs.pick_random() as Node2D
	)

	if target_peg == null:
		current_turn = Turn.PLAYER
		return

	# Aim without showing the trajectory line.
	cannon.aim_at(
		target_peg.global_position,
		false
	)

	await get_tree().create_timer(
		ai_aim_time
	).timeout

	if game_ended:
		return

	if (
		current_turn != Turn.AI
		or ball_in_play
	):
		return

	if not is_instance_valid(target_peg):
		start_ai_turn()
		return

	fire_ball(
		target_peg.global_position
	)


func _on_ball_body_entered(
	current_ball: RigidBody2D,
	_body: Node
) -> void:
	if not is_split_ball:
		return

	is_split_ball = false

	var turn_owner: int = int(
		current_ball.get_meta(
			"turn_owner",
			current_turn
		)
	)

	var spawned_split_ball: RigidBody2D = (
		cannon.fire_extra_ball(
			current_ball.global_position,
			cannon.last_shoot_direction
		)
	)

	if spawned_split_ball == null:
		return

	configure_ball(
		spawned_split_ball,
		turn_owner
	)
