extends Node3D

@export var cam: Camera3D
@export var moveSpeed: float = 20
@onready var world = $"../World"

var movementCounter: float = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += Vector3.FORWARD * moveSpeed * delta
	cam.position += Vector3.FORWARD * moveSpeed * delta
	
	if position.z > 0: 
		return
	
	movementCounter += moveSpeed * delta
	if movementCounter > world.segmentLenght:
		movementCounter = 0
		world.ClearSegment()
		
		if world.inLoop && world.loopCount > world.maxSegments:
			position = Vector3(0, 3, 150)
			cam.position = Vector3(0, 3, 150)
			world.loopCount = 0
			world.ClearWorld()
