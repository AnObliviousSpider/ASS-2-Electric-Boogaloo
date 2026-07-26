extends Node2D


const HUMAN_FORM: StringName = &"human"
const CHIMERA_FORM: StringName = &"chimera"


@export_group("Form Positions")

@export var human_position: Vector2 = Vector2(
	-17.0,
	70.0
)

@export var chimera_position: Vector2 = Vector2(
	8.0,
	-3.0
)


@export_group("Animation Transition")

@export var fade_out_duration: float = 0.08
@export var fade_in_duration: float = 0.10


@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


var return_animation: StringName = &"idle_human"
var target_animation: StringName = &"idle_human"

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

	if not EventBus.dialogue_line_emotion_triggered.is_connected(
		_on_dialogue_line_emotion_triggered
	):
		EventBus.dialogue_line_emotion_triggered.connect(
			_on_dialogue_line_emotion_triggered
		)

	configure_animation_loops()

	animated_sprite.modulate.a = 1.0

	play_animation_now(
		&"idle_human",
		false
	)


func _exit_tree() -> void:
	stop_transition_tween()


func configure_animation_loops() -> void:
	var animations: Array[StringName] = [
		&"angry_chimera",
		&"dejected_chimera",
		&"human_flirty",
		&"human_happy",
		&"idle_human",
		&"idle_chimera",
	]

	for animation_name: StringName in animations:
		if animated_sprite.sprite_frames.has_animation(
			animation_name
		):
			animated_sprite.sprite_frames.set_animation_loop(
				animation_name,
				true
			)


func _on_dialogue_line_emotion_triggered(
	alignment: StringName,
	emotion_index: int
) -> void:
	if alignment != &"right":
		return

	if emotion_index == EventBus.IDLE_EMOTION_INDEX:
		return_to_idle()
		return

	change_animation(
		emotion_index
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
		push_warning(
			"Invalid emotion index: %s"
			% emotion_index
		)
		return

	var emotion_name: String = str(
		emotion_names[emotion_index]
	).to_lower()

	match emotion_name:
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
				"Unknown Li emotion: %s"
				% emotion_name
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
		return

	return_animation = idle_animation

	request_animation(
		emotion_animation,
		true
	)


func return_to_idle() -> void:
	request_animation(
		return_animation,
		false
	)


func request_animation(
	animation_name: StringName,
	restart_animation: bool
) -> void:
	if not animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		push_warning(
			"Li animation does not exist: %s"
			% animation_name
		)
		return

	# Do not restart or fade when the requested
	# animation is already active.
	if target_animation == animation_name:
		return

	target_animation = animation_name
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

	play_animation_now(
		animation_name,
		restart_animation
	)

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
	set_form_position(
		animation_name
	)

	if restart_animation:
		animated_sprite.stop()
		animated_sprite.frame = 0

	animated_sprite.play(
		animation_name
	)


func stop_transition_tween() -> void:
	if (
		transition_tween != null
		and transition_tween.is_valid()
	):
		transition_tween.kill()

	transition_tween = null


func get_animation_form(
	animation_name: StringName
) -> StringName:
	var animation_text: String = str(
		animation_name
	).to_lower()

	if animation_text.contains(
		"chimera"
	):
		return CHIMERA_FORM

	if animation_text.contains(
		"human"
	):
		return HUMAN_FORM

	return &""


func set_form_position(
	animation_name: StringName
) -> void:
	match get_animation_form(
		animation_name
	):
		CHIMERA_FORM:
			position = chimera_position

		HUMAN_FORM:
			position = human_position

		_:
			push_warning(
				"Li animation does not specify a form: %s"
				% animation_name
			)
