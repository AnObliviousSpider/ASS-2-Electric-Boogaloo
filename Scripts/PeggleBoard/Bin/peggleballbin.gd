@tool
class_name PeggleBallBin
extends Area2D

@export var animated_sprite : AnimatedSprite2D
@export var light_vfx : Sprite2D

@export var fade_in_duration : float = 1
@export var fade_out_duration : float = 0.5

signal ball_caught(ball: Node2D, bin_emotion: int)

var bin_active : bool
var light_vfx_tween : Tween

@export_enum("Happy", "Dejected", "Flirty", "Angry") var what_emotion_to_respond_with: int = 0 :
	set(value):
		what_emotion_to_respond_with = value
		if $Sprite2D and GameData.emotions.keys()[what_emotion_to_respond_with]:
			set_emotion()


func set_emotion() -> void:
	$Sprite2D.texture = load("res://Assets/Art/Game/BinSprites/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "Bin.png")
	animated_sprite.sprite_frames = load("res://Resources/Art/Game/BinSpriteFrames/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "BinSpin.tres")

func _ready() -> void:
	set_emotion()
	body_entered.connect(_on_body_entered)
	if GameData:
		GameData.emotion_changed.connect(on_active_emotion_changed)

func on_active_emotion_changed(emotion_index: int) -> void:
	if emotion_index == what_emotion_to_respond_with:
		bin_active = true
		animated_sprite.visible = true
		animated_sprite.play("default")
		if light_vfx_tween and light_vfx_tween.is_valid():
			light_vfx_tween.kill()
		light_vfx_tween = create_tween()
		light_vfx_tween.tween_property(light_vfx, "modulate:a", 1.0, fade_in_duration)
	else:
		bin_active = false
		animated_sprite.visible = false
		if light_vfx_tween and light_vfx_tween.is_valid():
			light_vfx_tween.kill()
		light_vfx_tween = create_tween()
		light_vfx_tween.tween_property(light_vfx, "modulate:a", 0.0, fade_out_duration)

func _on_body_entered(body: Node2D) -> void:
	if body.get_meta("is_peggle_ball", false) != true:
		return
	
	if body.get_meta("ball_resolved", false) == true:
		return
	
	ball_caught.emit(body, what_emotion_to_respond_with)
	
	GameData.current_emotion = what_emotion_to_respond_with
	
	GameData.ball_entered_bin.emit()
	
	if bin_active:
		# give powerup
		pass
