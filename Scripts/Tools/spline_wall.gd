@tool
extends Path2D
class_name SplineWall

@export var block_scene: PackedScene:
	set(value):
		block_scene = value
		update_wall()

@export var wall_physics_material: PhysicsMaterial:
	set(value):
		wall_physics_material = value
		update_wall()

@export var block_spacing: float = 24.0:
	set(value):
		block_spacing = value
		update_wall()

@export var default_block_size: Vector2 = Vector2(20.0, 10.0):
	set(value):
		default_block_size = value
		update_wall()

@export var default_color: Color = Color.WHITE:
	set(value):
		default_color = value
		update_wall()

@export var closed_loop: bool = false:
	set(value):
		closed_loop = value
		update_wall()

@export var bake_interval: float = 4.0:
	set(value):
		bake_interval = value
		if curve:
			curve.bake_interval = bake_interval
		update_wall()

var blocks_container: Node2D

func _ready() -> void:
	setup_nodes()
	_connect_curve()
	update_wall()


func _exit_tree() -> void:
	if Engine.is_editor_hint() and blocks_container:
		blocks_container.queue_free()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_connect_curve()


func _connect_curve() -> void:
	if curve:
		if not curve.changed.is_connected(update_wall):
			curve.changed.connect(update_wall)
			update_wall()


func setup_nodes() -> void:
	blocks_container = get_node_or_null("Blocks") as Node2D
	if not blocks_container:
		blocks_container = Node2D.new()
		blocks_container.name = "Blocks"
		add_child(blocks_container)
		_set_owner_recursive(blocks_container)


func _set_owner_recursive(target_node: Node) -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var edited_root: Node = get_tree().edited_scene_root
	if not edited_root:
		return
	if target_node != edited_root and not target_node.owner:
		target_node.owner = edited_root
	for child: Node in target_node.get_children():
		_set_owner_recursive(child)


func _is_curve_closed() -> bool:
	if not curve or curve.get_point_count() < 3:
		return false
	var first_point: Vector2 = curve.get_point_position(0)
	var last_point: Vector2 = curve.get_point_position(curve.get_point_count() - 1)
	return first_point.distance_to(last_point) < 4.0


func _get_curve_tangent(d: float, curve_length: float, is_closed: bool) -> Vector2:
	var delta: float = 1.0
	var p1: Vector2
	var p2: Vector2

	if is_closed:
		var d1: float = fmod(d - delta + curve_length, curve_length)
		var d2: float = fmod(d + delta, curve_length)
		p1 = curve.sample_baked(d1)
		p2 = curve.sample_baked(d2)
	else:
		var d1: float = maxf(0.0, d - delta)
		var d2: float = minf(curve_length, d + delta)
		p1 = curve.sample_baked(d1)
		p2 = curve.sample_baked(d2)

	var dir: Vector2 = (p2 - p1).normalized()
	return dir if dir != Vector2.ZERO else Vector2.RIGHT


func update_wall() -> void:
	if not curve or not is_inside_tree() or not blocks_container:
		return

	for child: Node in blocks_container.get_children():
		blocks_container.remove_child(child)
		child.queue_free()

	var curve_length: float = curve.get_baked_length()
	if curve_length <= 0.0 or block_spacing <= 0.0:
		return

	var is_closed: bool = closed_loop or _is_curve_closed()
	var total_blocks: int = roundi(curve_length / block_spacing)
	total_blocks = maxi(1, total_blocks)
	var effective_spacing: float = curve_length / float(total_blocks)

	var half_height: float = default_block_size.y / 2.0
	var first_start_normal: Vector2 = Vector2.ZERO
	var first_start_point: Vector2 = Vector2.ZERO

	for block_index: int in range(total_blocks):
		var start_distance: float = float(block_index) * effective_spacing
		var end_distance: float = float(block_index + 1) * effective_spacing

		var start_point: Vector2 = curve.sample_baked(start_distance)
		var end_point: Vector2 = curve.sample_baked(end_distance)

		var start_dir: Vector2 = _get_curve_tangent(start_distance, curve_length, is_closed)
		var end_dir: Vector2 = _get_curve_tangent(end_distance, curve_length, is_closed)

		var start_normal: Vector2 = Vector2(-start_dir.y, start_dir.x)
		var end_normal: Vector2 = Vector2(-end_dir.y, end_dir.x)

		if block_index == 0:
			first_start_point = start_point
			first_start_normal = start_normal

		if is_closed and block_index == total_blocks - 1:
			end_point = first_start_point
			end_normal = first_start_normal

		var sample_center_distance: float = (start_distance + end_distance) / 2.0
		var center: Vector2 = curve.sample_baked(sample_center_distance)

		var top_left: Vector2 = (start_point + start_normal * half_height) - center
		var top_right: Vector2 = (end_point + end_normal * half_height) - center
		var bottom_right: Vector2 = (end_point - end_normal * half_height) - center
		var bottom_left: Vector2 = (start_point - start_normal * half_height) - center

		var polygon: PackedVector2Array = PackedVector2Array([top_left, top_right, bottom_right, bottom_left])

		var block_node: Node2D
		if block_scene:
			block_node = block_scene.instantiate() as Node2D
			block_node.name = "Block_" + str(block_index)
			block_node.position = center

			blocks_container.add_child(block_node)
			_set_owner_recursive(block_node)

			if block_node.has_method("set_polygon"):
				block_node.call("set_polygon", polygon)
			else:
				block_node.rotation = (end_point - start_point).angle()
		else:
			block_node = _create_wedge_block(polygon)
			block_node.name = "Block_" + str(block_index)
			block_node.position = center
			blocks_container.add_child(block_node)
			_set_owner_recursive(block_node)


func _create_wedge_block(polygon: PackedVector2Array) -> StaticBody2D:
	var body_node: StaticBody2D = StaticBody2D.new()
	body_node.physics_material_override = wall_physics_material
	body_node.add_to_group("pegs")

	var collision_shape: CollisionPolygon2D = CollisionPolygon2D.new()
	collision_shape.polygon = polygon
	body_node.add_child(collision_shape)

	var visual_polygon: Polygon2D = Polygon2D.new()
	visual_polygon.polygon = polygon
	visual_polygon.color = default_color
	body_node.add_child(visual_polygon)

	return body_node
