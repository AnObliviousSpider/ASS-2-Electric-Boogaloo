extends Control

func _on_reset_btn_pressed() -> void:
	EventBus.reset_button_pressed.emit()
