extends Node
class_name Button_enhancer


## How much to scale up on hover (e.g. 1.1 = 110%).
@export var hover_scale: float = 1.1

## How much to squish on click (e.g. 0.9 = 90%).
@export var click_squish: float = 0.9

## Duration of the hover tween (seconds).
@export var hover_duration: float = 0.12

## Duration of the click squish tween (seconds).
@export var click_duration: float = 0.08


var _parent: BaseButton
var _tween: Tween
var _original_scale: Vector2
var hovering :bool= false


func _ready() -> void:
	_parent = get_parent()
	if not _parent is BaseButton:
		push_error("ButtonAnimation must be a child of a Button.")
		return

	_original_scale = _parent.scale

	_parent.pivot_offset_ratio = 0.5 *Vector2.ONE
	_parent.mouse_entered.connect(_on_mouse_entered)
	_parent.mouse_exited.connect(_on_mouse_exited)
	_parent.button_down.connect(_on_button_down)
	_parent.button_up.connect(_on_button_up)



func _on_mouse_entered() -> void:
	hovering = true
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_parent, ^"scale", _original_scale * hover_scale, hover_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _on_mouse_exited() -> void:
	hovering = false
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_parent, ^"scale", _original_scale, hover_duration * 0.6)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_button_down() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_parent, ^"scale", _original_scale * click_squish, click_duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	


func _on_button_up() -> void:
	_kill_tween()
	_tween = create_tween()
	var _target_scale = hover_scale* _original_scale if hovering else _original_scale
	_tween.tween_property(_parent, ^"scale", _target_scale, click_duration * 1.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
