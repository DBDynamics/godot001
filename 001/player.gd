extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 8.0
@export var sprint_multiplier: float = 1.8
@export var mouse_sensitivity: float = 0.008
@export var max_pitch_deg: float = 60.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var yaw: float = 0.0
var pitch: float = 0.0

@onready var camera_pivot: Node3D = $"CameraPivot"

func _ready():
	_setup_input()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_input():
	_ensure_action_with_key("move_forward", KEY_W)
	_ensure_action_with_key("move_back", KEY_S)
	_ensure_action_with_key("move_left", KEY_A)
	_ensure_action_with_key("move_right", KEY_D)
	_ensure_action_with_key("sprint", KEY_SHIFT)
	_ensure_action_with_key("jump", KEY_SPACE)
	_ensure_action_with_key("toggle_mouse", KEY_ESCAPE)

func _ensure_action_with_key(action_name: String, key: int):
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	var already := false
	for e in InputMap.action_get_events(action_name):
		if e is InputEventKey and e.physical_keycode == key:
			already = true
			break
	if not already:
		InputMap.action_add_event(action_name, ev)

func _input(event):
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-max_pitch_deg), deg_to_rad(max_pitch_deg))

func _physics_process(delta):
	# 重力
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 输入方向（WASD）
	var forward_strength := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var right_strength := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var input_dir := Vector2(right_strength, forward_strength)

	# 应用鼠标视角（水平给玩家，垂直给相机枢）
	rotation.y = yaw
	if camera_pivot:
		camera_pivot.rotation.x = pitch

	# 依玩家朝向计算移动方向
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 冲刺速度
	var current_speed := speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)

	# 移动/阻尼
	if direction.length() > 0.0:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)

	move_and_slide()
