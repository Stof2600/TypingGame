extends Node3D

@export var targetWord: String = "target"
@export var moveSpeed: float = 20
@export var onDeathScore: int = 50
@export var mistypeScoreLoss: int = 5
@export var getRandomWord: bool = true
@export var getHigherWord: bool = false
@export var spawnBehindPlayer: bool = false
@export var immortal: bool = false
##if the enemy should stay on screen during a loop (locks move speed)
@export var permanent: bool = false
##set its permanent location to where it spawned in
@export var randomPermanent: bool = false
##lerp to the permanent spot first before floating
@export var slideToPermanent: bool = false
##if permanent use this to offset from the player
@export var permanentOffset: Vector3 = Vector3(0, -1.5, -10)
@export var doSpinAnimation: bool = false
@export var spinAnimationDirection: Vector3 = Vector3.ZERO


var currentInput: String = ""
var stun: bool = false
var dead: bool = true

#only used if enemy is permanent
var player: Node3D
var system: Node

var distanceToPlayer: float = 0

signal deathSignal()

func _ready() -> void:
	player = get_tree().get_nodes_in_group("Player")[0]
	system = get_tree().get_nodes_in_group("System")[0]
	
	if randomPermanent:
		permanentOffset.x = randf_range(-2, 2)
		permanentOffset.y = randf_range(-2, 2)
	
	if getHigherWord:
		var newWord = system.GetHigherWord()
		targetWord = newWord if newWord != "" else targetWord
	elif getRandomWord:
		var newWord = system.GetRandomWord()
		targetWord = newWord if newWord != "" else targetWord

func _process(delta: float) -> void:
	
	
	if doSpinAnimation:
		rotate_x(spinAnimationDirection.x * delta)
		rotate_y(spinAnimationDirection.y * delta)
		rotate_z(spinAnimationDirection.z * delta)
	
	if permanent:
		var hoverPosition = player.global_position + permanentOffset
		if !slideToPermanent:
			global_position = hoverPosition
		elif slideToPermanent && global_position.distance_to(hoverPosition) > 1:
			var movedir = (hoverPosition - global_position).normalized()
			global_position += movedir * moveSpeed * delta
		else:
			slideToPermanent = false
			global_position = hoverPosition
		return
	
	position += Vector3.FORWARD * moveSpeed * delta
	
	distanceToPlayer = player.global_position.z - global_position.z
	if distanceToPlayer <= 5 && !spawnBehindPlayer:
		var leaveDir = (global_position - Vector3(0, 3, global_position.z)).normalized()
		position += leaveDir * (moveSpeed / 8) * delta
	if distanceToPlayer <= 0 && !spawnBehindPlayer:
		queue_free()
	elif (distanceToPlayer > 100 || distanceToPlayer < -50) && spawnBehindPlayer:
		queue_free()

func WriteLetter(letter: String):
	if targetWord != "" && letter.to_lower() == targetWord[0].to_lower():
		currentInput += targetWord[0]
		targetWord = targetWord.erase(0)
	elif  targetWord != "" && letter.to_lower() != targetWord[0].to_lower():
		system.AddScore(-mistypeScoreLoss)
	
	if targetWord.length() <= 0:
		stun = true

func Die():
	if !stun:
		return
	
	stun = false
	#put effects here
	deathSignal.emit()
	
	if immortal:
		targetWord = currentInput
		currentInput = ""
		return
	
	system.AddScore(onDeathScore)
	dead = true
	queue_free()
