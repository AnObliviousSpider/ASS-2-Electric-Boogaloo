@tool
class_name PeggleBallBin
extends Area2D

signal ball_caught(ball: Node2D, bin_emotion: int)

@export_enum("Happy", "Dejected", "Flirty", "Angry") var what_emotion_to_respond_with: int = 0 :
	set(value):
		what_emotion_to_respond_with = value
		if $Sprite2D and GameData.emotions.keys()[what_emotion_to_respond_with]:
			$Sprite2D.texture = load("res://Assets/Art/Game/BinSprites/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "Bin.png")



func _ready() -> void:
	$Sprite2D.texture = load("res://Assets/Art/Game/BinSprites/" + GameData.emotions.keys()[what_emotion_to_respond_with] + "Bin.png")
	body_entered.connect(_on_body_entered)
	if get_child_count() == 3:
		GameData.connect("emotion_changed", get_child(2).emotion_effect())

func _on_body_entered(body: Node2D) -> void:
	if body.get_meta("is_peggle_ball", false) != true:
		return
	
	if body.get_meta("ball_resolved", false) == true:
		return
	
	ball_caught.emit(body, what_emotion_to_respond_with)
	
	EventBus.dialogue_mood_triggered.emit(GameData.emotions.keys()[what_emotion_to_respond_with], LevelManager.level)
	print("triggered mood dialogue: ", GameData.emotions.keys()[what_emotion_to_respond_with])
	
