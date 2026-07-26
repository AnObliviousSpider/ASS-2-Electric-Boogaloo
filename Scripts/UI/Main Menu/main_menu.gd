extends Control

# Main menu script.
# Handles scene buttons, button sounds, button juice,
# the neon logo animation, and the clickable arcade.


const NEW_GAME_INTRO_SCENE: String = (
	"inbetween_scene"
)


@export_group("Scenes")

@export var settings_scene: String = "settings"
@export var credits_scene: String = "credits"


@export_group("Scene Transitions")

@export var new_game_transition_duration: float = 1.0
@export var settings_transition_duration: float = 0.0
@export var credits_transition_duration: float = 1.0


@export_group("UI Sounds")

@export var click_sound: AudioStream
@export var hover_sound: AudioStream
@export var new_game_sound: AudioStream


@export_group("Arcade Interaction")

# Music played after clicking the arcade.
@export var arcade_music: AudioStream

# Duration of the music crossfade.
@export var arcade_music_crossfade_duration: float = 1.5

# Blends smoothly between the idle and party states.
@export var arcade_visual_blend_duration: float = 0.25


@export_group("Arcade Movement")

@export var arcade_idle_cycle_duration: float = 1.2
@export var arcade_idle_scale_amount: float = 0.015
@export var arcade_hover_scale_amount: float = 0.015

@export var arcade_bop_bpm: float = 120.0
@export var arcade_bop_height: float = 5.0
@export var arcade_bop_scale_amount: float = 0.055
@export var arcade_bop_rotation_degrees: float = 2.5


@export_group("Disco Filter")

@export var disco_alpha: float = 0.10

@export var disco_pink: Color = Color(
	1.0,
	0.51,
	0.74,
	1.0
)

@export var disco_cyan: Color = Color(
	0.33,
	0.81,
	0.65,
	1.0
)

@export var disco_purple: Color = Color(
	0.66,
	0.15,
	0.73,
	1.0
)


@export_group("TextureButton Juice")

@export var button_hover_scale: Vector2 = Vector2(
	1.3,
	1.3
)

@export var button_down_scale: Vector2 = Vector2(
	0.94,
	0.94
)

@export var button_up_scale: Vector2 = Vector2(
	1.35,
	1.35
)

@export var button_hover_duration: float = 0.5
@export var button_down_duration: float = 0.06
@export var button_up_duration: float = 0.08
@export var button_move_distance: float = 0.06
@export var button_move_duration: float = 0.08


@export_group("Logo Neon")

@export_range(
	0.1,
	5.0,
	0.1
)
var logo_flicker_speed: float = 1.0

@export var neon_light_energy: float = 0.2
@export var neon_light_2_energy: float = 0.2
@export var neon_flicker_sound: AudioStream
@export var neon_flicker_volume_db: float = 0.0
@export var neon_sound_tail_duration: float = 0.5


@onready var rock: Sprite2D = (
	$Island/Rock
)

@onready var arcade: Sprite2D = (
	$Island/Arcade
)

@onready var arcade_outline: Sprite2D = (
	$Island/Arcade/HoverOutline
)

@onready var disco_overlay: ColorRect = (
	$DiscoLayer/DiscoOverlay
)

@onready var new_game_button: TextureButton = (
	%NewGameButton
)

@onready var credits_button: TextureButton = (
	%CreditsButton
)

@onready var settings_button: TextureButton = (
	%SettingsButton
)

@onready var logo: Sprite2D = (
	$Logo
)

@onready var neon_light: PointLight2D = (
	%NeonLight
)

@onready var neon_light_2: PointLight2D = (
	%NeonLight2
)


# Stores active button tweens so new animations
# can cancel old ones.
var button_tweens: Dictionary = {}

var logo_tween: Tween

var arcade_base_position: Vector2
var arcade_base_scale: Vector2
var arcade_base_rotation: float

var arcade_idle_time: float = 0.0
var arcade_party_time: float = 0.0
var arcade_party_blend: float = 0.0

var arcade_hovered: bool = false
var arcade_music_active: bool = false


func _ready() -> void:
	get_tree().paused = false

	# Wait one frame so everything has its final
	# size, position, and scale.
	await get_tree().process_frame

	arcade_base_position = (
		arcade.position
	)

	arcade_base_scale = (
		arcade.scale
	)

	arcade_base_rotation = (
		arcade.rotation
	)

	_setup_buttons()

	arcade_outline.hide()

	var starting_disco_colour: Color = (
		disco_overlay.color
	)

	starting_disco_colour.a = 0.0

	disco_overlay.color = (
		starting_disco_colour
	)

	_blink_logo_in()


func _process(
	delta: float
) -> void:
	_update_arcade_visuals(
		delta
	)

	_update_arcade_hover()


func _input(
	event: InputEvent
) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if not mouse_event.pressed:
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not _is_mouse_over_arcade():
		return

	_toggle_arcade_music()

	get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	_stop_neon_flicker_sound()

	Input.set_default_cursor_shape(
		Input.CURSOR_ARROW
	)

	if is_instance_valid(
		arcade
	):
		arcade.position = (
			arcade_base_position
		)

		arcade.scale = (
			arcade_base_scale
		)

		arcade.rotation = (
			arcade_base_rotation
		)

	if is_instance_valid(
		disco_overlay
	):
		var ending_disco_colour: Color = (
			disco_overlay.color
		)

		ending_disco_colour.a = 0.0

		disco_overlay.color = (
			ending_disco_colour
		)


func _on_new_game_button_pressed() -> void:
	play_sfx(
		new_game_sound
	)

	SceneManager.go(
		NEW_GAME_INTRO_SCENE,
		new_game_transition_duration
	)


func _on_settings_button_pressed() -> void:
	play_sfx(
		click_sound
	)

	SceneManager.go(
		settings_scene,
		settings_transition_duration
	)


# This is still named load so existing editor
# signal connections do not break.
func _on_load_pressed() -> void:
	play_sfx(
		click_sound
	)

	SceneManager.go(
		credits_scene,
		credits_transition_duration
	)


func _update_arcade_visuals(
	delta: float
) -> void:
	arcade_idle_time += delta

	var target_party_blend: float = (
		1.0
		if arcade_music_active
		else 0.0
	)

	arcade_party_blend = move_toward(
		arcade_party_blend,
		target_party_blend,
		delta
		/ maxf(
			arcade_visual_blend_duration,
			0.001
		)
	)

	if (
		arcade_music_active
		or arcade_party_blend > 0.0
	):
		arcade_party_time += delta

	var idle_cycle: float = maxf(
		arcade_idle_cycle_duration,
		0.001
	)

	var idle_pulse: float = (
		sin(
			arcade_idle_time
			/ idle_cycle
			* TAU
		)
		+ 1.0
	) * 0.5

	var idle_scale: float = (
		1.0
		+ idle_pulse
			* arcade_idle_scale_amount
	)

	var beat_duration: float = (
		60.0
		/ maxf(
			arcade_bop_bpm,
			1.0
		)
	)

	var beat_phase: float = (
		fmod(
			arcade_party_time,
			beat_duration
		)
		/ beat_duration
	)

	var beat_wave: float = 0.0

	# Reach the top of the bop 20 percent into
	# the beat, then land halfway through it.
	if beat_phase < 0.2:
		beat_wave = smoothstep(
			0.0,
			0.2,
			beat_phase
		)
	elif beat_phase < 0.5:
		beat_wave = 1.0 - smoothstep(
			0.2,
			0.5,
			beat_phase
		)

	var party_scale: float = (
		1.0
		+ beat_wave
			* arcade_bop_scale_amount
	)

	var visual_scale: float = lerpf(
		idle_scale,
		party_scale,
		arcade_party_blend
	)

	if arcade_hovered:
		visual_scale += (
			arcade_hover_scale_amount
		)

	var beat_number: int = int(
		floor(
			arcade_party_time
			/ beat_duration
		)
	)

	var rotation_direction: float = (
		-1.0
		if beat_number % 2 == 0
		else 1.0
	)

	arcade.scale = (
		arcade_base_scale
		* visual_scale
	)

	arcade.position = (
		arcade_base_position
		+ Vector2(
			0.0,
			-arcade_bop_height
				* beat_wave
				* arcade_party_blend
		)
	)

	arcade.rotation = (
		arcade_base_rotation
		+ deg_to_rad(
			arcade_bop_rotation_degrees
		)
			* rotation_direction
			* beat_wave
			* arcade_party_blend
	)

	_update_disco_filter(
		beat_duration
	)


func _update_disco_filter(
	beat_duration: float
) -> void:
	var colour_cycle_position: float = (
		fmod(
			arcade_party_time,
			beat_duration * 4.0
		)
		/ beat_duration
	)

	var colour_section: int = int(
		floor(
			colour_cycle_position
		)
	)

	var colour_blend: float = (
		colour_cycle_position
		- float(
			colour_section
		)
	)

	var start_colour: Color
	var end_colour: Color

	match colour_section:
		0:
			start_colour = disco_pink
			end_colour = disco_cyan

		1:
			start_colour = disco_cyan
			end_colour = disco_purple

		2:
			start_colour = disco_purple
			end_colour = disco_cyan

		_:
			start_colour = disco_cyan
			end_colour = disco_pink

	var disco_colour: Color = (
		start_colour.lerp(
			end_colour,
			colour_blend
		)
	)

	disco_colour.a = (
		disco_alpha
		* arcade_party_blend
	)

	disco_overlay.color = (
		disco_colour
	)


func _update_arcade_hover() -> void:
	var is_hovering: bool = (
		_is_mouse_over_arcade()
	)

	if is_hovering == arcade_hovered:
		return

	arcade_hovered = is_hovering

	if is_instance_valid(
		arcade_outline
	):
		arcade_outline.visible = (
			arcade_hovered
		)

	if arcade_hovered:
		play_sfx(
			hover_sound
		)

		Input.set_default_cursor_shape(
			Input.CURSOR_POINTING_HAND
		)
	else:
		Input.set_default_cursor_shape(
			Input.CURSOR_ARROW
		)


func _is_mouse_over_arcade() -> bool:
	if not is_instance_valid(
		arcade
	):
		return false

	if not arcade.is_visible_in_tree():
		return false

	if arcade.texture == null:
		return false

	var local_mouse_position: Vector2 = (
		arcade.to_local(
			get_global_mouse_position()
		)
	)

	return arcade.get_rect().has_point(
		local_mouse_position
	)


func _toggle_arcade_music() -> void:
	var target_music: AudioStream
	var new_arcade_music_state: bool

	if arcade_music_active:
		target_music = (
			SceneMusicManager.get_music_for_scene(
				"main_menu"
			)
		)

		new_arcade_music_state = false
	else:
		target_music = arcade_music
		new_arcade_music_state = true

	if target_music == null:
		if new_arcade_music_state:
			push_warning(
				"No alternative arcade music "
				+ "has been assigned."
			)
		else:
			push_warning(
				"No music is assigned to the "
				+ "main_menu scene key."
			)

		return

	play_sfx(
		click_sound
	)

	arcade_music_active = (
		new_arcade_music_state
	)

	if arcade_music_active:
		arcade_party_time = 0.0

	if MusicPlayer.is_playing(
		target_music
	):
		return

	# The final true enables the crossfade.
	MusicPlayer.play(
		target_music,
		true,
		false,
		arcade_music_crossfade_duration,
		true
	)


func _setup_buttons() -> void:
	for node: Node in find_children(
		"*",
		"TextureButton",
		true,
		false
	):
		var button: TextureButton = (
			node as TextureButton
		)

		if button == null:
			continue

		button.pivot_offset = (
			button.size / 2.0
		)

		var mouse_entered_callable: Callable = (
			_on_button_mouse_entered.bind(
				button
			)
		)

		var mouse_exited_callable: Callable = (
			_on_button_mouse_exited.bind(
				button
			)
		)

		var button_down_callable: Callable = (
			_on_button_down.bind(
				button
			)
		)

		var button_up_callable: Callable = (
			_on_button_up.bind(
				button
			)
		)

		if not button.mouse_entered.is_connected(
			mouse_entered_callable
		):
			button.mouse_entered.connect(
				mouse_entered_callable
			)

		if not button.mouse_exited.is_connected(
			mouse_exited_callable
		):
			button.mouse_exited.connect(
				mouse_exited_callable
			)

		if not button.button_down.is_connected(
			button_down_callable
		):
			button.button_down.connect(
				button_down_callable
			)

		if not button.button_up.is_connected(
			button_up_callable
		):
			button.button_up.connect(
				button_up_callable
			)


func _on_button_mouse_entered(
	button: TextureButton
) -> void:
	play_sfx(
		hover_sound
	)

	_animate_button(
		button,
		button_hover_scale,
		button_hover_duration,
		button_move_distance,
		button_move_duration
	)


func _on_button_mouse_exited(
	button: TextureButton
) -> void:
	_animate_button(
		button,
		Vector2.ONE,
		button_hover_duration,
		0.0,
		button_move_duration
	)


func _on_button_down(
	button: TextureButton
) -> void:
	play_sfx(
		click_sound
	)

	_animate_button(
		button,
		button_down_scale,
		button_down_duration,
		button_move_distance / 2.0,
		button_move_duration
	)


func _on_button_up(
	button: TextureButton
) -> void:
	if button.get_global_rect().has_point(
		get_global_mouse_position()
	):
		_animate_button(
			button,
			button_up_scale,
			button_up_duration,
			button_move_distance,
			button_move_duration
		)
	else:
		_animate_button(
			button,
			Vector2.ONE,
			button_up_duration,
			0.0,
			button_move_duration
		)


func _animate_button(
	button: TextureButton,
	target_scale: Vector2,
	duration: float,
	target_move_distance: float,
	target_move_duration: float
) -> void:
	if button == null:
		return

	if button_tweens.has(
		button
	):
		var old_tween: Tween = (
			button_tweens[button] as Tween
		)

		if old_tween != null:
			old_tween.kill()

	var tween: Tween = create_tween()

	button_tweens[button] = tween

	tween.tween_property(
		button,
		"scale",
		target_scale,
		duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	tween.parallel()

	tween.tween_property(
		button,
		"position:x",
		target_move_distance,
		target_move_duration
	).from_current()


func _blink_logo_in() -> void:
	if logo_tween != null:
		logo_tween.kill()

	_stop_neon_flicker_sound()

	logo.modulate.a = 0.0
	neon_light.energy = 0.0
	neon_light_2.energy = 0.0

	logo_tween = create_tween()

	_play_neon_flicker_sound()

	var flicker_sequence: Array[Vector2] = [
		Vector2(0.90, 0.06),
		Vector2(0.05, 0.04),
		Vector2(0.65, 0.08),
		Vector2(0.10, 0.05),
		Vector2(1.00, 0.07),
		Vector2(0.25, 0.06),
		Vector2(0.85, 0.05),
		Vector2(0.10, 0.04),
		Vector2(1.00, 0.15),
	]

	for flicker: Vector2 in flicker_sequence:
		var brightness: float = (
			flicker.x
		)

		var duration: float = (
			flicker.y
			/ logo_flicker_speed
		)

		logo_tween.tween_property(
			logo,
			"modulate:a",
			brightness,
			duration
		)

		logo_tween.parallel().tween_property(
			neon_light,
			"energy",
			brightness * neon_light_energy,
			duration
		)

		logo_tween.parallel().tween_property(
			neon_light_2,
			"energy",
			brightness * neon_light_2_energy,
			duration
		)

	var final_duration: float = (
		0.08
		/ logo_flicker_speed
	)

	logo_tween.tween_property(
		logo,
		"modulate:a",
		1.0,
		final_duration
	)

	logo_tween.parallel().tween_property(
		neon_light,
		"energy",
		neon_light_energy,
		final_duration
	)

	logo_tween.parallel().tween_property(
		neon_light_2,
		"energy",
		neon_light_2_energy,
		final_duration
	)

	logo_tween.tween_interval(
		neon_sound_tail_duration
	)

	logo_tween.finished.connect(
		_on_logo_flicker_finished
	)


func _play_neon_flicker_sound() -> void:
	if neon_flicker_sound == null:
		return

	SfxPlayer.play(
		neon_flicker_sound,
		false,
		false,
		0.5,
		false,
		neon_flicker_volume_db,
		0.5,
		false,
		true
	)


func _stop_neon_flicker_sound() -> void:
	if neon_flicker_sound == null:
		return

	SfxPlayer.stop_audio(
		neon_flicker_sound
	)


func _on_logo_flicker_finished() -> void:
	_stop_neon_flicker_sound()


func play_sfx(
	sound: AudioStream
) -> void:
	if sound != null:
		SfxPlayer.play(
			sound
		)
