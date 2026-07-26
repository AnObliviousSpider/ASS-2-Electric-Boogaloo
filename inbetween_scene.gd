extends Control


signal introduction_finished
signal advance_requested


@export_group("Timing")

@export var fade_in_duration: float = 0.7
@export var fade_out_duration: float = 0.6
@export var gap_between_lines: float = 0.25
@export var transition_delay: float = 0.5


@export_group("Audio")

# Plays during the first text glitch only.
@export var text_show_sound: AudioStream
@export var text_show_volume_db: float = 0.0

# Music played when this scene loads.
@export var scene_music: AudioStream
@export var music_crossfade_duration: float = 1.0


@export_group("Glitch Colours")

@export var glitch_green: Color = Color(
	0.329,
	0.808,
	0.655,
	1.0
)

@export var glitch_teal: Color = Color(
	0.169,
	0.643,
	0.651,
	1.0
)

@export var glitch_blue: Color = Color(
	0.047,
	0.412,
	0.529,
	1.0
)

@export var glitch_light_pink: Color = Color(
	1.0,
	0.690,
	0.749,
	1.0
)

@export var glitch_pink: Color = Color(
	1.0,
	0.510,
	0.741,
	1.0
)

@export var glitch_magenta: Color = Color(
	0.843,
	0.290,
	0.780,
	1.0
)

@export var glitch_purple: Color = Color(
	0.659,
	0.145,
	0.729,
	1.0
)


@export_group("New Game")

@export var new_game_scene: String = "main"
@export var new_game_transition_duration: float = 1.0
@export var new_game_sound: AudioStream
@export var starting_ball_count: int = 50
@export var starting_level: int = 0


@onready var color_rect: ColorRect = (
	$ColorRect
)

@onready var dialogue_label: Label = (
	$Label
)


var introduction_lines: Array[String] = [
	"Let us begin at the\nend of everything. Dramatic, yes?\nNear where Andromeda used to be.",
	"Only three things remain worth\nmentioning. A barely preserved arcade,\nthe last human, and the\nentity destined to end everything.",
	"Oh, and the best part?\nThe human and the cosmic\nharbinger are dating.",
	"So, naturally, this should all\ngo perfectly well. Nothing tragic\ncould possibly happen here.",
]


var label_normal_modulate: Color
var current_final_color: Color
var text_tween: Tween

var introduction_running: bool = false
var accepting_advance: bool = false
var waiting_for_advance: bool = false
var advance_queued: bool = false
var game_transition_started: bool = false

var text_glitch_sound_playing: bool = false
var text_glitch_sound_has_played: bool = false


func _ready() -> void:
	label_normal_modulate = (
		dialogue_label.modulate
	)

	label_normal_modulate.a = 1.0

	current_final_color = (
		label_normal_modulate
	)

	dialogue_label.modulate = (
		label_normal_modulate
	)

	dialogue_label.modulate.a = 0.0
	dialogue_label.text = ""

	play_scene_music()
	play_introduction()


func _input(
	event: InputEvent
) -> void:
	if not introduction_running:
		return

	if not event.is_action_pressed(
		"action_primary"
	):
		return

	if not accepting_advance:
		return

	get_viewport().set_input_as_handled()

	if waiting_for_advance:
		waiting_for_advance = false
		accepting_advance = false

		advance_requested.emit()
	else:
		# Remember a click made while the current
		# line is still glitching into view.
		advance_queued = true


func _exit_tree() -> void:
	stop_text_tween()
	stop_text_glitch_sound()


func play_introduction() -> void:
	if introduction_running:
		return

	introduction_running = true

	for line_index: int in range(
		introduction_lines.size()
	):
		dialogue_label.text = (
			introduction_lines[line_index]
		)

		current_final_color = (
			get_final_color_for_line(
				line_index
			)
		)

		advance_queued = false
		accepting_advance = true

		await glitch_label_in(
			current_final_color
		)

		if advance_queued:
			advance_queued = false
			accepting_advance = false
		else:
			waiting_for_advance = true

			await advance_requested

			waiting_for_advance = false
			accepting_advance = false

		await fade_label_out()

		await get_tree().create_timer(
			gap_between_lines
		).timeout

	dialogue_label.text = ""

	introduction_running = false
	accepting_advance = false
	waiting_for_advance = false
	advance_queued = false

	introduction_finished.emit()

	await get_tree().create_timer(
		transition_delay
	).timeout

	start_new_game()


func glitch_label_in(
	final_color: Color
) -> void:
	stop_text_tween()

	var glitch_alphas: Array = [
		0.90,
		0.08,
		0.65,
		0.18,
		0.85,
		0.12,
		0.75,
		0.30,
		0.95,
		0.45,
		0.80,
		1.0,
	]

	var glitch_colors: Array = [
		glitch_green,
		glitch_pink,
		glitch_blue,
		glitch_light_pink,
		glitch_purple,
		glitch_teal,
		glitch_magenta,
		glitch_green,
		glitch_pink,
		glitch_blue,
		glitch_light_pink,
		final_color,
	]

	var step_duration: float = (
		fade_in_duration
		/ float(
			glitch_alphas.size()
		)
	)

	dialogue_label.modulate = (
		glitch_colors[0]
	)

	dialogue_label.modulate.a = 0.0

	text_tween = create_tween()

	# This function ignores every call after the
	# first successful playback.
	play_text_glitch_sound()

	for index: int in range(
		glitch_alphas.size()
	):
		var target_modulate: Color = (
			glitch_colors[index]
		)

		target_modulate.a = float(
			glitch_alphas[index]
		)

		text_tween.tween_property(
			dialogue_label,
			"modulate",
			target_modulate,
			step_duration
		).set_trans(
			Tween.TRANS_LINEAR
		)

	await text_tween.finished

	text_tween = null

	stop_text_glitch_sound()

	final_color.a = 1.0

	dialogue_label.modulate = (
		final_color
	)


func get_final_color_for_line(
	line_index: int
) -> Color:
	match line_index % 4:
		0:
			return glitch_green

		1:
			return glitch_teal

		2:
			return glitch_pink

		3:
			return glitch_magenta

	return label_normal_modulate


func fade_label_out() -> void:
	stop_text_tween()

	current_final_color.a = 1.0

	dialogue_label.modulate = (
		current_final_color
	)

	text_tween = create_tween()

	text_tween.tween_property(
		dialogue_label,
		"modulate:a",
		0.0,
		fade_out_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN_OUT
	)

	await text_tween.finished

	text_tween = null


func stop_text_tween() -> void:
	if (
		text_tween != null
		and text_tween.is_valid()
	):
		text_tween.kill()

	text_tween = null

	# If the first glitch tween is interrupted,
	# its sound stops immediately.
	stop_text_glitch_sound()


func play_text_glitch_sound() -> void:
	if text_glitch_sound_has_played:
		return

	if text_show_sound == null:
		return

	stop_text_glitch_sound()

	text_glitch_sound_has_played = true
	text_glitch_sound_playing = true

	SfxPlayer.play(
		text_show_sound,
		false,
		false,
		0.5,
		false,
		text_show_volume_db,
		0.5,
		false,
		true
	)


func stop_text_glitch_sound() -> void:
	if not text_glitch_sound_playing:
		return

	text_glitch_sound_playing = false

	if text_show_sound == null:
		return

	SfxPlayer.stop_audio(
		text_show_sound
	)


func play_scene_music() -> void:
	if scene_music == null:
		push_warning(
			"No introduction scene music has been assigned."
		)
		return

	if MusicPlayer.is_playing(
		scene_music
	):
		return

	MusicPlayer.play(
		scene_music,
		true,
		false,
		music_crossfade_duration,
		true
	)


func start_new_game() -> void:
	if game_transition_started:
		return

	game_transition_started = true

	play_sfx(
		new_game_sound
	)

	GameData.start_new_game(
		starting_ball_count
	)

	LevelManager.set_level(
		starting_level
	)

	SceneManager.go(
		new_game_scene,
		new_game_transition_duration
	)


func play_sfx(
	sound: AudioStream
) -> void:
	if sound != null:
		SfxPlayer.play(
			sound
		)
