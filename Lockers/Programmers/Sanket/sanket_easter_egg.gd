extends Node2D

# Animation and label used by the intro / fallback scene.
# get_node_or_null() keeps the scene from exploding if one of these nodes is missing.
@onready var anim: AnimationPlayer = get_node_or_null("anim") as AnimationPlayer
@onready var label: Label = get_node_or_null("Label") as Label

@export_group("Scene")
# SceneManager key to go to after the animation, or when skipping.
@export var target_scene_key: String = "main_menu"

# Transition duration used by SceneManager.
@export var scene_transition_duration: float = 1.0

@export_group("Timing")
# Extra waiting time after the animation finishes.
@export var delay_after_animation: float = 2.0

@export_group("Input")
# Template input action used to skip this scene.
# Do not hardcode keys here. "pause" can be rebound and can also work on controller.
@export var skip_action: String = "pause"

@export_group("Label Fade")
# How long the label waits before fading out.
@export var label_fade_delay: float = 7.5

# How long the label fade takes.
@export var label_fade_duration: float = 1.0

# Prevents the scene transition from being triggered twice.
var has_started_leaving: bool = false

# Stored so we can kill the tween if the player skips.
var label_fade_tween: Tween = null


func _ready() -> void:
	# When the animation finishes, leave after the optional delay.
	pass


func _unhandled_input(event: InputEvent) -> void:
	if has_started_leaving:
		return

	if not event.is_action_pressed(skip_action):
		return

	# Keyboard keys can send repeated "echo" events when held down. This is just built into godot.
	# Ignore those so holding pause does not trigger skip multiple times.
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.echo:
			return
	# Stop the skip input from doing anything else.
	get_viewport().set_input_as_handled()
	go_to_target_scene()

# Leaves this scene and goes to the target scene.
func go_to_target_scene() -> void:
	if has_started_leaving:
		return

	has_started_leaving = true

	SceneManager.go(target_scene_key, scene_transition_duration)
