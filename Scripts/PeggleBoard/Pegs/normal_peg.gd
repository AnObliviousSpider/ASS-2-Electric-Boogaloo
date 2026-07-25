class_name PegglePeg extends StaticBody2D

signal claim_changed

@onready var hit_area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var peg_sprite: AnimatedSprite2D = $Sprite2D

var claimed_turn: int = -1
var hit_count: int = 0
var is_vanished: bool = false

@export var destroy: bool = false
@export var dummy: bool = false

var starting_sprite_scale: Vector2
var starting_sprite_rotation: float

var scale_tween: Tween
var rotation_tween: Tween


func _ready() -> void:
	destroy = true
	add_to_group("pegs")

	starting_sprite_scale = peg_sprite.scale
	starting_sprite_rotation = peg_sprite.rotation

	hit_area.body_entered.connect(change_peg_colour)
	peg_sprite.play("default")


func change_peg_colour(body: Node2D) -> void:
	if is_vanished:
		return

	if not body.get_meta("is_peggle_ball", false):
func change_peg_colour(
	body: Node2D
) -> void:
	if body.get_meta(
		"is_peggle_ball",
		false
	) != true and body is not BallExplosion:
		return

	EventBus.peg_hit_sound_update.emit()

	var new_claimed_turn: int = int(body.get_meta("turn_owner", -1))
	if new_claimed_turn == -1:
		return

	var ball_owner: String = String(body.get_meta("ball_owner", "default"))

	if claimed_turn == new_claimed_turn:
		hit_count += 1
		is_vanished = true

		hit_area.set_deferred("monitoring", false)
		collision_shape.set_deferred("disabled", true)

		play_hit_animation()

		if scale_tween != null and scale_tween.is_valid():
			await scale_tween.finished

		visible = false
		claim_changed.emit()
		return

	claimed_turn = new_claimed_turn
	hit_count = 1

	peg_sprite.play(ball_owner)

	play_hit_animation()
	play_claim_rotation()

	claim_changed.emit()


func play_hit_animation() -> void:
	if scale_tween != null and scale_tween.is_valid():
		scale_tween.kill()
		scale_tween = null

	peg_sprite.scale = starting_sprite_scale

	var enlarged_scale: Vector2 = starting_sprite_scale * 1.15

	scale_tween = create_tween()
	scale_tween.tween_property(
		peg_sprite,
		"scale",
		enlarged_scale,
		0.12
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	scale_tween.tween_property(
		peg_sprite,
		"scale",
		starting_sprite_scale,
		0.18
	).set_trans(
		Tween.TRANS_ELASTIC
	).set_ease(
		Tween.EASE_OUT
	)


func play_claim_rotation() -> void:
	if rotation_tween != null and rotation_tween.is_valid():
		rotation_tween.kill()
		rotation_tween = null

	var rotation_amount: float = 90.0
	if claimed_turn == 0:
		rotation_amount = -90.0

	var target_rotation: float = peg_sprite.rotation + deg_to_rad(rotation_amount)

	rotation_tween = create_tween()
	rotation_tween.tween_property(
		peg_sprite,
		"rotation",
		target_rotation,
		0.3
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)


func reset_peg() -> void:
	if scale_tween != null and scale_tween.is_valid():
		scale_tween.kill()
		scale_tween = null

	if rotation_tween != null and rotation_tween.is_valid():
		rotation_tween.kill()
		rotation_tween = null

	is_vanished = false
	visible = true
	collision_shape.disabled = false
	hit_area.monitoring = true

	claimed_turn = -1
	hit_count = 0

	peg_sprite.scale = starting_sprite_scale
	peg_sprite.rotation = starting_sprite_rotation
	peg_sprite.play("default")


func get_claimed_turn() -> int:
	return claimed_turn
