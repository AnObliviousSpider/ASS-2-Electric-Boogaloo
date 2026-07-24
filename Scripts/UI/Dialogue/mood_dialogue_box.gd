extends Control

@export var on_display_audio : AudioStream
@export var on_text_audio : AudioStream

@export_subgroup("Child Nodes")
@export var dialogue_box: DialogueBox

func _ready() -> void:
	self.visible = true
	EventBus.dialogue_mood_triggered.connect(_on_dialogue_mood_triggered)
	# hide dialogue box on ready
	dialogue_box.instant_hide_dialogue()
	if on_display_audio:
		dialogue_box.on_display_audio = on_display_audio
	if on_text_audio:
		dialogue_box.on_text_audio = on_text_audio

func _on_dialogue_mood_triggered(mood_index: int, level: int) -> void:
	DialogueManager.open_dialogue()
	# Dialogue system for mood mode
	var mood : String = GameData.emotions.keys()[mood_index]
	if mood in DialogueManager.dialogue_moods.keys():
		var dialogue : String = DialogueManager.dialogue_moods[mood].pick_random()
		dialogue_box.display_dialogue(dialogue)
		await EventBus.dialogue_next
		dialogue_box.hide_dialogue()
		DialogueManager.close_dialogue()
	else:
		printerr("Mood: ", mood, " not in dialogue_moods dictionary")
