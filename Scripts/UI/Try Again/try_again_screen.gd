extends Control

@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var retry_button: Button = $MarginContainer/VBoxContainer/RetryButton

@export var dialogue_to_retry_delay : float
@export var retry_fade_in_tween_duration : float

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

func _ready() -> void:
	dialogue_box.display_dialogue("Want to try that again?")
	await get_tree().create_timer(3).timeout
	retry_button.modulate 
	var tween: Tween = create_tween()
	tween.tween_property(retry_button, "modulate:a", 1, retry_fade_in_tween_duration)

func _on_retry_button_pressed() -> void:
	# Return to level 1.
	LevelManager.set_level(1)

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
