extends Control

# Win screen. (yes this is mostly the same as the loss screen :P)
# Lets the player replay the last level or return to the main menu.

@export_group("Scenes")
# Used if GameData does not know which level was played.
@export var fallback_level_scene: String = "main"

# SceneManager key for the main menu.
@export var main_menu_scene: String = "main_menu"

@export_group("Scene Transitions")
# Loading duration when replaying the level.
@export var retry_loading_duration: float = 2.0

# Loading duration when returning to the main menu.
@export var menu_loading_duration: float = 2.0

# CHILD NODES
@onready var main_margin: MarginContainer = $MainMargin
@onready var color_rect_vignette: ColorRect = $ColorRectVignette
@onready var animation_player_vignette: AnimationPlayer = $AnimationPlayerVignette

func _ready() -> void:
	init_components()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action_primary"):
		vignette_transition()

## Make all components invisible + other setup features for the transition
func init_components() -> void:
	main_margin.visible = false
	color_rect_vignette.visible = false

func vignette_transition() ->void:
	color_rect_vignette.visible = true
	animation_player_vignette.speed_scale = 0.8
	animation_player_vignette.play("vignette_transition")
	await animation_player_vignette.animation_finished
	main_margin.visible = true

# Replay the level the player just won.
func _on_retry_button_pressed() -> void:
	var level_scene: String = get_retry_level_scene()

	# The true at the end forces the scene to reload,
	# even if the player is already technically coming from that scene.
	SceneManager.go(level_scene, retry_loading_duration, true)


# Go back to the main menu.
func _on_main_menu_button_pressed() -> void:
	LevelManager.level = 1 # set back to level 1 on loading main menu
	SceneManager.go(main_menu_scene, menu_loading_duration)


# Gets the scene the replay button should load.
func get_retry_level_scene() -> String:
	if GameData.has_method("get_current_level"):
		var current_level_scene: String = GameData.get_current_level()

		# strip_edges() makes sure spaces like "   " do not count.
		if current_level_scene.strip_edges() != "":
			return current_level_scene

	# If GameData has nothing, use the fallback from the Inspector.
	return fallback_level_scene
