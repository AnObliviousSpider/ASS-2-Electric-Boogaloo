extends StaticBody2D


signal claim_changed


@export_group("Audio")

@export var peg_hit_sfx: AudioStream


@onready var hit_area: Area2D = $Area2D
@onready var peg_sprite: AnimatedSprite2D = $Sprite2D



# -1 means the peg is unclaimed.
var claimed_turn: int = -1

var tween = create_tween()

var tween_rotation = create_tween()

func _ready() -> void:
	add_to_group("pegs")

	hit_area.body_entered.connect(
		change_peg_colour
	)

	peg_sprite.play("default")


func change_peg_colour(body: Node2D) -> void:
	
	peg_sprite.stop()
	if body.get_meta(
		"is_peggle_ball",
		false
	) != true:
		return

	if peg_hit_sfx != null:
		SfxPlayer.play(
			peg_hit_sfx
		)

	var new_claimed_turn: int = int(
		body.get_meta(
			"turn_owner",
			-1
		)
	)

	if new_claimed_turn == -1:
		return

	peg_sprite.play(
		body.get_meta(
			"ball_owner",
			"default"
		)
	)
	
	tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.9,0.9), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	if claimed_turn == new_claimed_turn:
		return
	

	claimed_turn = new_claimed_turn
	
	if claimed_turn == 0:
		create_tween().tween_property(self, "rotation_degrees", -90, 0.3).as_relative()	
	else:
		create_tween().tween_property(self, "rotation_degrees", 90, 0.3).as_relative()	
	
	claim_changed.emit()


func reset_peg() -> void:
	claimed_turn = -1
	peg_sprite.play("default")


func get_claimed_turn() -> int:
	return claimed_turn
