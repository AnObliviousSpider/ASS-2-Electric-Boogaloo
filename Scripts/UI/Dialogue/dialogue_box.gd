class_name DialogueBox
extends Control


@export_group("Timing")

@export var fade_in_time: float = 0.3
@export var fade_out_time: float = 0.3
@export var dialogue_speed: float = 0.06


@export_group("Audio")

@export var on_display_audio: AudioStream
@export var on_text_audio: AudioStream


@export_group("Dialogue Box Textures")

# Used when the left-aligned character speaks.
@export var left_dialogue_texture: Texture2D


@export_group("Dialogue Fonts")

@export var left_dialogue_font: Font
@export var right_dialogue_font: Font


@export_group("Child Nodes")

@export var dialogue_label: Label
@export var animation_player: AnimationPlayer


@onready var nine_patch_rect: NinePatchRect = (
	$NinePatchRect
)


var placeholder_text: String = (
	"placeholder text: if you see this something went wrong!"
)


# The texture already assigned in the Inspector
# is used for right-aligned dialogue.
var default_dialogue_texture: Texture2D


var typing_tween: Tween
var fade_tween: Tween

var dialogue_is_printing: bool = false

# Handles clicking while the box is still fading in,
# before the typing tween has been created.
var finish_printing_requested: bool = false


func _ready() -> void:
	default_dialogue_texture = (
		nine_patch_rect.texture
	)

	# Start with the normal right-side appearance.
	# Each line applies its own appearance when
	# display_dialogue is called.
	set_dialogue_alignment(
		"right"
	)


func _input(
	event: InputEvent
) -> void:
	if not event.is_action_pressed(
		"action_primary"
	):
		return

	if not visible:
		return

	if dialogue_label.text == placeholder_text:
		return

	if not DialogueManager.can_accept_dialogue_input():
		return

	# First click instantly reveals the
	# complete current line.
	if dialogue_is_printing:
		finish_dialogue_printing()

		get_viewport().set_input_as_handled()
		return

	# Second click advances to the next line.
	EventBus.dialogue_next.emit()

	get_viewport().set_input_as_handled()


func display_dialogue(
	dialogue: String,
	on_text_audio_override : AudioStream = null
) -> void:
	# This changes only this DialogueBox.
	# Other boxes no longer receive a global signal.
	var dialogue_alignment: String = (
		DialogueManager.get_alignment_for_dialogue_text(
			dialogue
		)
	)

	set_dialogue_alignment(
		dialogue_alignment
	)

	_cancel_typing_tween()

	finish_printing_requested = false
	dialogue_is_printing = true

	dialogue_label.text = dialogue
	dialogue_label.visible_ratio = 0.0

	animation_player.play(
		"RESET"
	)

	var dialogue_length: int = maxi(
		dialogue.length(),
		1
	)

	animation_player.speed_scale = (
		50.0 / float(dialogue_length)
	)

	await _fade_in(
		fade_in_time
	)

	# The player may have clicked while the
	# dialogue box was fading in.
	if finish_printing_requested:
		dialogue_label.visible_ratio = 1.0
		dialogue_is_printing = false
		return

	if on_text_audio_override:
		SfxPlayer.play(
			on_text_audio_override
		)
	elif on_text_audio != null:
		SfxPlayer.play(
			on_text_audio
		)

	typing_tween = create_tween()

	typing_tween.tween_property(
		dialogue_label,
		"visible_ratio",
		1.0,
		dialogue_speed * float(dialogue_length)
	)

	typing_tween.finished.connect(
		_on_typing_finished,
		CONNECT_ONE_SHOT
	)


func finish_dialogue_printing() -> void:
	if not dialogue_is_printing:
		return

	finish_printing_requested = true

	_cancel_typing_tween()

	dialogue_label.visible_ratio = 1.0
	dialogue_is_printing = false


func _on_typing_finished() -> void:
	typing_tween = null

	dialogue_label.visible_ratio = 1.0
	dialogue_is_printing = false


func _cancel_typing_tween() -> void:
	if typing_tween == null:
		return

	typing_tween.kill()
	typing_tween = null


func hide_dialogue() -> void:
	_cancel_typing_tween()

	dialogue_is_printing = false
	finish_printing_requested = false

	await _fade_out(
		fade_out_time
	)

	dialogue_label.text = placeholder_text
	dialogue_label.visible_ratio = 0.0


func instant_hide_dialogue() -> void:
	_cancel_typing_tween()

	dialogue_is_printing = false
	finish_printing_requested = false

	if fade_tween != null:
		fade_tween.kill()
		fade_tween = null

	dialogue_label.text = placeholder_text
	dialogue_label.visible_ratio = 0.0

	visible = false
	modulate.a = 0.0


func set_dialogue_alignment(
	alignment: String
) -> void:
	var normalised_alignment: String = (
		alignment.strip_edges().to_lower()
	)

	if normalised_alignment == "left":
		if left_dialogue_texture != null:
			nine_patch_rect.texture = (
				left_dialogue_texture
			)
		else:
			nine_patch_rect.texture = (
				default_dialogue_texture
			)

		dialogue_label.add_theme_color_override(
			"font_color",
			Color.BLACK
		)

		if left_dialogue_font != null:
			dialogue_label.add_theme_font_override(
				"font",
				left_dialogue_font
			)
		else:
			dialogue_label.remove_theme_font_override(
				"font"
			)

		return

	# Right-aligned dialogue uses the original
	# texture, white text and right-side font.
	nine_patch_rect.texture = (
		default_dialogue_texture
	)

	dialogue_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	if right_dialogue_font != null:
		dialogue_label.add_theme_font_override(
			"font",
			right_dialogue_font
		)
	else:
		dialogue_label.remove_theme_font_override(
			"font"
		)


func _fade_in(
	duration: float = 0.3
) -> void:
	if fade_tween != null:
		fade_tween.kill()

	if on_display_audio != null:
		SfxPlayer.play(
			on_display_audio
		)

	visible = true
	modulate.a = 0.0

	fade_tween = create_tween()

	fade_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		duration
	)

	await fade_tween.finished

	fade_tween = null


func _fade_out(
	duration: float = 0.3
) -> void:
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()

	fade_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		duration
	)

	await fade_tween.finished

	fade_tween = null
	visible = false
