extends RigidBody2D

#SCENES
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var ball_textures: Array[Texture2D]

@onready var sprite_2d: Sprite2D = $Sprite2D

@export var ball_hit_wall_sound: AudioStream



func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if ball_textures.is_empty():
		push_warning("No ballz textures have been assigned.")
		return

	sprite_2d.texture = ball_textures.pick_random()


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):

		if abs(state.get_contact_local_normal(i).y) < 0.1: 
			SfxPlayer.play(ball_hit_wall_sound)
			break



func ghost_ball():
	collision_mask=1+3
	await get_tree().create_timer(1).timeout
	collision_mask=1+2+3
