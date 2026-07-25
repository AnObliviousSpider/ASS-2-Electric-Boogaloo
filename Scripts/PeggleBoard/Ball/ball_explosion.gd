class_name BallExplosion extends Area2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var scale_tween : Tween
var ball

func _ready() -> void:
	scale_tween = create_tween()
	scale_tween.tween_property(sprite_2d, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_EXPO)
	scale_tween.tween_callback(shrink_explostion)
	await get_tree().physics_frame
	await get_tree().physics_frame

	for body in self.get_overlapping_bodies():
		if body is PegglePeg:
			print("peg")
			body.change_peg_colour(ball)

func shrink_explostion() -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween = null
	scale_tween = create_tween()
	scale_tween.tween_property(sprite_2d, "scale", Vector2(0, 0), 1).set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_callback(self.queue_free)

func _on_area_2d_body_entered(body):
	print(body)
	if body == PegglePeg:
		print("The specific StaticBody2D entered.")
