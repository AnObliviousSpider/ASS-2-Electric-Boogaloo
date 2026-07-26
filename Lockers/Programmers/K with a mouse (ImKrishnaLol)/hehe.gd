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

var click_radius : float = 3.0

func _input(event: InputEvent) -> void:
	# workdaround of click handling because _input_event Area2D signal handling was not working :(
	# I think because there's a bigger control container on top of Racoon
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var distance_to_mouse = get_global_mouse_position().distance_to(global_position)
			if distance_to_mouse <= click_radius:
				SceneManager.go("res://Lockers/Programmers/Sanket/SanketEasterEgg.tscn", 1)
