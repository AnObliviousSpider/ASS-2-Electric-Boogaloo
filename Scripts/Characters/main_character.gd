extends Node2D


@export_group("Position")

@export var root_position: Vector2 = Vector2(
	79.0,
	187.0
)


@export_group("Transition")

@export var fade_out_duration: float = 0.08
@export var fade_in_duration: float = 0.10


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


var transition_tween: Tween
var transition_request: int = 0


func _ready() -> void:
	if not EventBus.bin_emotion_triggered.is_connected(
		change_animation
	):
		EventBus.bin_emotion_triggered.connect(
			change_animation
		)

	if not EventBus.bin_emotion_cleared.is_connected(
		return_to_idle
	):
		EventBus.bin_emotion_cleared.connect(
			return_to_idle
		)

	configure_animation_loops()

	position = root_position
	animated_sprite.modulate.a = 0.0

	play_animation_now(
		&"human_idle",
		true
	)

	fade_sprite_to(
		1.0,
		fade_in_duration
	)


func _exit_tree() -> void:
	stop_transition_tween()


func configure_animation_loops() -> void:
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
	emotion_index: int
) -> void:
	var emotion_names: Array = (
		GameData.emotions.keys()
	)

	if (
		emotion_index < 0
		or emotion_index >= emotion_names.size()
	):
		push_error(
			"Invalid emotion index: %s"
			% emotion_index
		)

		return_to_idle()
		return

	var emotion_name: String = str(
		emotion_names[emotion_index]
	).to_lower()

	var animation_name: StringName = StringName(
		"human_" + emotion_name
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

	request_animation(
		animation_name,
		true
	)


func return_to_idle() -> void:
	request_animation(
		&"human_idle",
		false
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

	request_animation(
		animation_name,
		false
	)


func request_animation(
	animation_name: StringName,
	restart_animation: bool
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_error(
			"Human animation does not exist: %s"
			% animation_name
		)
		return

	transition_request += 1

	var request_id: int = transition_request

	transition_to_animation(
		animation_name,
		restart_animation,
		request_id
	)


func transition_to_animation(
	animation_name: StringName,
	restart_animation: bool,
	request_id: int
) -> void:
	stop_transition_tween()

	# Fade out the current animation.
	transition_tween = create_tween()

	transition_tween.tween_property(
		animated_sprite,
		"modulate:a",
		0.0,
		fade_out_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	await transition_tween.finished

	if request_id != transition_request:
		return

	# Swap the animation while invisible.
	play_animation_now(
		animation_name,
		restart_animation
	)

	# Fade the new animation back in.
	transition_tween = create_tween()

	transition_tween.tween_property(
		animated_sprite,
		"modulate:a",
		1.0,
		fade_in_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func play_animation_now(
	animation_name: StringName,
	restart_animation: bool
) -> void:
	position = root_position

	if restart_animation:
		animated_sprite.stop()
		animated_sprite.animation = animation_name
		animated_sprite.frame = 0

		animated_sprite.play(
			animation_name
		)
		return

	if animated_sprite.animation == animation_name:
		if not animated_sprite.is_playing():
			animated_sprite.play(
				animation_name
			)

		return

	animated_sprite.play(
		animation_name
	)


func fade_sprite_to(
	target_alpha: float,
	duration: float
) -> void:
	stop_transition_tween()

	transition_tween = create_tween()

	transition_tween.tween_property(
		animated_sprite,
		"modulate:a",
		target_alpha,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


func stop_transition_tween() -> void:
	if (
		transition_tween != null
		and transition_tween.is_valid()
	):
		transition_tween.kill()

	transition_tween = null
