extends Node


const MUSIC_STATE_MAIN: StringName = &"main"
const MUSIC_STATE_EARLY_LOW: StringName = &"early_low"
const MUSIC_STATE_LEVEL_3_NORMAL: StringName = &"level_3_normal"
const MUSIC_STATE_LEVEL_3_LOW: StringName = &"level_3_low"
const MUSIC_STATE_LEVEL_4: StringName = &"level_4"
const MUSIC_STATE_LEVEL_4_LOW: StringName = &"level_4_low"


@export_group("Scenes")

@export var current_level_scene: String = "main"


@export_group("Game")

@export var starting_ball_count: int = 50


@export_group("Level Music")

# Used during levels 1 and 2 below 50%.
@export var early_levels_low_music: AudioStream

# Used during level 3 at or above 50%.
@export var level_3_normal_music: AudioStream

# Used during level 3 below 50%.
@export var level_3_low_music: AudioStream

# Used during level 4 at or above 50%.
@export var level_4_music: AudioStream

# Used during level 4 below 50%.
@export var level_4_low_music: AudioStream

@export_range(
	0.0,
	1.0,
	0.01
)
var low_ball_threshold: float = 0.5

@export var music_crossfade_duration: float = 1.5


@export_group("Peggle Board Transition")

@export var board_fade_duration: float = 0.5


@export_group("Debug")

# Enable this in the Inspector while testing.
#
# This still will not work in an exported build.
@export var enable_debug_win: bool = false


@onready var peggle_board: Node2D = (
	%PeggleBoard
)


var board_fade_tween: Tween

# SceneMusicManager selects the main track
# when this scene first loads.
var current_music_state: StringName = (
	MUSIC_STATE_MAIN
)


func _enter_tree() -> void:
	GameData.ensure_ball_counter(
		starting_ball_count
	)


func _ready() -> void:
	GameData.set_current_level(
		current_level_scene
	)

	if not DialogueManager.level_dialogue_closed.is_connected(
		_on_level_dialogue_closed
	):
		DialogueManager.level_dialogue_closed.connect(
			_on_level_dialogue_closed
		)

	peggle_board.modulate.a = 0.0
	peggle_board.hide()

	# Give SceneMusicManager time to apply the
	# track assigned to the main scene.
	await get_tree().process_frame

	_update_level_music()


func _process(
	_delta: float
) -> void:
	_update_level_music()


func _unhandled_input(
	event: InputEvent
) -> void:
	if not enable_debug_win:
		return

	if not OS.has_feature(
		"editor"
	):
		return

	if not event.is_action_pressed(
		"debug_win"
	):
		return

	if not peggle_board.has_method(
		"debug_win_current_level"
	):
		push_warning(
			"PeggleBoard does not have "
			+ "debug_win_current_level()."
		)

		return

	peggle_board.call(
		"debug_win_current_level"
	)

	get_viewport().set_input_as_handled()


func _on_level_dialogue_closed() -> void:
	# The final win sequence sets game_ended before
	# opening its post-level dialogue. Do not fade
	# the board back in when that dialogue closes.
	if (
		LevelManager.level
		== LevelManager.MAX_LEVEL
		and bool(
			peggle_board.get(
				"game_ended"
			)
		)
	):
		return

	fade_in_peggle_board()


func _update_level_music() -> void:
	var desired_state: StringName = (
		_get_desired_music_state()
	)

	if desired_state == current_music_state:
		return

	current_music_state = desired_state

	var target_music: AudioStream = (
		_get_music_for_state(
			desired_state
		)
	)

	if target_music == null:
		push_warning(
			"No music assigned for state: %s"
			% desired_state
		)
		return

	if MusicPlayer.is_playing(
		target_music
	):
		return

	MusicPlayer.play(
		target_music,
		true,
		false,
		music_crossfade_duration,
		true
	)


func _get_desired_music_state() -> StringName:
	var current_level: int = (
		LevelManager.level
	)

	var below_threshold: bool = (
		_is_below_ball_threshold()
	)

	match current_level:
		1, 2:
			if below_threshold:
				return MUSIC_STATE_EARLY_LOW

			return MUSIC_STATE_MAIN

		3:
			if below_threshold:
				return MUSIC_STATE_LEVEL_3_LOW

			return MUSIC_STATE_LEVEL_3_NORMAL

		4:
			if below_threshold:
				return MUSIC_STATE_LEVEL_4_LOW

			return MUSIC_STATE_LEVEL_4

		_:
			return MUSIC_STATE_MAIN


func _get_music_for_state(
	music_state: StringName
) -> AudioStream:
	match music_state:
		MUSIC_STATE_MAIN:
			return SceneMusicManager.get_music_for_scene(
				current_level_scene
			)

		MUSIC_STATE_EARLY_LOW:
			return early_levels_low_music

		MUSIC_STATE_LEVEL_3_NORMAL:
			return level_3_normal_music

		MUSIC_STATE_LEVEL_3_LOW:
			return level_3_low_music

		MUSIC_STATE_LEVEL_4:
			return level_4_music

		MUSIC_STATE_LEVEL_4_LOW:
			return level_4_low_music

	return null


func _is_below_ball_threshold() -> bool:
	if GameData.maximum_ball_count <= 0:
		return false

	var remaining_fraction: float = (
		float(
			GameData.balls_remaining
		)
		/ float(
			GameData.maximum_ball_count
		)
	)

	# Exactly 50% remains part of the normal state.
	return remaining_fraction < low_ball_threshold


func fade_in_peggle_board() -> void:
	if board_fade_tween != null:
		board_fade_tween.kill()

	peggle_board.show()
	peggle_board.modulate.a = 0.0

	board_fade_tween = create_tween()

	board_fade_tween.tween_property(
		peggle_board,
		"modulate:a",
		1.0,
		board_fade_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func fade_out_peggle_board() -> void:
	if board_fade_tween != null:
		board_fade_tween.kill()

	peggle_board.show()

	var fade_tween: Tween = create_tween()
	board_fade_tween = fade_tween

	fade_tween.tween_property(
		peggle_board,
		"modulate:a",
		0.0,
		board_fade_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await fade_tween.finished

	# Another transition may have replaced this
	# tween while it was running.
	if board_fade_tween != fade_tween:
		return

	peggle_board.hide()
	board_fade_tween = null
