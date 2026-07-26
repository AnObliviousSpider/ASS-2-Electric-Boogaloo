extends AnimatedSprite2D

@export var firework_shot_sound: AudioStream
@export var firework_explode_sound: AudioStream

func _ready() -> void:
	await get_tree().create_timer(randf_range(0.0, 5.0)).timeout
	play("default")
	if firework_shot_sound == null:
		return
		
	SfxPlayer.play(firework_shot_sound, false, true, 0.3, true, 0.0, 1.0)


func _on_frame_changed() -> void:
	if firework_explode_sound == null:
		return
		
	if frame == 23:
		SfxPlayer.play(firework_explode_sound, false, true, 2, false, 0.0, 3.30)
