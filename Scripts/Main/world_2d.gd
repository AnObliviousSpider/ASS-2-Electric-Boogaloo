extends Node2D


@export_group("Character Fades")

@export var main_character_fade_duration: float = 0.75
@export var li_fade_duration: float = 0.75


@onready var main_character: Node2D = (
	$MainCharacter
)

@onready var li: Node2D = (
	$Li
)


func _ready() -> void:
	# Begin with both characters invisible.
	main_character.modulate.a = 0.0
	li.modulate.a = 0.0

	main_character.show()
	li.show()

	# Give the dialogue interface time to connect
	# to the EventBus signals.
	await get_tree().create_timer(
		0.1
	).timeout

	# This controller only performs the special
	# level 1 introduction.
	if LevelManager.level != 1:
		main_character.modulate.a = 1.0
		li.modulate.a = 1.0
		return

	# Fade in the main character.
	await fade_in_character(
		main_character,
		main_character_fade_duration
	)

	# Level 1, chunk 0:
	# Main character's isolated opening line.
	await DialogueManager.play_level_dialogue_set(
		LevelManager.level,
		0
	)

	# Reveal Li after the opening line closes.
	await fade_in_character(
		li,
		li_fade_duration
	)

	# Level 1, chunk 1:
	# Remainder of the first conversation.
	await DialogueManager.play_level_dialogue_set(
		LevelManager.level,
		1
	)

	# Level 1, chunk 2:
	# Restart the dialogue UI and play the tutorial
	# conversation as a fresh set.
	await DialogueManager.restart_level_dialogue_from_set(
		LevelManager.level,
		2,
		true
	)


func fade_in_character(
	character: Node2D,
	duration: float
) -> void:
	character.show()
	character.modulate.a = 0.0

	var fade_tween: Tween = create_tween()

	fade_tween.tween_property(
		character,
		"modulate:a",
		1.0,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	await fade_tween.finished
