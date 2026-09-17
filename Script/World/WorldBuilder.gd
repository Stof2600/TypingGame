extends Node3D

@export_category("SEGMENTS")
@export var maxSegments: int = 3
@export var segmentLenght: float = 50
@export var loopAfterSeg: int = 15

@export var startSegment: PackedScene
@export var loopSegment: PackedScene
@export var randomSegments: Array[PackedScene]

@export_category("ENEMIES")
@export var enemyPrefabs: Array[PackedScene]
@export var rareEnemyPrefab: PackedScene
@export var enemySpawnTime: float = 2
@export var enemySpawnDistance: float = 30
@export var enemySpawnLimits: Vector2 = Vector2(5, 2)
@export var maxEnemies: int = 5
@export_range(0, 100, 1) var rareEnemyChance: int = 5

var activeSegments: Array[Node3D]
var loopSegments: Array[Node3D]

var inLoop: bool = false
var inStart: bool = true
var currentSegment: int = 0
var loopCount: int = 0

var enemyCount: int = 0
var enemyTimer: float = 0

var player: Node3D

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]

func _process(delta: float) -> void:
	if activeSegments.size() < maxSegments:
		buildSegment()
	
	enemyCount = get_tree().get_nodes_in_group("Target").size()
	if enemyCount < maxEnemies && !inStart && enemyTimer >= enemySpawnTime:
		#5% chance to spawn a rare
		if randi_range(0, 100) < rareEnemyChance:
			SpawnEnemy(rareEnemyPrefab)
			enemyTimer = 0
			return
		SpawnEnemy(enemyPrefabs[randi_range(0, enemyPrefabs.size() - 1)])
		enemyTimer = 0
	elif enemyTimer <= enemySpawnTime:
		enemyTimer += delta

func buildSegment():
	if currentSegment >= loopAfterSeg:
		SpawnSegment(loopSegment)
		loopCount += 1
		
		if !inLoop:
			SpawnLoop()
			inLoop = true
	elif inStart:
		SpawnSegment(startSegment)
	else:
		SpawnSegment(randomSegments[randi_range(0, randomSegments.size() - 1)])
	
	currentSegment += 1

func SpawnSegment(seg: PackedScene):
	var newSeg = seg.instantiate()
	add_child(newSeg)
	newSeg.global_position = Vector3(0, 0, -segmentLenght * currentSegment)
	activeSegments.append(newSeg)
func SpawnLoop():
	if loopSegments.size() >= 3: 
		return
	
	for i in 3:
		var loopSeg = loopSegment.instantiate()
		add_child(loopSeg)
		loopSeg.global_position = Vector3(0, 0, segmentLenght * (i + 1))
		loopSegments.append(loopSeg)

func SpawnEnemy(enemy: PackedScene):
	var newEnemy = enemy.instantiate()
	add_child(newEnemy)
	
	var x: float = randf_range(-enemySpawnLimits.x, enemySpawnLimits.x)
	var y: float = randf_range(-enemySpawnLimits.y, enemySpawnLimits.y)
	
	var z: float = player.position.z - enemySpawnDistance
	if newEnemy.spawnBehindPlayer:
		z = player.position.z + 20
	
	newEnemy.global_position = Vector3(x, 3 + y, z)

func ClearSegment():
	var toDelete = activeSegments[0]
	activeSegments.remove_at(0)
	
	toDelete.queue_free()
func ClearWorld():
	for seg in activeSegments:
		seg.queue_free()
	
	activeSegments.clear()
	currentSegment = 0
	inLoop = false
	
	for e in get_tree().get_nodes_in_group("Target"):
		e.global_position.z = player.global_position.z - e.distanceToPlayer

func LeaveStart():
	inStart = false
func ReturnToStart():
	for targ in get_tree().get_nodes_in_group("Target"):
		targ.queue_free()
	
	inStart = true
