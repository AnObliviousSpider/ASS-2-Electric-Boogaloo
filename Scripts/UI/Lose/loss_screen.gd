extends Control


@export_group("Scenes")

# SceneManager key for level 1.
@export var first_level_scene: String = "main"

# SceneManager key for the main menu.
@export var main_menu_scene: String = "main_menu"


@export_group("Game")

# Used if GameData does not have a valid maximum.
@export var default_max_ball_count: int = 20


@export_group("Scene Transitions")

@export var retry_loading_duration: float = 1.0
@export var menu_loading_duration: float = 1.0


@export_group("UI Sounds")

@export var click_sound: AudioStream
@export var hover_sound: AudioStream


@export_group("Button Juice")

@export var button_hover_scale: Vector2 = Vector2(
	1.04,
	1.04
)

@export var button_down_scale: Vector2 = Vector2(
	0.97,
	0.97
)

@export var button_up_scale: Vector2 = Vector2(
	1.05,
	1.05
)

@export var button_hover_duration: float = 0.15
@export var button_down_duration: float = 0.06
@export var button_up_duration: float = 0.08

@export var button_move_distance: float = 2.0
@export var button_move_duration: float = 0.08


@onready var retry_button: Button = (
	$MarginContainer/VBoxContainer/RetryButton
)

@onready var main_menu_button: Button = (
	$MarginContainer/VBoxContainer/MainMenuButton
)

@onready var animation_player: AnimationPlayer = (
	$AnimationPlayer
)


var button_tweens: Dictionary[Button, Tween] = {}
var button_start_positions: Dictionary[Button, Vector2] = {}


func _ready() -> void:
	get_tree().paused = false

	# Prevent the buttons from being used while
	# they are being introduced.
	set_buttons_enabled(
		false
	)

	# Wait for the buttons to receive their
	# final size and position.
	await get_tree().process_frame

	_setup_buttons()

	if not animation_player.has_animation(
		&"Die"
	):
		push_warning(
			'AnimationPlayer does not contain an animation named "Die".'
		)

		set_buttons_enabled(
			true
		)
		return

	animation_player.play(
		&"Die"
	)

	# Wait until the buttons have finished
	# modulating into view.
	await animation_player.animation_finished

	set_buttons_enabled(
		true
	)


func _exit_tree() -> void:
	for tween: Tween in button_tweens.values():
		if (
			tween != null
			and tween.is_valid()
		):
			tween.kill()

	button_tweens.clear()
	button_start_positions.clear()


func get_buttons() -> Array[Button]:
	return [
		retry_button,
		main_menu_button,
	]


func set_buttons_enabled(
	enabled: bool
) -> void:
	for button: Button in get_buttons():
		if button == null:
			continue

		button.disabled = not enabled

		if enabled:
			button.mouse_filter = (
				Control.MOUSE_FILTER_STOP
			)
		else:
			button.mouse_filter = (
				Control.MOUSE_FILTER_IGNORE
			)


func _on_retry_button_pressed() -> void:
	# Do not allow activation during the
	# introduction animation.
	if retry_button.disabled:
		return

	# Return to level 1.
	LevelManager.set_level(
		1
	)

	# Use the existing maximum ball count.
	var maximum_balls: int = (
		GameData.maximum_ball_count
	)

	# Use the fallback if no maximum exists.
	if maximum_balls <= 0:
		maximum_balls = default_max_ball_count

	# Begin a new run with full balls.
	GameData.start_new_game(
		maximum_balls
	)

	# Store level 1 as the current level.
	GameData.set_current_level(
		first_level_scene
	)

	# Force level 1 to load from a fresh instance.
	SceneManager.go(
		first_level_scene,
		retry_loading_duration,
		true
	)


func _on_main_menu_button_pressed() -> void:
	# Do not allow activation during the
	# introduction animation.
	if main_menu_button.disabled:
		return

	# Prepare the level number for a new game.
	LevelManager.set_level(
		1
	)

	SceneManager.go(
		main_menu_scene,
		menu_loading_duration
	)


func _setup_buttons() -> void:
	for button: Button in get_buttons():
		if button == null:
			continue

		button.pivot_offset = (
			button.size / 2.0
		)

		button_start_positions[button] = (
			button.position
		)

		var mouse_entered_callable: Callable = (
			_on_button_mouse_entered.bind(
				button
			)
		)

		var mouse_exited_callable: Callable = (
			_on_button_mouse_exited.bind(
				button
			)
		)

		var button_down_callable: Callable = (
			_on_button_down.bind(
				button
			)
		)

		var button_up_callable: Callable = (
			_on_button_up.bind(
				button
			)
		)

		if not button.mouse_entered.is_connected(
			mouse_entered_callable
		):
			button.mouse_entered.connect(
				mouse_entered_callable
			)

		if not button.mouse_exited.is_connected(
			mouse_exited_callable
		):
			button.mouse_exited.connect(
				mouse_exited_callable
			)

		if not button.button_down.is_connected(
			button_down_callable
		):
			button.button_down.connect(
				button_down_callable
			)

		if not button.button_up.is_connected(
			button_up_callable
		):
			button.button_up.connect(
				button_up_callable
			)


func _on_button_mouse_entered(
	button: Button
) -> void:
	if button.disabled:
		return

	play_sfx(
		hover_sound
	)

	_animate_button(
		button,
		button_hover_scale,
		button_hover_duration,
		button_move_distance,
		button_move_duration
	)


func _on_button_mouse_exited(
	button: Button
) -> void:
	if button.disabled:
		return

	_animate_button(
		button,
		Vector2.ONE,
		button_hover_duration,
		0.0,
		button_move_duration
	)


func _on_button_down(
	button: Button
) -> void:
	if button.disabled:
		return

	play_sfx(
		click_sound
	)

	_animate_button(
		button,
		button_down_scale,
		button_down_duration,
		button_move_distance / 2.0,
		button_move_duration
	)


func _on_button_up(
	button: Button
) -> void:
	if button.disabled:
		return

	if button.get_global_rect().has_point(
		get_global_mouse_position()
	):
		_animate_button(
			button,
			button_up_scale,
			button_up_duration,
			button_move_distance,
			button_move_duration
		)
	else:
		_animate_button(
			button,
			Vector2.ONE,
			button_up_duration,
			0.0,
			button_move_duration
		)


func _animate_button(
	button: Button,
	target_scale: Vector2,
	duration: float,
	target_move_distance: float,
	target_move_duration: float
) -> void:
	if button == null:
		return

	if not button_start_positions.has(
		button
	):
		button_start_positions[button] = (
			button.position
		)

	if button_tweens.has(
		button
	):
		var old_tween: Tween = (
			button_tweens[button] as Tween
		)

		if (
			old_tween != null
			and old_tween.is_valid()
		):
			old_tween.kill()

	var starting_position: Vector2 = (
		button_start_positions[button]
	)

	var target_position: Vector2 = (
		starting_position
		+ Vector2(
			target_move_distance,
			0.0
		)
	)

	var tween: Tween = create_tween()

	button_tweens[button] = tween

	tween.set_parallel(
		true
	)

	tween.tween_property(
		button,
		"scale",
		target_scale,
		duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		button,
		"position",
		target_position,
		target_move_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.finished.connect(
		func() -> void:
			if button_tweens.get(
				button
			) == tween:
				button_tweens.erase(
					button
				)
	)


func play_sfx(
	sound: AudioStream
) -> void:
	if sound != null:
		SfxPlayer.play(
			sound
		)
