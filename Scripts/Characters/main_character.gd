extends Node2D


@export_group("Position")

@export var root_position: Vector2 = Vector2(
	87.0,
	187.0
)


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

	if not EventBus.dialogue_mood_hide.is_connected(
		return_to_idle
	):
		EventBus.dialogue_mood_hide.connect(
			return_to_idle
		)

	configure_animation_loops()

	# Move the root Node2D.
	position = root_position

	# Always begin idle on the player's turn.
	play_animation(
		&"human_idle"
	)


func configure_animation_loops() -> void:
	# Emotion animations remain active throughout
	# the entire opponent turn.
	var emotion_animations: Array[StringName] = [
		&"human_happy",
		&"human_flirty",
		&"human_angry",
		&"human_dejected",
	]

	for animation_name: StringName in emotion_animations:
		if animated_sprite.sprite_frames.has_animation(
			animation_name
		):
			animated_sprite.sprite_frames.set_animation_loop(
				animation_name,
				true
			)

	if animated_sprite.sprite_frames.has_animation(
		&"human_idle"
	):
		animated_sprite.sprite_frames.set_animation_loop(
			&"human_idle",
			true
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

		return_to_idle()
		return

	var mood_name: String = str(
		emotion_names[mood_index]
	).to_lower()

	var animation_name: StringName = StringName(
		"human_" + mood_name
	)

	play_emotion_animation(
		animation_name
	)


func play_emotion_animation(
	animation_name: StringName
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_error(
			(
				"Human emotion animation does not exist: %s. "
				+ "Falling back to human_idle."
			)
			% animation_name
		)

		return_to_idle()
		return

	# Keep the root node at its assigned position.
	position = root_position

	# Restart the emotion animation and keep it
	# active for the entire opponent turn.
	animated_sprite.stop()
	animated_sprite.frame = 0

	animated_sprite.play(
		animation_name
	)


func return_to_idle() -> void:
	play_animation(
		&"human_idle"
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

	# Keep the root node at its assigned position.
	position = root_position

	if animated_sprite.animation == animation_name:
		if not animated_sprite.is_playing():
			animated_sprite.play(
				animation_name
			)

		return

	animated_sprite.play(
		animation_name
	)
