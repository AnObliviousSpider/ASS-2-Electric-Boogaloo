extends Control

@export var on_display_audio : AudioStream
@export var on_text_audio : AudioStream

@export_subgroup("Child Nodes")
@export var dialogue_box: DialogueBox


var dialogue_moods: Dictionary = {
	"Happy": [
		"Im happy",
		"*happy noise*",
		"Yippyyyyy",
		"MATH IS FUN",
	],
	"Flirty": [
		"I lik u lowkey",
		"Are you Wi‑Fi? Because I’m feeling strong signals and zero common sense. (AI)",
		"How do i rizz someone",
		"touch grass? no. touch me (WHY IS MY AI FREAKY GAHDAMN)",
	],
	"Angry": [
		"BARK BARK BARK BARK GRRRRR",
		"D:<",
		"GRRRR BARK",
	],
	"Dejected": [
		"MC, I know we don't get along.. but I think I'm cooked.",
		"Um.. my rizz is on airplane mode. (AI GENERATED)",
	],
}

func _ready() -> void:
	self.visible = true
	EventBus.dialogue_mood_triggered.connect(_on_dialogue_mood_triggered)
	# hide dialogue box on ready
	dialogue_box.instant_hide_dialogue()
	if on_display_audio:
		dialogue_box.on_display_audio = on_display_audio
	if on_text_audio:
		dialogue_box.on_text_audio = on_text_audio

func _on_dialogue_mood_triggered(mood: String, level: int) -> void:
	DialogueManager.open_dialogue()
	# Dialogue system for mood mode
	if mood in dialogue_moods.keys():
		var dialogue : String = dialogue_moods[mood].pick_random()
		dialogue_box.display_dialogue(dialogue)
		await EventBus.dialogue_next
		dialogue_box.hide_dialogue()
		DialogueManager.close_dialogue()
	else:
		printerr("Mood: ", mood, " not in dialogue_moods dictionary")
