extends Control


@export_group("Scenes")

# SceneManager key for the gameplay scene.
@export var first_level_scene: String = "main"

# SceneManager key for the main menu.
@export var main_menu_scene: String = "main_menu"


@export_group("Scene Transitions")

@export var retry_loading_duration: float = 1.0


@export_group("Retry Button Reveal")

@export var dialogue_to_retry_delay: float = 3.0
@export var retry_fade_in_tween_duration: float = 0.5


@export_group("Retry Button Hover")

@export var retry_hover_sound: AudioStream

@export var retry_hover_scale: Vector2 = Vector2(
	1.05,
	1.05
)

@export var retry_normal_scale: Vector2 = Vector2.ONE
@export var retry_hover_duration: float = 0.12
@export var retry_unhover_duration: float = 0.16


@onready var dialogue_box: DialogueBox = (
	$DialogueBox
)

@onready var retry_button: Button = (
	$MarginContainer/VBoxContainer/RetryButton
)


var retry_button_tween: Tween


func _ready() -> void:
	retry_button.modulate.a = 0.0
	retry_button.disabled = true
	retry_button.scale = retry_normal_scale

	dialogue_box.display_dialogue(
		"Want to try that again?\nYou know. In a different universe?"
	)

	# Wait for the container to calculate the
	# button's final size.
	await get_tree().process_frame

	retry_button.pivot_offset = (
		retry_button.size / 2.0
	)

	if not retry_button.mouse_entered.is_connected(
		_on_retry_button_mouse_entered
	):
		retry_button.mouse_entered.connect(
			_on_retry_button_mouse_entered
		)

	if not retry_button.mouse_exited.is_connected(
		_on_retry_button_mouse_exited
	):
		retry_button.mouse_exited.connect(
			_on_retry_button_mouse_exited
		)

	await get_tree().create_timer(
		dialogue_to_retry_delay
	).timeout

	var fade_tween: Tween = create_tween()

	fade_tween.tween_property(
		retry_button,
		"modulate:a",
		1.0,
		retry_fade_in_tween_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await fade_tween.finished

	retry_button.disabled = false


func _exit_tree() -> void:
	if (
		retry_button_tween != null
		and retry_button_tween.is_valid()
	):
		retry_button_tween.kill()


func _on_retry_button_mouse_entered() -> void:
	if retry_button.disabled:
		return

	if retry_hover_sound != null:
		SfxPlayer.play(
			retry_hover_sound
		)

	_animate_retry_button(
		retry_hover_scale,
		retry_hover_duration
	)


func _on_retry_button_mouse_exited() -> void:
	_animate_retry_button(
		retry_normal_scale,
		retry_unhover_duration
	)


func _animate_retry_button(
	target_scale: Vector2,
	duration: float
) -> void:
	if (
		retry_button_tween != null
		and retry_button_tween.is_valid()
	):
		retry_button_tween.kill()

	retry_button_tween = create_tween()

	retry_button_tween.tween_property(
		retry_button,
		"scale",
		target_scale,
		duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func _on_retry_button_pressed() -> void:
	# LevelManager and GameData are autoloads.
	# Reloading the scene preserves the latest
	# level, remaining balls, and maximum balls.
	GameData.set_current_level(
		first_level_scene
	)

	# Reload the gameplay scene from a fresh instance.
	SceneManager.go(
		first_level_scene,
		retry_loading_duration,
		true
	)
