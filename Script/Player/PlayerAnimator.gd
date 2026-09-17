extends Node3D

@export var trackingTarget: Node3D
@export var positionOffset: Vector3 = Vector3(0, 0, 0)
@export var trackingLimits: Vector2 = Vector2(1.3, 0.8)
@export var MoveExaguration: float = 2

@onready var boostMesh: Node3D = $Boost

func _process(delta: float) -> void:
	var targetPos = Vector3(trackingTarget.global_position.x, trackingTarget.global_position.y, global_position.z)
	global_position = lerp(global_position, targetPos + positionOffset, delta * 5)
	
	position.x = clamp(position.x, -trackingLimits.x, trackingLimits.x)
	position.y = clamp(position.y, -trackingLimits.y, trackingLimits.y)
	
	var pitch: float = global_position.y - targetPos.y
	var roll: float = global_position.x - targetPos.x
	rotation = Vector3(-pitch * MoveExaguration, 0, roll * MoveExaguration)
	
	boostMesh.rotate_z(5 * delta)
