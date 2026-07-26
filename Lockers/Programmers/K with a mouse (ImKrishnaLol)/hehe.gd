extends CharacterBody2D

@export var speed: float = 2
@export var ang_speed: float = 0.5
@export var direction: Vector2 = Vector2.from_angle(-0.5)
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	velocity= speed* direction
	
func _process(delta: float) -> void:
	animated_sprite_2d.rotate(ang_speed* delta)
	move_and_slide()
