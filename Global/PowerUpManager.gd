extends Node

signal trigger_power_up

# Power up types.
enum power_ups {
	ghost_ball,
	split_ball,
	blast_ball,
}

var active_power_up : power_ups

func set_triggered_power_up(power_up: power_ups) -> void:
	active_power_up = power_up
	print("triggered power up: ", power_up)
	trigger_power_up.emit()
