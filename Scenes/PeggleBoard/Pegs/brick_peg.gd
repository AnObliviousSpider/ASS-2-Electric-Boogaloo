extends StaticBody2D

signal claim_changed

@export var size: Vector2 = Vector2(24.0, 8.0)
@export var unclaimed_color: Color = Color.WHITE
@export var player_color: Color = Color(0.9, 0.2, 0.2)
@export var ai_color: Color = Color(0.2, 0.4, 0.9)

@onready var hit_area: Area2D = $Area2D
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var area_collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var visual_polygon: Polygon2D = $Polygon2D

var claimed_turn: int = -1

func _ready() -> void:
	add_to_group("pegs")
	hit_area.body_entered.connect(change_peg_colour)
	visual_polygon.color = unclaimed_color

	if collision_polygon.polygon.is_empty():
		setup_centered_box(size)


func setup_centered_box(box_size: Vector2) -> void:
	var half_w: float = box_size.x * 0.5
	var half_h: float = box_size.y * 0.5

	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	set_polygon(points)


func set_polygon(points: PackedVector2Array) -> void:
	collision_polygon.polygon = points
	area_collision_polygon.polygon = points
	visual_polygon.polygon = points
	_update_uvs()


func _update_uvs() -> void:
	if visual_polygon.polygon.size() != 4:
		return

	var tex_size: Vector2 = Vector2.ONE
	if visual_polygon.texture != null:
		tex_size = visual_polygon.texture.get_size()

	var uvs: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(tex_size.x, 0.0),
		Vector2(tex_size.x, tex_size.y),
		Vector2(0.0, tex_size.y)
	])
	visual_polygon.uv = uvs


func change_peg_colour(body: Node2D) -> void:
	if body.get_meta("is_peggle_ball", false) != true:
		return

	EventBus.peg_hit_sound_update.emit()

	var new_claimed_turn: int = int(body.get_meta("turn_owner", -1))
	if new_claimed_turn == -1:
		return

	var ball_owner: String = String(body.get_meta("ball_owner", "default"))
	_apply_color_for_owner(ball_owner)

	if claimed_turn == new_claimed_turn:
		return

	claimed_turn = new_claimed_turn
	claim_changed.emit()


func _apply_color_for_owner(owner_name: String) -> void:
	match owner_name:
		"player":
			visual_polygon.color = player_color
		"ai":
			visual_polygon.color = ai_color
		_:
			visual_polygon.color = unclaimed_color


func reset_peg() -> void:
	claimed_turn = -1
	visual_polygon.color = unclaimed_color


func get_claimed_turn() -> int:
	return claimed_turn
