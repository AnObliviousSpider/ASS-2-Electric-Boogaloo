extends Node2D


@export_group("Animation Positions")

@export var animation_positions: Dictionary[StringName, Vector2] = {
	&"human_idle": Vector2.ZERO,
	&"human_happy": Vector2.ZERO,
	&"human_flirty": Vector2.ZERO,
	&"human_angry": Vector2.ZERO,
	&"human_sad": Vector2.ZERO,
}


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


func _ready() -> void:
	if not EventBus.dialogue_mood_triggered.is_connected(
		change_animation
	):
		EventBus.dialogue_mood_triggered.connect(
			change_animation
	)

	play_animation(
		&"human_idle"
	)


func change_animation(
	mood_index: int,
	_dialogue_level: int
) -> void:
	var emotion_names: Array = (
		GameData.emotions.keys()
	)

	if (
		mood_index < 0
		or mood_index >= emotion_names.size()
	):
		push_error(
			"Invalid mood index: %s"
			% mood_index
		)

		play_animation(
			&"human_idle"
		)
		return

	var mood_name: String = str(
		emotion_names[mood_index]
	).to_lower()

	var animation_name := StringName(
		"human_" + mood_name
	)

	play_animation(
		animation_name
	)


func play_animation(
	animation_name: StringName
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_error(
			(
				"Human animation does not exist: %s. "
				+ "Falling back to human_idle."
			)
			% animation_name
		)

		animation_name = &"human_idle"

	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_error(
			"Fallback animation human_idle does not exist."
		)
		return

	if animation_positions.has(animation_name):
		animated_sprite.position = (
			animation_positions[animation_name]
		)

	if animated_sprite.animation == animation_name:
		return

	animated_sprite.play(
		animation_name
	)
