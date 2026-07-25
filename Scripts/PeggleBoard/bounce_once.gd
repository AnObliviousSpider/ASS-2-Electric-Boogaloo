extends StaticBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer=16
	
func bounce_once():
	collision_layer=1


func _on_area_2d_body_entered(body: Node2D) -> void:
		await get_tree().create_timer(1).timeout
		collision_layer=16
