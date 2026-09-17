extends Node3D
class_name HomingProjectile

@export var target: Node3D
@export var travelTime: float = 1

var origin: Node3D

var startPos: Vector3
var endPos: Vector3
var time: float

func _ready() -> void:
	startPos = global_position

func SetTarget(newOrigin: Node3D, newTarget: Node3D):
	origin = newOrigin
	global_position = origin.global_position
	startPos = global_position
	
	target = newTarget
	endPos = target.global_position

func _process(delta: float) -> void:
	time += delta
	global_position = lerp(startPos, endPos, time / travelTime)
	
	if time >= travelTime:
		if target:
			target.Die()
		
		queue_free()
		return
	
	if origin:
		startPos = origin.global_position
	
	if target:
		endPos = target.global_position
		#look_at(target.global_position)
