class_name GlobeLauncher
extends AnimatedSprite2D


@export_group("Launch Animation")

@export var launch_animation: StringName = (
	&"default"
)

# Godot frame indexes begin at zero.
# These settings play indexes 1 through 19.
@export_range(0, 100, 1)
var first_launch_frame: int = 1

@export_range(0, 100, 1)
var final_launch_frame: int = 19


func _ready() -> void:
	if sprite_frames == null:
		push_warning(
			"GlobeLauncher has no SpriteFrames resource."
		)
		return

	if not sprite_frames.has_animation(
		launch_animation
	):
		push_warning(
			"GlobeLauncher does not have animation: %s"
			% launch_animation
		)
		return

	# Prevent the animation from looping back
	# to its opening frame.
	sprite_frames.set_animation_loop(
		launch_animation,
		false
	)

	if not animation_finished.is_connected(
		_on_animation_finished
	):
		animation_finished.connect(
			_on_animation_finished
		)

	# The launcher's normal resting appearance
	# is the final frame.
	hold_on_final_frame()


func play_launch_animation() -> void:
	if sprite_frames == null:
		return

	if not sprite_frames.has_animation(
		launch_animation
	):
		return

	var safe_first_frame: int = (
		_get_safe_frame(
			first_launch_frame
		)
	)

	stop()

	animation = launch_animation

	set_frame_and_progress(
		safe_first_frame,
		0.0
	)

	play()


func hold_on_final_frame() -> void:
	if sprite_frames == null:
		return

	if not sprite_frames.has_animation(
		launch_animation
	):
		return

	var safe_final_frame: int = (
		_get_safe_frame(
			final_launch_frame
		)
	)

	stop()

	animation = launch_animation

	set_frame_and_progress(
		safe_final_frame,
		0.0
	)


func _on_animation_finished() -> void:
	if animation != launch_animation:
		return

	hold_on_final_frame()


func _get_safe_frame(
	requested_frame: int
) -> int:
	var frame_count: int = (
		sprite_frames.get_frame_count(
			launch_animation
		)
	)

	if frame_count <= 0:
		return 0

	return clampi(
		requested_frame,
		0,
		frame_count - 1
	)
