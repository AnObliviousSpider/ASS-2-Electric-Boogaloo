extends Node


signal dialogue_closed
signal level_dialogue_closed
signal level_dialogue_set_closed


const LEVEL_DIALOGUE_CHUNK_GAP: float = 0.2


var _dialogue_box_displayed: bool = false
var _dialogue_input_locked: bool = false
var _level_dialogue_sequence_running: bool = false


var current_dialogue_alignment: String = "right"


var dialogue_level_sets: Dictionary = {
	1: [
		# INTRO: FIRST ISOLATED LINE
		[
			{
				"align": "left",
				"emotion": "Angry",
				"text": "There you are! How can you erase most of the universe and still be so hard to find?"
			},
		],

		# INTRO: REMAINDER OF SET 1
		[
			{
				"align": "right",
				"emotion": "Idle",
				"text": "I found a stray meteor drifting through the Xal Thari sector that just had to go. But I am here now."
			},
			{
				"align": "left",
				"emotion": "Flirty",
				"text": "I see. So... can we hang out for a while?"
			},
			{
				"align": "right",
				"emotion": "Happy",
				"text": "We could play something in the arcade I kept for you. How about that one, until you win five times?"
			},
			{
				"align": "left",
				"emotion": "Idle",
				"text": "Okay. That one is new. How does it work?"
			},
		],

		# INTRO: SET 2
		[
			{
				"align": "right",
				"emotion": "Flirty",
				"text": "It is a special machine I made for you. It links our emotions, so you can understand me a bit better."
			},
			{
				"align": "right",
				"emotion": "Idle",
				"text": "We take turns shooting orbs. Every peg you hit becomes yours, and vice versa, until one of us owns three quarters of the board."
			},
			{
				"align": "left",
				"emotion": "Idle",
				"text": "Any stakes? What happens if we run out of orbs?"
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "Every orb is a planet. Miss the emotion link bins at the bottom, and that planet is gone."
			},
			{
				"align": "right",
				"emotion": "Idle",
				"text": "Hit the right emotion and you get a power up. And if we run out, it is over. A countdown to the end."
			},
		],
	],

	2: [
		# LEVEL 2: SET 1
		[
			{
				"align": "left",
				"emotion": "Idle",
				"text": "So, what happens if I win every round?"
			},
			{
				"align": "right",
				"emotion": "Flirty",
				"text": "Then we get to spend one more day together."
			},
			{
				"align": "left",
				"emotion": "Angry",
				"text": "Only one more? Why not longer?!"
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "Because my very existence means I have to keep ending things."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "I know, but there has to be some way to keep this going..."
			},
		],

		# LEVEL 2: SET 2
		[
			{
				"align": "left",
				"emotion": "Happy",
				"text": "Uh... we could start fishing in black holes again? Did that not work that one time?"
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "There are not any left."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "What if you cut the planets in half?"
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "They would not bounce as well."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "Okay... a few more games, then?"
			},
		],
	],

	3: [
		# LEVEL 3: SET 1
		[
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "So many more planets are gone now..."
			},
			{
				"align": "right",
				"emotion": "Angry",
				"text": "It is not as though your family was on any of those."
			},
			{
				"align": "left",
				"emotion": "Angry",
				"text": "You cannot say things like that."
			},
			{
				"align": "right",
				"emotion": "Angry",
				"text": "Why not? They have been gone for eons."
			},
			{
				"align": "left",
				"emotion": "Angry",
				"text": "Because... I wish... YOU WOULD JUST STOP WITH THIS NONSENSE!"
			},
		],

		# LEVEL 3: SET 2
		[
			{
				"align": "right",
				"emotion": "Angry",
				"text": "That is not how this works. You should know that."
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "This cannot be stopped. Not by you. Not by me. It is inevitable."
			},
			{
				"align": "left",
				"emotion": "Angry",
				"text": "THEN WHY NOT JUST END IT ALREADY?"
			},
			{
				"align": "right",
				"emotion": "Angry",
				"text": "BECAUSE I AM NOT READY TO SAY GOODBYE YET."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "..."
			},
		],
	],

	4: [
		# LEVEL 4: SET 1
		[
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "Hey, so... I am not ready to say goodbye yet either."
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "...I suppose I just do not know what will be left after this."
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "Everything will be gone. Everyone will be dead. We will not be able to talk anymore."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "Oh... I did not think you actually cared."
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "..."
			},
		],

		# LEVEL 4: SET 2
		[
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "Soon, everything will be gone. Everyone will be dead."
			},
			{
				"align": "left",
				"emotion": "Idle",
				"text": "..."
			},
			{
				"align": "right",
				"emotion": "Flirty",
				"text": "But you will remain. I will not let you disappear."
			},
			{
				"align": "left",
				"emotion": "Dejected",
				"text": "...But that is so cruel."
			},
			{
				"align": "right",
				"emotion": "Dejected",
				"text": "I just do not want to be alone."
			},
		],
	],

	5: [
		# LEVEL 5: PRE GAME SET
		[
			{
				"align": "left",
				"emotion": "Idle",
				"text": "So, if I win this round, we get another day?"
			},
			{
				"align": "right",
				"emotion": "Happy",
				"text": "And I will not have to erase anything else today."
			},
			{
				"align": "left",
				"emotion": "Idle",
				"text": "Are you sure?"
			},
			{
				"align": "right",
				"emotion": "Happy",
				"text": "Yes. Thank you for not losing all the planets yet."
			},
			{
				"align": "left",
				"emotion": "Flirty",
				"text": "Thank you for telling me how you felt."
			},
		],
	],
}


var post_win_dialogue_sets: Dictionary = {
	5: [
		{
			"align": "right",
			"emotion": "Idle",
			"text": "Maybe we can play something else until tomorrow."
		},
		{
			"align": "left",
			"emotion": "Happy",
			"text": "That would be nice."
		},
		{
			"align": "right",
			"emotion": "Flirty",
			"text": "Every second we spend together is nice."
		},
		{
			"align": "left",
			"emotion": "Dejected",
			"text": "But what do we do when we play for the final world?"
		},
		{
			"align": "right",
			"emotion": "Idle",
			"text": "Enjoy it."
		},
	],
}


var dialogue_levels: Dictionary = {}


var dialogue_moods: Dictionary = {
	"Happy": [
		"Oh my, what a round!",
		"There are plenty more stars where that came from.",
		"Did you know there are holes in reality AND doughnuts?",
		"The universe may have been made last Thursday, and you would not know any better.",
		"The day you will fulfil your destiny is soon. That day is Pancake Day. Please, can we get pancakes next?",
		"Do not worry about it. Things break all the time. Planets, stars and stuff.",
		"Again! Again!",
	],

	"Flirty": [
		"You made me think of another game we can play later.",
		"I am surprised you could last this many rounds against me.",
		"This game is fun, but not as fun as you are.",
		"When you humans look up, you always think we look back. I only do that when it is you.",
		"The sky once called to me. I went. It was pretty cool. You are cooler, though.",
		"Do not worry about it. Things break all the time. Planets, stars and you~",
		"You shine brighter than any star I have seen.",
		"Space monkeys are so fun when they are trained properly...",
		"I would knock something random off the counter for you. Then scratch your furniture. Then... never mind.",
	],

	"Angry": [
		"Ridiculous... There is no way you got that many.",
		"Hey, stop messing around with those.",
		"Why are you trying to end things so fast?",
		"The silent treatment? How mature of you.",
		"What makes you think I wanted to hear that right now?",
	],

	"Dejected": [
		"Do not think about it, my love. Just play.",
		"Another globe gone, then.",
		"Stalling your round would not change much.",
		"There are only so many rounds left for us to play.",
		"Sometimes I can hardly hear my favourite little space monkey...",
		"At least this will be a very chill reality...",
		"Well, the cat is out of the bag now.",
	],

	"Missed": [
		"Phew, I was foaming at the Meowth.",
		"You did not even leave a scratch!",
		"Uhhhh... meee ow?",
		"I shudder to imagine how you will one up that!",
		"Beat that, kitten!",
		"You think I should diversify my puns? I am starting to think I am all bark and no bite!",
	],
}


func _ready() -> void:
	_prepare_first_dialogue_sets()


func can_accept_dialogue_input() -> bool:
	return (
		_dialogue_box_displayed
		and not _dialogue_input_locked
	)


func _prepare_first_dialogue_sets() -> void:
	for level_variant: Variant in dialogue_level_sets.keys():
		var level_number: int = int(
			level_variant
		)

		var level_sets: Array = dialogue_level_sets.get(
			level_number,
			[]
		)

		if level_sets.is_empty():
			dialogue_levels[level_number] = []
			continue

		var first_set: Array = (
			level_sets[0] as Array
		)

		dialogue_levels[level_number] = (
			first_set.duplicate(
				true
			)
		)


func _get_level_dialogue_set(
	level_number: int,
	set_index: int
) -> Array:
	var level_sets: Array = dialogue_level_sets.get(
		level_number,
		[]
	)

	if level_sets.is_empty():
		return []

	if (
		set_index < 0
		or set_index >= level_sets.size()
	):
		push_warning(
			"Invalid dialogue set index %s for level %s."
			% [
				set_index,
				level_number,
			]
		)

		return []

	return (
		level_sets[set_index] as Array
	)


func _load_level_dialogue_set(
	level_number: int,
	set_index: int
) -> bool:
	var dialogue_set: Array = _get_level_dialogue_set(
		level_number,
		set_index
	)

	if dialogue_set.is_empty():
		return false

	dialogue_levels[level_number] = (
		dialogue_set.duplicate(
			true
		)
	)

	return true


func _load_post_win_dialogue_set(
	level_number: int
) -> bool:
	var dialogue_set: Array = (
		post_win_dialogue_sets.get(
			level_number,
			[]
		)
	)

	if dialogue_set.is_empty():
		return false

	dialogue_levels[level_number] = (
		dialogue_set.duplicate(
			true
		)
	)

	return true


func get_alignment_for_dialogue_text(
	dialogue_text: String
) -> String:
	var level_number: int = (
		LevelManager.level
	)

	var active_dialogue: Array = dialogue_levels.get(
		level_number,
		[]
	)

	for entry_variant: Variant in active_dialogue:
		if not entry_variant is Dictionary:
			continue

		var dialogue_entry: Dictionary = (
			entry_variant as Dictionary
		)

		var entry_text: String = str(
			dialogue_entry.get(
				"text",
				""
			)
		)

		if entry_text != dialogue_text:
			continue

		var entry_alignment: String = str(
			dialogue_entry.get(
				"align",
				"right"
			)
		)

		entry_alignment = (
			entry_alignment
				.strip_edges()
				.to_lower()
		)

		if entry_alignment != "left":
			entry_alignment = "right"

		current_dialogue_alignment = (
			entry_alignment
		)

		var emotion_name: String = str(
			dialogue_entry.get(
				"emotion",
				"Idle"
			)
		)

		var emotion_index: int = (
			EventBus.IDLE_EMOTION_INDEX
		)

		if emotion_name.to_lower() != "idle":
			if not GameData.emotions.has(
				emotion_name
			):
				push_warning(
					"Unknown dialogue emotion: %s"
					% emotion_name
				)

				emotion_name = "Happy"

			emotion_index = int(
				GameData.emotions.get(
					emotion_name,
					0
				)
			)

		EventBus.dialogue_line_emotion_triggered.emit(
			StringName(
				entry_alignment
			),
			emotion_index
		)

		return entry_alignment

	current_dialogue_alignment = "right"

	return "right"


func _trigger_fresh_level_dialogue(
	level_number: int
) -> void:
	_dialogue_box_displayed = false
	_dialogue_input_locked = true

	await get_tree().process_frame

	_dialogue_input_locked = false

	EventBus.dialogue_level_triggered.emit(
		level_number
	)


func play_level_dialogue_set(
	level_number: int,
	set_index: int
) -> void:
	if LevelManager.level != level_number:
		return

	if not _load_level_dialogue_set(
		level_number,
		set_index
	):
		return

	await _trigger_fresh_level_dialogue(
		level_number
	)

	await level_dialogue_set_closed

	await get_tree().create_timer(
		LEVEL_DIALOGUE_CHUNK_GAP
	).timeout


func restart_level_dialogue_from_set(
	level_number: int,
	set_index: int,
	close_level_after: bool = true
) -> void:
	if LevelManager.level != level_number:
		return

	_level_dialogue_sequence_running = false

	_dialogue_box_displayed = false
	_dialogue_input_locked = true

	dialogue_levels[level_number] = []

	current_dialogue_alignment = "right"

	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(
		LEVEL_DIALOGUE_CHUNK_GAP
	).timeout

	if LevelManager.level != level_number:
		return

	if not _load_level_dialogue_set(
		level_number,
		set_index
	):
		return

	_dialogue_box_displayed = false
	_dialogue_input_locked = false

	EventBus.dialogue_level_triggered.emit(
		level_number
	)

	await level_dialogue_set_closed

	await get_tree().create_timer(
		LEVEL_DIALOGUE_CHUNK_GAP
	).timeout

	if close_level_after:
		level_dialogue_closed.emit()


func play_level_dialogue_sequence(
	level_number: int,
	start_set_index: int = 0
) -> void:
	if _level_dialogue_sequence_running:
		return

	var level_sets: Array = dialogue_level_sets.get(
		level_number,
		[]
	)

	if level_sets.is_empty():
		level_dialogue_closed.emit()
		return

	var safe_start_index: int = clampi(
		start_set_index,
		0,
		level_sets.size()
	)

	_level_dialogue_sequence_running = true

	for set_index: int in range(
		safe_start_index,
		level_sets.size()
	):
		if LevelManager.level != level_number:
			_level_dialogue_sequence_running = false
			return

		await play_level_dialogue_set(
			level_number,
			set_index
		)

	_level_dialogue_sequence_running = false

	level_dialogue_closed.emit()


func play_post_win_dialogue(
	level_number: int
) -> void:
	if LevelManager.level != level_number:
		return

	_dialogue_box_displayed = false
	_dialogue_input_locked = true

	dialogue_levels[level_number] = []

	current_dialogue_alignment = "right"

	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(
		LEVEL_DIALOGUE_CHUNK_GAP
	).timeout

	if not _load_post_win_dialogue_set(
		level_number
	):
		return

	_dialogue_input_locked = false

	EventBus.dialogue_level_triggered.emit(
		level_number
	)

	await level_dialogue_set_closed

	await get_tree().create_timer(
		LEVEL_DIALOGUE_CHUNK_GAP
	).timeout


func open_dialogue() -> void:
	_dialogue_box_displayed = true


func close_dialogue() -> void:
	_dialogue_box_displayed = false
	_dialogue_input_locked = false

	dialogue_closed.emit()


func lock_dialogue() -> void:
	_dialogue_input_locked = true


func unlock_dialogue() -> void:
	_dialogue_input_locked = false


func force_close_dialogue() -> void:
	_dialogue_input_locked = false

	if not _dialogue_box_displayed:
		return

	close_dialogue()


func open_level_dialogue() -> void:
	_dialogue_box_displayed = true
	_dialogue_input_locked = false


func close_level_dialogue() -> void:
	_dialogue_box_displayed = false
	_dialogue_input_locked = false

	dialogue_closed.emit()
	level_dialogue_set_closed.emit()
