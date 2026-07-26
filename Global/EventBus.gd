extends Node


const IDLE_EMOTION_INDEX: int = -1


# Gameplay character animation signals.
# These never control dialogue.
signal bin_emotion_triggered(
	emotion_index: int
)

signal bin_emotion_cleared


# Story dialogue character animation signal.
signal dialogue_line_emotion_triggered(
	alignment: StringName,
	emotion_index: int
)


# Dialogue signals.
signal dialogue_mood_triggered(
	mood_index: int,
	dialogue_level: int
)

signal dialogue_mood_hide

signal dialogue_level_triggered(
	level: int
)

signal dialogue_next


# Gameplay signals.
signal balls_left_percentage_changed(
	percentage: float
)

signal celestial_body_explosion_triggered(
	body_id: StringName
)

signal peg_hit_sound_update
signal reset_button_pressed
