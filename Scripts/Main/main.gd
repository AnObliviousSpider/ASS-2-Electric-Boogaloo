extends Node


@export_group("Scenes")

@export var current_level_scene: String = "main"


@export_group("Game")

@export var starting_ball_count: int = 50


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


func _enter_tree() -> void:
	# Create the ball counter only if no game exists.
	GameData.ensure_ball_counter(
		starting_ball_count
	)


func _ready() -> void:
	# Save the current scene.
	GameData.set_current_level(
		current_level_scene
	)

	# Reveal the board only after the complete
	# level dialogue sequence has finished.
	if not DialogueManager.level_dialogue_closed.is_connected(
		fade_in_peggle_board
	):
		DialogueManager.level_dialogue_closed.connect(
			fade_in_peggle_board
		)

	# Begin with the board hidden.
	peggle_board.modulate.a = 0.0
	peggle_board.hide()

	# Do not trigger dialogue here.
	#
	# Level 1 dialogue is started by the character
	# introduction script.
	#
	# Later level dialogue is started by PeggleBoard.


func _unhandled_input(
	event: InputEvent
) -> void:
	# The Inspector toggle must be enabled.
	if not enable_debug_win:
		return

	# The debug shortcut only works when the game
	# is being run through the Godot editor.
	#
	# It cannot work in exported builds.
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


func fade_in_peggle_board() -> void:
	# Stop the previous fade.
	if board_fade_tween != null:
		board_fade_tween.kill()

	peggle_board.show()
	peggle_board.modulate.a = 0.0

	# Fade the board in.
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
	# Stop the previous fade.
	if board_fade_tween != null:
		board_fade_tween.kill()

	peggle_board.show()

	# Fade the board out.
	board_fade_tween = create_tween()

	board_fade_tween.tween_property(
		peggle_board,
		"modulate:a",
		0.0,
		board_fade_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await board_fade_tween.finished

	peggle_board.hide()
