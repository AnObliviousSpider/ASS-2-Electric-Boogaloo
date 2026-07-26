extends Node2D


@export_group("Form Positions")

@export var human_position: Vector2 = Vector2(
	-17.0,
	70
)

@export var chimera_position: Vector2 = Vector2(
	5.0,
	-3.0
)


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


var return_animation: StringName = &"idle_human"


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

	# Always begin in the human idle animation.
	play_animation(
		&"idle_human"
	)


func configure_animation_loops() -> void:
	# These animations remain active throughout
	# the entire opponent turn.
	var emotion_animations: Array[StringName] = [
		&"angry_chimera",
		&"dejected_chimera",
		&"human_flirty",
		&"human_happy",
	]

	for animation_name: StringName in emotion_animations:
		if animated_sprite.sprite_frames.has_animation(
			animation_name
		):
			animated_sprite.sprite_frames.set_animation_loop(
				animation_name,
				true
			)

	var idle_animations: Array[StringName] = [
		&"idle_human",
		&"idle_chimera",
	]

	for animation_name: StringName in idle_animations:
		if animated_sprite.sprite_frames.has_animation(
			animation_name
		):
			animated_sprite.sprite_frames.set_animation_loop(
				animation_name,
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
		push_warning(
			"Invalid mood index: %s"
			% mood_index
		)
		return

	var mood_name: String = str(
		emotion_names[mood_index]
	).to_lower()

	match mood_name:
		"angry":
			play_emotion_animation(
				&"angry_chimera",
				&"idle_chimera"
			)

		"dejected":
			play_emotion_animation(
				&"dejected_chimera",
				&"idle_chimera"
			)

		"flirty":
			play_emotion_animation(
				&"human_flirty",
				&"idle_human"
			)

		"happy":
			play_emotion_animation(
				&"human_happy",
				&"idle_human"
			)

		_:
			push_warning(
				"Unknown Li mood: %s"
				% mood_name
			)

			return_animation = &"idle_human"

			play_animation(
				return_animation
			)


func play_emotion_animation(
	emotion_animation: StringName,
	idle_animation: StringName
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		emotion_animation
	):
		push_warning(
			"Li emotion animation does not exist: %s"
			% emotion_animation
		)

		return_animation = idle_animation

		play_animation(
			idle_animation
		)
		return

	if not animated_sprite.sprite_frames.has_animation(
		idle_animation
	):
		push_warning(
			"Li idle animation does not exist: %s"
			% idle_animation
		)
		return

	# Remember which idle animation should be used
	# when control returns to the player.
	return_animation = idle_animation

	set_form_position(
		emotion_animation
	)

	# Restart the emotion animation from its
	# first frame and keep it looping.
	animated_sprite.stop()
	animated_sprite.frame = 0

	animated_sprite.play(
		emotion_animation
	)


func return_to_idle() -> void:
	play_animation(
		return_animation
	)


func play_animation(
	animation_name: StringName
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_warning(
			"Li animation does not exist: %s"
			% animation_name
		)
		return

	set_form_position(
		animation_name
	)

	if animated_sprite.animation == animation_name:
		if not animated_sprite.is_playing():
			animated_sprite.play(
				animation_name
			)

		return

	animated_sprite.play(
		animation_name
	)


func set_form_position(
	animation_name: StringName
) -> void:
	var animation_name_string: String = str(
		animation_name
	).to_lower()

	# Move this Node2D to the chimera position.
	if animation_name_string.contains(
		"chimera"
	):
		position = chimera_position
		return

	# Move this Node2D to the human position.
	if animation_name_string.contains(
		"human"
	):
		position = human_position
		return

	push_warning(
		"Li animation does not specify a form: %s"
		% animation_name
	)
