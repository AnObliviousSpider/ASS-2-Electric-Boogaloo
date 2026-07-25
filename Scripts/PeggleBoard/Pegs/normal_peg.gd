extends StaticBody2D


signal claim_changed


@onready var hit_area: Area2D = $Area2D

@onready var peg_sprite: AnimatedSprite2D = (
	$Sprite2D
)


# -1 means the peg is unclaimed.
var claimed_turn: int = -1
@export var destroy: bool = false
@export var dummy: bool = false

# VISUAL STATE

var starting_sprite_scale: Vector2
var starting_sprite_rotation: float


# TWEENS

var scale_tween: Tween
var rotation_tween: Tween


func _ready() -> void:
	destroy = true
	add_to_group(
		"pegs"
	)

	starting_sprite_scale = (
		peg_sprite.scale
	)

	starting_sprite_rotation = (
		peg_sprite.rotation
	)

	hit_area.body_entered.connect(
		change_peg_colour
	)

	peg_sprite.play(
		"default"
	)


func change_peg_colour(
	body: Node2D
) -> void:
	if body.get_meta(
		"is_peggle_ball",
		false
	) != true:
		return

	EventBus.peg_hit_sound_update.emit()

	var new_claimed_turn: int = int(
		body.get_meta(
			"turn_owner",
			-1
		)
	)

	if new_claimed_turn == -1:
		return

	var ball_owner: String = String(
		body.get_meta(
			"ball_owner",
			"default"
		)
	)

	peg_sprite.play(
		ball_owner
	)

	play_hit_animation()

	if claimed_turn == new_claimed_turn:
		return

	claimed_turn = new_claimed_turn

	play_claim_rotation()

	claim_changed.emit()

	#if destroy:
		#print("destroy yes")
		#await scale_tween.finished
		#queue_free()


func play_hit_animation() -> void:
	if scale_tween != null:
		if scale_tween.is_valid():
			scale_tween.kill()

		scale_tween = null

	# Reset before starting a new hit animation.
	peg_sprite.scale = starting_sprite_scale

	var enlarged_scale: Vector2 = (
		starting_sprite_scale * 1.15
	)

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
	if rotation_tween != null:
		if rotation_tween.is_valid():
			rotation_tween.kill()

		rotation_tween = null

	var rotation_amount: float = 90.0

	if claimed_turn == 0:
		rotation_amount = -90.0

	var target_rotation: float = (
		peg_sprite.rotation
			+ deg_to_rad(rotation_amount)
	)

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
	if scale_tween != null:
		if scale_tween.is_valid():
			scale_tween.kill()

		scale_tween = null

	if rotation_tween != null:
		if rotation_tween.is_valid():
			rotation_tween.kill()

		rotation_tween = null

	claimed_turn = -1

	peg_sprite.scale = (
		starting_sprite_scale
	)

	peg_sprite.rotation = (
		starting_sprite_rotation
	)

	peg_sprite.play(
		"default"
	)


func get_claimed_turn() -> int:
	return claimed_turn
