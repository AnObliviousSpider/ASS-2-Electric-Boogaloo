extends Control
class_name CountdownDisplay


@export_group("Sounds")
@export var countdown_tick_sfx: AudioStream
@export var critical_tick_sfx: AudioStream
@export var miss_burst_sfx: AudioStream
@export var refund_sfx: AudioStream
@export var music_bus_name: StringName = &"Music"
@export var music_duck_db: float = -7.0

@export_group("Countdown Neon")
@export_range(0.1, 5.0, 0.1) var remaining_flicker_speed: float = 1.0
@export var remaining_flicker_sound: AudioStream
@export var remaining_flicker_volume_db: float = 0.0
@export var remaining_sound_tail_duration: float = 0.5

@export_group("Timing")
@export var anticipation_duration: float = 0.12
@export var impact_duration: float = 0.16
@export var settle_duration: float = 0.28
@export var dark_hold_duration: float = 0.24
@export var darkness_fade_duration: float = 0.55
@export var flash_duration: float = 0.40
@export var refund_duration: float = 0.22

@export_group("Motion")
@export var minimum_impact_scale: float = 1.16
@export var maximum_impact_scale: float = 1.55
@export var minimum_screen_shake: float = 4.0
@export var maximum_screen_shake: float = 14.0
@export var minimum_screen_shake_duration: float = 0.55
@export var maximum_screen_shake_duration: float = 0.95
@export var refund_screen_shake: float = 1.5
@export var refund_screen_shake_duration: float = 0.16
@export var minimum_vignette_darkness: float = 0.28
@export var maximum_vignette_darkness: float = 0.76

@export_group("Colours")
@export var normal_colour: Color = Color(0.95, 0.95, 1.0)
@export var warning_colour: Color = Color(1.0, 0.73, 0.22)
@export var critical_colour: Color = Color(1.0, 0.18, 0.12)

@export_group("Idle Warning")
@export var warning_threshold: float = 0.30
@export var critical_threshold: float = 0.10
@export var warning_breathe_amount: float = 0.025
@export var critical_breathe_amount: float = 0.055
@export var warning_breathe_speed: float = 2.5
@export var critical_breathe_speed: float = 5.0
@export var critical_jitter_pixels: float = 0.7


@onready var display_root: Control = $DisplayRoot
@onready var main_label: Label = $DisplayRoot/MainLabel
@onready var remaining_label: Label = $DisplayRoot/RemainingLabel

@onready var vignette: ColorRect = $CountdownOverlay/Vignette
@onready var impact_flash: ColorRect = $CountdownOverlay/ImpactFlash
@onready var star_effects: Node2D = $CountdownOverlay/StarEffects
@onready var travelling_star_template: Polygon2D = (
	$CountdownOverlay/StarEffects/TravellingStarTemplate
)
@onready var refund_star_template: Polygon2D = (
	$CountdownOverlay/StarEffects/RefundStarTemplate
)
@onready var shockwave: Line2D = $CountdownOverlay/Shockwave
@onready var old_number: Label = $CountdownOverlay/NumberRoll/OldNumber
@onready var new_number: Label = $CountdownOverlay/NumberRoll/NewNumber


var displayed_count: int = 0
var maximum_count: int = 1
var busy: bool = false
var idle_time: float = 0.0

var base_position: Vector2
var base_scale: Vector2
var base_rotation: float

var vignette_material: ShaderMaterial
var flash_colour: Color
var main_flicker_tween: Tween
var remaining_flicker_tween: Tween
var flicker_sound_tween: Tween

var music_bus_index: int = -1
var old_music_volume: float = 0.0
var music_is_ducked: bool = false

var shake_target: Node2D
var shake_start_position: Vector2
var shaking: bool = false


func _ready() -> void:
	base_position = display_root.position
	base_scale = display_root.scale
	base_rotation = display_root.rotation

	display_root.pivot_offset = display_root.size / 2.0
	main_label.pivot_offset = main_label.size / 2.0
	main_label.resized.connect(_update_pivots)

	vignette_material = vignette.material as ShaderMaterial
	flash_colour = impact_flash.color

	travelling_star_template.hide()
	refund_star_template.hide()
	shockwave.hide()
	old_number.hide()
	new_number.hide()

	if vignette_material:
		vignette_material.set_shader_parameter("darkness", 0.0)

	impact_flash.color.a = 0.0
	_copy_label_style(old_number)
	_copy_label_style(new_number)

	music_bus_index = AudioServer.get_bus_index(music_bus_name)
	set_count_immediate(_text_as_number(), maximum_count)


func _process(delta: float) -> void:
	if busy:
		return

	idle_time += delta
	var fraction := _remaining_fraction(displayed_count, maximum_count)

	if fraction > warning_threshold:
		_reset_display()
		return

	var critical := fraction <= critical_threshold
	var amount := critical_breathe_amount if critical else warning_breathe_amount
	var speed := critical_breathe_speed if critical else warning_breathe_speed
	var pulse := (sin(idle_time * speed) + 1.0) * 0.5

	display_root.scale = base_scale * (1.0 + pulse * amount)
	display_root.position = base_position

	if critical:
		display_root.position += Vector2(
			randf_range(-critical_jitter_pixels, critical_jitter_pixels),
			randf_range(-critical_jitter_pixels, critical_jitter_pixels)
		)


func _exit_tree() -> void:
	_stop_remaining_flicker_sound()
	_restore_music()
	_stop_shake()


# Used when a level begins or the counter needs to be synchronised quietly.
func set_count_immediate(new_count: int, new_maximum: int) -> void:
	displayed_count = maxi(new_count, 0)
	maximum_count = maxi(new_maximum, 1)

	main_label.text = str(displayed_count)
	_update_remaining_text()
	main_label.add_theme_color_override(
		"font_color",
		_count_colour(displayed_count, maximum_count)
	)
	main_label.self_modulate.a = 1.0

	if not busy:
		_reset_display()


# Plays only after a shot has permanently consumed a ball.
func play_countdown_loss(
	new_count: int,
	new_maximum: int,
	ball_world_position: Vector2
) -> void:
	if busy:
		set_count_immediate(new_count, new_maximum)
		return

	busy = true
	idle_time = 0.0
	_reset_display()

	maximum_count = maxi(new_maximum, 1)
	new_count = maxi(new_count, 0)

	var old_count := displayed_count
	var intensity := _impact_intensity(new_count, maximum_count)
	var label_rect := main_label.get_global_rect()
	var target_position := label_rect.get_center()
	var source_position := (
		get_viewport().get_canvas_transform() * ball_world_position
	)

	source_position = _clamp_to_viewport(source_position)

	_set_vignette_focus(target_position)
	_aim_cannon_at_counter()
	_duck_music()
	_play_countdown_sound(intensity)
	_throw_stars(source_position, target_position, intensity)

	var darkness := lerpf(
		minimum_vignette_darkness,
		maximum_vignette_darkness,
		intensity
	)

	if vignette_material:
		var vignette_in := create_tween()
		vignette_in.tween_property(
			vignette_material,
			"shader_parameter/darkness",
			darkness,
			anticipation_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await vignette_in.finished
	else:
		await get_tree().create_timer(anticipation_duration).timeout

	_prepare_number(old_number, str(old_count), _count_colour(
		old_count,
		maximum_count
	), label_rect)
	_prepare_number(new_number, str(new_count), _count_colour(
		new_count,
		maximum_count
	), label_rect)

	var roll_distance := lerpf(18.0, 44.0, intensity)
	var impact_scale := lerpf(
		minimum_impact_scale,
		maximum_impact_scale,
		intensity
	)

	old_number.position = label_rect.position
	new_number.position = label_rect.position - Vector2(0.0, roll_distance)
	new_number.scale = Vector2.ONE * impact_scale
	new_number.modulate.a = 0.0

	old_number.show()
	new_number.show()
	main_label.self_modulate.a = 0.0

	_play_miss_burst_sound()
	_flash(intensity)
	_play_shockwave(target_position, new_count, intensity)
	_start_shake(
		lerpf(
			minimum_screen_shake_duration,
			maximum_screen_shake_duration,
			intensity
		),
		lerpf(minimum_screen_shake, maximum_screen_shake, intensity)
	)

	var roll := create_tween().set_parallel()
	roll.tween_property(
		old_number,
		"position",
		label_rect.position + Vector2(0.0, roll_distance),
		impact_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	roll.tween_property(
		old_number,
		"modulate:a",
		0.0,
		impact_duration
	)
	roll.tween_property(
		new_number,
		"position",
		label_rect.position,
		impact_duration
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	roll.tween_property(
		new_number,
		"modulate:a",
		1.0,
		impact_duration * 0.55
	)
	await roll.finished

	displayed_count = new_count
	main_label.text = str(displayed_count)
	_update_remaining_text()
	main_label.add_theme_color_override(
		"font_color",
		_count_colour(displayed_count, maximum_count)
	)

	# Hand the impact scale over to the real label,
	# then start both flickers while the explosion
	# flash, darkness and screen shake are still active.
	main_label.scale = new_number.scale
	old_number.hide()
	new_number.hide()
	main_label.self_modulate.a = 1.0
	_flicker_count_labels()

	if dark_hold_duration > 0.0:
		await get_tree().create_timer(dark_hold_duration).timeout

	var settle := create_tween().set_parallel()
	settle.tween_property(
		main_label,
		"scale",
		Vector2.ONE,
		settle_duration
	).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	if vignette_material:
		settle.tween_property(
			vignette_material,
			"shader_parameter/darkness",
			0.0,
			darkness_fade_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await settle.finished

	_reset_display()
	_restore_music()
	busy = false


# A bin hit keeps the number unchanged and gives it a quick relief pulse.
func play_refund_relief() -> void:
	if busy:
		return

	busy = true
	idle_time = 0.0
	_reset_display()

	if refund_sfx:
		SfxPlayer.play(refund_sfx)

	_burst_refund_stars(main_label.get_global_rect().get_center())
	_start_shake(
		refund_screen_shake_duration,
		refund_screen_shake
	)

	var old_modulate := display_root.modulate
	var refund_colour := refund_star_template.color
	var pulse := create_tween()

	pulse.tween_property(
		display_root,
		"scale",
		base_scale * 1.08,
		refund_duration * 0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.parallel().tween_property(
		display_root,
		"modulate",
		refund_colour,
		refund_duration * 0.45
	)
	pulse.tween_property(
		display_root,
		"scale",
		base_scale,
		refund_duration * 0.55
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.parallel().tween_property(
		display_root,
		"modulate",
		old_modulate,
		refund_duration * 0.55
	)

	await pulse.finished

	display_root.modulate = old_modulate
	_reset_display()
	busy = false


func _prepare_number(
	label: Label,
	value: String,
	colour: Color,
	rect: Rect2
) -> void:
	label.text = value
	label.size = rect.size
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", colour)


func _copy_label_style(label: Label) -> void:
	label.horizontal_alignment = main_label.horizontal_alignment
	label.vertical_alignment = main_label.vertical_alignment
	label.theme = main_label.theme
	label.theme_type_variation = main_label.theme_type_variation
	label.add_theme_font_override("font", main_label.get_theme_font("font"))
	label.add_theme_font_size_override(
		"font_size",
		main_label.get_theme_font_size("font_size")
	)
	label.add_theme_color_override(
		"font_outline_color",
		main_label.get_theme_color("font_outline_color")
	)
	label.add_theme_constant_override(
		"outline_size",
		main_label.get_theme_constant("outline_size")
	)


func _throw_stars(from: Vector2, to: Vector2, intensity: float) -> void:
	var count := int(round(lerpf(7.0, 18.0, intensity)))

	for index in range(count):
		var star := travelling_star_template.duplicate() as Polygon2D
		if not star:
			continue

		star.position = from + Vector2(
			randf_range(-12.0, 12.0),
			randf_range(-12.0, 12.0)
		)
		star.scale = Vector2.ONE * randf_range(0.7, 1.25)
		star.modulate = Color.WHITE
		star.show()
		star_effects.add_child(star)

		var destination := to + Vector2(
			randf_range(-10.0, 10.0),
			randf_range(-10.0, 10.0)
		)
		var duration := anticipation_duration + impact_duration
		var flight := create_tween()

		flight.tween_interval(index * 0.012)
		flight.tween_property(
			star,
			"position",
			destination,
			duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.parallel().tween_property(
			star,
			"rotation",
			randf_range(-TAU, TAU),
			duration
		)
		flight.parallel().tween_property(
			star,
			"scale",
			Vector2.ONE * 0.15,
			duration
		)
		flight.finished.connect(star.queue_free)


func _burst_refund_stars(center: Vector2) -> void:
	for index in range(8):
		var star := refund_star_template.duplicate() as Polygon2D
		if not star:
			continue

		var angle := TAU * index / 8.0
		var destination := (
			center
			+ Vector2.RIGHT.rotated(angle) * randf_range(24.0, 42.0)
		)

		star.position = center
		star.scale = Vector2.ONE
		star.modulate = Color.WHITE
		star.show()
		star_effects.add_child(star)

		var burst := create_tween().set_parallel()
		burst.tween_property(
			star,
			"position",
			destination,
			refund_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst.tween_property(
			star,
			"modulate:a",
			0.0,
			refund_duration
		)
		burst.tween_property(
			star,
			"rotation",
			angle + PI,
			refund_duration
		)
		burst.finished.connect(star.queue_free)


func _play_shockwave(
	center: Vector2,
	new_count: int,
	intensity: float
) -> void:
	shockwave.position = center
	shockwave.scale = Vector2.ONE
	shockwave.modulate = Color.WHITE
	shockwave.width = lerpf(2.0, 5.0, intensity)
	shockwave.default_color = _count_colour(new_count, maximum_count)
	shockwave.show()

	var wave := create_tween().set_parallel()
	wave.tween_property(
		shockwave,
		"scale",
		Vector2.ONE * 2.6,
		settle_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wave.tween_property(
		shockwave,
		"modulate:a",
		0.0,
		settle_duration
	)
	wave.finished.connect(shockwave.hide)


func _flash(intensity: float) -> void:
	impact_flash.color = flash_colour
	impact_flash.color.a = lerpf(0.1, 0.3, intensity)

	var tween := create_tween()
	tween.tween_property(
		impact_flash,
		"color:a",
		0.0,
		flash_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _start_shake(duration: float, strength: float) -> void:
	if not (get_parent() is Node2D):
		return

	shake_target = get_parent() as Node2D
	shake_start_position = shake_target.position
	shaking = true
	_run_shake(duration, strength)


func _run_shake(duration: float, strength: float) -> void:
	var elapsed := 0.0
	var safe_duration := maxf(duration, 0.001)

	while elapsed < safe_duration and shaking and is_instance_valid(shake_target):
		await get_tree().process_frame
		elapsed += get_process_delta_time()

		var fade := 1.0 - elapsed / safe_duration
		var amount := strength * fade
		shake_target.position = shake_start_position + Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)

	_stop_shake()


func _stop_shake() -> void:
	if shaking and is_instance_valid(shake_target):
		shake_target.position = shake_start_position

	shaking = false
	shake_target = null


func _aim_cannon_at_counter() -> void:
	var cannon := get_parent().get_node_or_null("PeggleBallShooter")
	if cannon and cannon.has_method("aim_at"):
		cannon.call(
			"aim_at",
			main_label.get_global_rect().get_center(),
			false,
			false
		)


func _play_countdown_sound(intensity: float) -> void:
	var sound := countdown_tick_sfx

	if intensity >= 0.7 and critical_tick_sfx:
		sound = critical_tick_sfx

	if sound:
		SfxPlayer.play(sound)


func _play_miss_burst_sound() -> void:
	if miss_burst_sfx:
		SfxPlayer.play(miss_burst_sfx)


func _flicker_count_labels() -> void:
	if main_flicker_tween:
		main_flicker_tween.kill()

	if remaining_flicker_tween:
		remaining_flicker_tween.kill()

	if flicker_sound_tween:
		flicker_sound_tween.kill()

	_stop_remaining_flicker_sound()

	main_label.modulate.a = 0.0
	remaining_label.modulate.a = 0.0
	_play_remaining_flicker_sound()

	var main_flickers: Array[Vector2] = [
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

	var remaining_flickers: Array[Vector2] = [
		Vector2(0.15, 0.03),
		Vector2(0.95, 0.09),
		Vector2(0.20, 0.05),
		Vector2(0.75, 0.04),
		Vector2(0.05, 0.08),
		Vector2(1.00, 0.06),
		Vector2(0.35, 0.04),
		Vector2(0.90, 0.07),
		Vector2(0.12, 0.05),
		Vector2(1.00, 0.14),
	]

	main_flicker_tween = _make_flicker_tween(
		main_label,
		main_flickers,
		0.0
	)
	remaining_flicker_tween = _make_flicker_tween(
		remaining_label,
		remaining_flickers,
		0.035
	)

	var main_duration := _get_flicker_duration(
		main_flickers,
		0.0
	)
	var remaining_duration := _get_flicker_duration(
		remaining_flickers,
		0.035
	)

	flicker_sound_tween = create_tween()
	flicker_sound_tween.tween_interval(
		maxf(
			main_duration,
			remaining_duration
		)
		+ remaining_sound_tail_duration
	)
	flicker_sound_tween.finished.connect(
		_stop_remaining_flicker_sound
	)


func _make_flicker_tween(
	target: CanvasItem,
	flickers: Array[Vector2],
	start_delay: float
) -> Tween:
	var tween := create_tween()

	if start_delay > 0.0:
		tween.tween_interval(
			start_delay
		)

	for flicker in flickers:
		tween.tween_property(
			target,
			"modulate:a",
			flicker.x,
			flicker.y / remaining_flicker_speed
		)

	tween.tween_property(
		target,
		"modulate:a",
		1.0,
		0.08 / remaining_flicker_speed
	)

	return tween


func _get_flicker_duration(
	flickers: Array[Vector2],
	start_delay: float
) -> float:
	var duration := start_delay

	for flicker in flickers:
		duration += (
			flicker.y / remaining_flicker_speed
		)

	duration += (
		0.08 / remaining_flicker_speed
	)

	return duration


func _play_remaining_flicker_sound() -> void:
	if not remaining_flicker_sound:
		return

	SfxPlayer.play(
		remaining_flicker_sound,
		false,
		false,
		0.5,
		false,
		remaining_flicker_volume_db,
		0.5,
		false,
		true
	)


func _stop_remaining_flicker_sound() -> void:
	if remaining_flicker_sound:
		SfxPlayer.stop_audio(
			remaining_flicker_sound
		)


func _duck_music() -> void:
	if music_bus_index < 0 or music_is_ducked:
		return

	old_music_volume = AudioServer.get_bus_volume_db(music_bus_index)
	AudioServer.set_bus_volume_db(
		music_bus_index,
		old_music_volume + music_duck_db
	)
	music_is_ducked = true


func _restore_music() -> void:
	if not music_is_ducked:
		return

	if music_bus_index >= 0:
		AudioServer.set_bus_volume_db(music_bus_index, old_music_volume)

	music_is_ducked = false


func _set_vignette_focus(screen_position: Vector2) -> void:
	if not vignette_material:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	vignette_material.set_shader_parameter(
		"focus",
		Vector2(
			screen_position.x / viewport_size.x,
			screen_position.y / viewport_size.y
		)
	)


func _clamp_to_viewport(screen_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	return Vector2(
		clampf(screen_position.x, 0.0, viewport_size.x),
		clampf(screen_position.y, 0.0, viewport_size.y)
	)


func _impact_intensity(count: int, maximum: int) -> float:
	var fraction := _remaining_fraction(count, maximum)

	if count <= 0:
		return 1.0
	if count == 1:
		return 0.95
	if fraction <= 0.10:
		return 0.85
	if fraction <= 0.30:
		return 0.65
	if fraction <= 0.60:
		return 0.42
	return 0.22


func _remaining_fraction(count: int, maximum: int) -> float:
	if maximum <= 0:
		return 0.0
	return clampf(float(count) / float(maximum), 0.0, 1.0)


func _count_colour(count: int, maximum: int) -> Color:
	var fraction := _remaining_fraction(count, maximum)

	if fraction <= critical_threshold:
		return critical_colour
	if fraction <= warning_threshold:
		return warning_colour
	return normal_colour


func _text_as_number() -> int:
	if main_label.text.is_valid_int():
		return main_label.text.to_int()
	return 0


func _update_remaining_text() -> void:
	if displayed_count == 1:
		remaining_label.text = "Planet remains"
	else:
		remaining_label.text = "Planets remain"


func _reset_display() -> void:
	display_root.position = base_position
	display_root.scale = base_scale
	display_root.rotation = base_rotation


func _update_pivots() -> void:
	main_label.pivot_offset = main_label.size / 2.0
	display_root.pivot_offset = display_root.size / 2.0
