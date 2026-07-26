extends Control

var can_reset: bool = false

@onready var cooldown: Timer = $Cooldown
@onready var peggle_board: Node2D = %PeggleBoard

func _on_reset_btn_pressed() -> void:
	if not can_reset:
		return
	
	EventBus.reset_button_pressed.emit()
	
	can_reset = false
	visible = false

func _on_cooldown_timeout() -> void:
	if peggle_board.ball_in_play:
		can_reset = true
		visible = true
