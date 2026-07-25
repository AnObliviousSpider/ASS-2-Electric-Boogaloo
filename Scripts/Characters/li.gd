extends Node2D


@onready var sprite_2d: Sprite2D = $Sprite2D


@export var textures: Dictionary[String, Texture2D] = {}


func _ready() -> void:
	if not EventBus.dialogue_mood_triggered.is_connected(
		change_sprite
	):
		EventBus.dialogue_mood_triggered.connect(
			change_sprite
		)


func change_sprite(
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
	)

	var new_texture: Texture2D = textures.get(
		mood_name
	) as Texture2D

	if new_texture == null:
		push_warning(
			"No Li texture assigned for mood: %s"
			% mood_name
		)
		return

	sprite_2d.texture = new_texture
