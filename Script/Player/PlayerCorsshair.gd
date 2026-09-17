extends Node3D

@export var cam: Camera3D
@export var cursorLimit: Vector2 = Vector2(1, 0.57)
@export var crosshairLerpSpeed: float = 15
@export var textOffset: Vector3 = Vector3(0, 0.2, 0)

@export var projectile: PackedScene
@export var firePoint: Node3D

@onready var crossOne: Node3D = $"1"
@onready var crossTwo: Node3D = $"2"
@onready var crossLock: Node3D = $"3"

@onready var typeText: Label3D = $"TypeText"
@onready var inputText: Label3D = $"InputText"

var cursorPos: Vector2 = Vector2(0, 0)
var target: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	typeText.visible = false
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ESC"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("M1"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if event.is_action_pressed("ENTER") && target && target.stun:
		FireProjectile()
	
	if event is InputEventMouseMotion:
		cursorPos += Vector2(event.relative.x, -event.relative.y) / 100
	if event is InputEventKey && event.is_pressed() && target:
		var inputChar: String = event.as_text()
		if inputChar.length() == 1:
			target.WriteLetter(inputChar)
	
	MoveCursor()

func MoveCursor():
	cursorPos.x = clamp(cursorPos.x, -cursorLimit.x, cursorLimit.x)
	cursorPos.y = clamp(cursorPos.y, -cursorLimit.y, cursorLimit.y)
	
	crossOne.position = Vector3(cursorPos.x, cursorPos.y, 0)
	crossOne.position.x = clamp(crossOne.position.x, -cursorLimit.x, cursorLimit.x)
	crossOne.position.y = clamp(crossOne.position.y, -cursorLimit.y, cursorLimit.y)

func _process(delta: float) -> void:
	crossTwo.position = lerp(crossTwo.position, crossOne.position, delta * crosshairLerpSpeed)
	
	Targeting()
	ArrowKeyControl(delta)
	
	if target:
		LockOnMovement(delta)
	else:
		crossLock.visible = false

#using the _input func didnt work for some reason
func ArrowKeyControl(delta: float):
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("LEFT"):
		x = -1
	elif Input.is_action_pressed("RIGHT"):
		x = 1
	if Input.is_action_pressed("UP"):
		y = 1
	elif Input.is_action_pressed("DOWN"):
		y = -1
	
	cursorPos += Vector2(x, y) * delta
	MoveCursor()

func LockOnMovement(delta: float):
	crossLock.visible = true
	crossLock.position = crossTwo.position
	
	var dirToTarget: Vector3 = (target.global_position - cam.global_position).normalized()
	var lockAngle = Vector3.FORWARD.angle_to( dirToTarget)
	var lockOnPos = cam.global_position + dirToTarget * (2 + lockAngle)
	var movePos = Vector2(lockOnPos.x, lockOnPos.y - 3)
	
	cursorPos = lerp(cursorPos, movePos, delta * 5)
	MoveCursor()

func Targeting():
	var space = get_world_3d().direct_space_state
	var origin = crossOne.global_position
	var dir = (crossOne.global_position - cam.global_position).normalized()
	var end = origin + dir * 999
	var ray = PhysicsRayQueryParameters3D.create(origin, end)
	var hit = space.intersect_ray(ray)
	
	if hit && (hit.collider.is_in_group("Target") || hit.collider.is_in_group("MenuTarget")):
		target = hit.collider
		inputText.text = hit.collider.currentInput
		typeText.text = hit.collider.targetWord
		
		inputText.position = crossOne.position - textOffset
		typeText.position = crossOne.position + textOffset
		
		inputText.visible = true
		typeText.visible = true
	else:
		target = null
		inputText.visible = false
		typeText.visible = false

func FireProjectile():
	var proj: HomingProjectile = projectile.instantiate()
	add_child(proj)
	
	proj.global_position = firePoint.global_position
	proj.SetTarget(firePoint, target)
