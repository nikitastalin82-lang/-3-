extends CharacterBody3D

@export var speed: float = 3.0
@export var run_speed: float = 7.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var model_forward_offset: float = 0.0
@export var idle_animation_name: StringName = &"mixamo_com_004"
@export var move_animation_name: StringName = &"mixamo_com_006"

@onready var model: Node3D = $animation
@onready var camera_pivot: Node3D = $CameraPivot

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var animation_player: AnimationPlayer

func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null:
		push_warning("В GLB не найден AnimationPlayer")
	elif not animation_player.has_animation(idle_animation_name):
		push_warning("В GLB не найдена анимация покоя: %s" % idle_animation_name)
	elif not animation_player.has_animation(move_animation_name):
		push_warning("В GLB не найдена анимация: %s" % move_animation_name)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - event.relative.y * mouse_sensitivity,
			deg_to_rad(-40),
			deg_to_rad(60)
		)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_forward := -camera_pivot.global_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera_pivot.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var direction := camera_right * input_dir.x - camera_forward * input_dir.y
	var is_running := Input.is_action_pressed("run")
	var current_speed := run_speed if is_running else speed

	if direction.length_squared() > 0.0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		var target_rotation := atan2(-direction.x, -direction.z) + model_forward_offset
		model.rotation.y = lerp_angle(model.rotation.y, target_rotation, delta * 10.0)
		_play_animation(move_animation_name)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		_play_animation(idle_animation_name)

	move_and_slide()

func _play_animation(animation_name: StringName) -> void:
	if not animation_player or not animation_player.has_animation(animation_name):
		return
	if animation_player.current_animation != animation_name or not animation_player.is_playing():
		animation_player.play(animation_name)
