extends Node


signal dialogue_closed
signal level_dialogue_closed
signal level_dialogue_set_closed


const LEVEL_DIALOGUE_CHUNK_GAP: float = 0.2


var _dialogue_box_displayed: bool = false
var _dialogue_input_locked: bool = false

var _level_dialogue_sequence_running: bool = false


# Stores the most recently resolved alignment.
# Each DialogueBox still applies its own alignment
# locally and remains visually unchanged afterwards.
var current_dialogue_alignment: String = "right"


# These are the conversations that play before
# each level begins.
#
# Levels 2 to 4 contain two sets. Calling
# play_level_dialogue_sequence() plays set 1,
# then set 2, before emitting level_dialogue_closed.
#
# Level 5 contains only its pre-game conversation.
# Its post-win conversation is stored separately.
var dialogue_level_sets: Dictionary = {
	1: [
		# INTRO: FIRST ISOLATED LINE
		[
			{
				"align": "left",
				"text": "There you are! How can you erase most of the universe and still be so hard to find?"
			},
		],

		# INTRO: REMAINDER OF SET 1
		[
			{
				"align": "right",
				"text": "I found a stray meteor drifting through the Xal'Thari sector that just had to go. But I'm here now."
			},
			{
				"align": "left",
				"text": "I see. So... can we hang out for a while?"
			},
			{
				"align": "right",
				"text": "We could play something in the arcade I kept for you. How about that one, until you win five times?"
			},
			{
				"align": "left",
				"text": "Okay. That one's new. How does it work?"
			},
		],

		# INTRO: SET 2
		[
			{
				"align": "right",
				"text": "It's a special machine I made for you. It links our emotions, so you can understand me a bit better."
			},
			{
				"align": "right",
				"text": "We take turns shooting orbs. Every peg you hit becomes yours, and vice versa, until one of us owns three quarters of the board."
			},
			{
				"align": "left",
				"text": "Any stakes? What happens if we run out of orbs?"
			},
			{
				"align": "right",
				"text": "Every orb is a planet. Miss the emotion-link bins at the bottom, and that planet is gone."
			},
			{
				"align": "right",
				"text": "Hit the right emotion and you get a power-up. And if we run out, it's over. A countdown to the end."
			},
		],
	],

	2: [
		# LEVEL 2: SET 1
		[
			{
				"align": "left",
				"text": "So, what happens if I win every round?"
			},
			{
				"align": "right",
				"text": "Then we get to spend one more day together."
			},
			{
				"align": "left",
				"text": "Only one more? Why not longer?!"
			},
			{
				"align": "right",
				"text": "Because my very existence means I have to keep ending things."
			},
			{
				"align": "left",
				"text": "I know, but there has to be some way to keep this going..."
			},
		],

		# LEVEL 2: SET 2
		[
			{
				"align": "left",
				"text": "Uh... we could start fishing in black holes again? Didn't that work that one time?"
			},
			{
				"align": "right",
				"text": "There aren't any left."
			},
			{
				"align": "left",
				"text": "What if you cut the planets in half?"
			},
			{
				"align": "right",
				"text": "They wouldn't bounce as well."
			},
			{
				"align": "left",
				"text": "Okay... a few more games, then?"
			},
		],
	],

	3: [
		# LEVEL 3: SET 1
		[
			{
				"align": "left",
				"text": "So many more planets are gone now..."
			},
			{
				"align": "right",
				"text": "It's not as though your family was on any of those."
			},
			{
				"align": "left",
				"text": "You can't say things like that."
			},
			{
				"align": "right",
				"text": "Why not? They've been gone for eons."
			},
			{
				"align": "left",
				"text": "Because... I wish... YOU WOULD JUST STOP WITH THIS NONSENSE!"
			},
		],

		# LEVEL 3: SET 2
		[
			{
				"align": "right",
				"text": "That's not how this works. You should know that."
			},
			{
				"align": "right",
				"text": "This cannot be stopped. Not by you. Not by me. It's inevitable."
			},
			{
				"align": "left",
				"text": "THEN WHY NOT JUST END IT ALREADY?"
			},
			{
				"align": "right",
				"text": "BECAUSE I AM NOT READY TO SAY GOODBYE YET."
			},
			{
				"align": "left",
				"text": "..."
			},
		],
	],

	4: [
		# LEVEL 4: SET 1
		[
			{
				"align": "left",
				"text": "Hey, so... I'm not ready to say goodbye yet either."
			},
			{
				"align": "right",
				"text": "...I suppose I just don't know what will be left after this."
			},
			{
				"align": "right",
				"text": "Everything will be gone. Everyone will be dead. We won't be able to talk anymore."
			},
			{
				"align": "left",
				"text": "Oh... I didn't think you actually cared."
			},
			{
				"align": "right",
				"text": "..."
			},
		],

		# LEVEL 4: SET 2
		[
			{
				"align": "right",
				"text": "Soon, everything will be gone. Everyone will be dead."
			},
			{
				"align": "left",
				"text": "..."
			},
			{
				"align": "right",
				"text": "But you'll remain. I won't let you disappear."
			},
			{
				"align": "left",
				"text": "...But that's so cruel."
			},
			{
				"align": "right",
				"text": "I just don't want to be alone."
			},
		],
	],

	5: [
		# LEVEL 5: PRE-GAME SET
		[
			{
				"align": "left",
				"text": "So, if I win this round, we get another day?"
			},
			{
				"align": "right",
				"text": "And I won't have to erase anything else today."
			},
			{
				"align": "left",
				"text": "Are you sure?"
			},
			{
				"align": "right",
				"text": "Yes. Thank you for not losing all the planets yet."
			},
			{
				"align": "left",
				"text": "Thank you for telling me how you felt."
			},
		],
	],
}


# Dialogue that plays only after winning its level.
# This is kept separate so it does not play before
# the final round begins.
var post_win_dialogue_sets: Dictionary = {
	5: [
		{
			"align": "right",
			"text": "Maybe we can play something else until tomorrow."
		},
		{
			"align": "left",
			"text": "That would be nice."
		},
		{
			"align": "right",
			"text": "Every second we spend together is nice."
		},
		{
			"align": "left",
			"text": "But what do we do when we play for the final world?"
		},
		{
			"align": "right",
			"text": "Enjoy it."
		},
	],
}


# Contains the currently active flat dialogue set.
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
		"You didn't even leave a scratch!",
		"Uhhhh... meee-ow?",
		"I shudder to imagine how you'll one-up that!",
		"Beat that, kitten!",
		"You think I should diversify my puns? I'm starting to think I'm all bark and no bite!",
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


# Returns the alignment for one specific line.
# It does not emit a global signal, so existing
# dialogue boxes retain their original appearance.
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

		return entry_alignment

	# Mood dialogue and unknown text use the
	# right-side appearance.
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


# Plays dialogue stored in post_win_dialogue_sets.
# It does not emit level_dialogue_closed because
# gameplay must not resume after the final ending.
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
