extends Node

signal dialogue_mood_triggered(
	mood_index: int,
	dialogue_level: int
)

signal dialogue_level_triggered(level: int)
signal dialogue_next

signal balls_left_percentage_changed(
	percentage: float
)

signal celestial_body_explosion_triggered(
	body_id: StringName
)
