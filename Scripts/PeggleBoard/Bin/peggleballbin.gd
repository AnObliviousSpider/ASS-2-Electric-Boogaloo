@tool
class_name PeggleBallBin
extends Area2D

signal ball_caught(ball: Node2D, bin_emotion: int)

var bin_active : bool

@export_enum("Happy", "Dejected", "Flirty", "Angry") var what_emotion_to_respond_with: int = 0 :
	set(value):
		what_emotion_to_respond_with = value
		if $Sprite2D and GameData.emotions.keys()[what_emotion_to_respond_with]:
			$Sprite2D.texture = load("res://Assets/Art/Game/BinSprites/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "Bin.png")



func _ready() -> void:
	$Sprite2D.texture = load("res://Assets/Art/Game/BinSprites/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "Bin.png")
	body_entered.connect(_on_body_entered)
	GameData.emotion_changed.connect(on_active_emotion_changed)

func on_active_emotion_changed(emotion_index: int) -> void:
	print("active emotion: ", emotion_index)
	if emotion_index == what_emotion_to_respond_with:
		bin_active = true
	else:
		bin_active = false

func _on_body_entered(body: Node2D) -> void:
	if body.get_meta("is_peggle_ball", false) != true:
		return
	
	if body.get_meta("ball_resolved", false) == true:
		return
	
	ball_caught.emit(body, what_emotion_to_respond_with)
	
	EventBus.dialogue_mood_triggered.emit(what_emotion_to_respond_with, LevelManager.level)
	
	GameData.current_emotion = what_emotion_to_respond_with
	print("triggered mood dialogue: ", GameData.emotions.keys()[what_emotion_to_respond_with])
