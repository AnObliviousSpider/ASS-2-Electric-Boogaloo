@tool
class_name PeggleBallBin
extends Area2D


signal ball_caught(
	ball: Node2D,
	bin_emotion: int
)


@export var animated_sprite: AnimatedSprite2D
@export var light_vfx: Sprite2D
@export var emotion_sound: AudioStream

@export var fade_in_duration: float = 1.0
@export var fade_out_duration: float = 0.5


@export_enum(
	"Happy",
	"Dejected",
	"Flirty",
	"Angry"
)
var what_emotion_to_respond_with: int = 0:
	set(value):
		what_emotion_to_respond_with = value

		if is_node_ready():
			set_emotion()


# CHILD NODES

@onready var bin_sprite: Sprite2D = (
	$Sprite2D
)

@onready var cpu_particles_2d: CPUParticles2D = (
	$CPUParticles2D
)

@onready var animation_player: AnimationPlayer = (
	$AnimationPlayer
)


var bin_active: bool = false

var light_vfx_tween: Tween


func _ready() -> void:
	set_emotion()

	# This script runs in the editor because
	# it uses @tool. Gameplay signals should
	# only be connected while the game runs.
	if Engine.is_editor_hint():
		return

	if not body_entered.is_connected(
		_on_body_entered
	):
		body_entered.connect(
			_on_body_entered
		)

	if not GameData.emotion_changed.is_connected(
		on_active_emotion_changed
	):
		GameData.emotion_changed.connect(
			on_active_emotion_changed
		)

	on_active_emotion_changed(
		GameData.current_emotion
	)


func set_emotion() -> void:
	if not is_node_ready():
		return

	var emotion_names: Array = (
		GameData.emotions.keys()
	)

	if (
		what_emotion_to_respond_with < 0
		or what_emotion_to_respond_with
		>= emotion_names.size()
	):
		push_warning(
			"Invalid bin emotion index: %s"
			% what_emotion_to_respond_with
		)
		return

	var emotion_name: String = str(
		emotion_names[
			what_emotion_to_respond_with
		]
	)

	var bin_texture_path: String = (
		"res://Assets/Art/Game/BinSprites/"
		+ emotion_name
		+ "Bin.png"
	)

	var animation_path: String = (
		"res://Resources/Art/Game/BinSpriteFrames/"
		+ emotion_name
		+ "BinSpin.tres"
	)

	var bin_texture: Texture2D = load(
		bin_texture_path
	) as Texture2D

	var sprite_frames: SpriteFrames = load(
		animation_path
	) as SpriteFrames

	if bin_texture == null:
		push_warning(
			"Could not load bin texture: %s"
			% bin_texture_path
		)

	else:
		bin_sprite.texture = bin_texture

	if sprite_frames == null:
		push_warning(
			"Could not load bin animation: %s"
			% animation_path
		)

	else:
		animated_sprite.sprite_frames = (
			sprite_frames
		)


func on_active_emotion_changed(
	emotion_index: int
) -> void:
	bin_active = (
		emotion_index
		== what_emotion_to_respond_with
	)

	if bin_active:
		animated_sprite.visible = true

		animated_sprite.play(
			"default"
		)

		fade_light_to(
			1.0,
			fade_in_duration
		)

	else:
		animated_sprite.visible = false

		animated_sprite.stop()

		fade_light_to(
			0.0,
			fade_out_duration
		)


func fade_light_to(
	target_alpha: float,
	duration: float
) -> void:
	if light_vfx == null:
		return

	if (
		light_vfx_tween != null
		and light_vfx_tween.is_valid()
	):
		light_vfx_tween.kill()

	light_vfx_tween = create_tween()

	light_vfx_tween.tween_property(
		light_vfx,
		"modulate:a",
		target_alpha,
		duration
	)


func _on_body_entered(
	body: Node2D
) -> void:
	# Ignore anything that is not a Peggle ball.
	if (
		body.get_meta(
			"is_peggle_ball",
			false
		) != true
	):
		return

	# Ignore balls that have already entered
	# another bin or the endzone.
	if (
		body.get_meta(
			"ball_resolved",
			false
		) == true
	):
		return
		
	if bin_active:
		# Give power-up.
		PowerUpManager.set_triggered_power_up(PowerUpManager.power_ups.values().pick_random())

	# Tell the Peggle board which ball entered
	# and which emotion this bin represents.
	ball_caught.emit(
		body,
		what_emotion_to_respond_with
	)

	if emotion_sound != null:
		SfxPlayer.play(
			emotion_sound
		)

	EventBus.dialogue_mood_triggered.emit(
		what_emotion_to_respond_with,
		LevelManager.level
	)

	animation_player.play(
		"ball_caught"
	)

	GameData.current_emotion = (
		what_emotion_to_respond_with
	)
