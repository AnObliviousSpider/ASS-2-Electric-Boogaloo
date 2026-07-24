extends Control


@export var on_display_audio: AudioStream
@export var on_text_audio: AudioStream

@export_subgroup("Child Nodes")
@export var dialogue_boxes: Array[DialogueBox]

var in_level_dialogue: bool = false

func _ready() -> void:
	self.visible = true

	EventBus.dialogue_level_triggered.connect(
		_on_dialogue_level_triggered
	)

	for dialogue_box: DialogueBox in dialogue_boxes:
		dialogue_box.instant_hide_dialogue()

		if on_display_audio:
			dialogue_box.on_display_audio = on_display_audio

		if on_text_audio:
			dialogue_box.on_text_audio = on_text_audio


func _on_dialogue_level_triggered(level: int) -> void:
	if in_level_dialogue:
		return
	
	if DialogueManager._dialogue_box_displayed:
		DialogueManager.dialogue_closed.connect(
			func() -> void: display_level_dialogue(level),
			CONNECT_ONE_SHOT
		)
	else:
		display_level_dialogue(level)

func display_level_dialogue(level: int) -> void:
	EventBus.dialogue_mood_hide.emit()
	if not DialogueManager.dialogue_levels.has(level):
		push_error(
			"No level dialogue exists for level %s." % level
		)
		DialogueManager.open_level_dialogue()
		DialogueManager.close_level_dialogue()
		return

	in_level_dialogue = true
	DialogueManager.open_level_dialogue()

	var messages: Array = DialogueManager.dialogue_levels[level]

	for index: int in range(messages.size()):
		if index >= dialogue_boxes.size():
			printerr(
				"Not enough dialogue boxes for level dialogue."
			)
			break

		var message: Dictionary = messages[index]
		if message.align == "left":
			dialogue_boxes[index].size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if message.align == "right":
			dialogue_boxes[index].size_flags_horizontal = Control.SIZE_SHRINK_END
		dialogue_boxes[index].display_dialogue(message["text"])
		
		await EventBus.dialogue_next

	for dialogue_box: DialogueBox in dialogue_boxes:
		dialogue_box.hide_dialogue()

	DialogueManager.close_level_dialogue()
	in_level_dialogue = false
