extends Node

@export_category("GAME")
##length of a round in seconds
@export var gameLenght: float = 180
@export var easyWordLenght: int = 4
@export var normalWordLenght: int = 7

@export_category("UI")
@export var startTarget: Node3D
@export var difficultyTargets: Array[Node3D]
@export var difficultyDisplay: Node3D
@export var scoreDisplay: Label3D
@export var highScoreDisplay: Label3D
@export var timeDisplay: Label3D

@onready var skybox: WorldEnvironment = $WorldData
var daySky: Color = Color("789da4")
var redSky: Color = Color("a00037")
var nightSky: Color = Color("01002b")

var wordFile: String = "res://Texts/Words.txt"
var easyWords: Array[String]
var normalWords: Array[String]
var extremeWords: Array[String]

var scoreFile: String = "res://Texts/Scores.txt"
var highScore: int = 0

#1=easy, 2=normal, 3=extreme
var difficulty: int = 0
var score: int = 0
var visualScore: int = 0
var newHighScore: bool = false

var roundTimer: SceneTreeTimer

var dayCountUp: bool = true
var dayTime: float = 0
var dayLenght: float = 60
#half gets used for the red shift
var sunDownLenght: float = 30
var nightFallLenght: float = 30
var dayNightCycleStep: int = 0

signal endGameSig

func _init() -> void:
	LoadWords()
	LoadHighScore()

func _ready() -> void:
	print("EASY COUNT: " + str(easyWords.size()))
	print("NORMAL COUNT: " + str(normalWords.size()))
	print("EXTREME COUNT: " + str(extremeWords.size()))
	
	highScoreDisplay.text = "HIGH-SCORE: " + str(highScore)
	SetDifEasy()
	scoreDisplay.text = "SCORE: 0"

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if visualScore != score:
		var add = 1 if score > visualScore else -1
		visualScore += add
		scoreDisplay.text = "SCORE: " + str(visualScore)
		if newHighScore:
			highScoreDisplay.text = "HIGH-SCORE: " + str(visualScore)
	
	if score > highScore:
		newHighScore = true
		SaveHighScore()
	
	GameTimer()
	
	DayNightCycle(delta)

func LoadWords():
	var file = FileAccess.open(wordFile, FileAccess.READ)
	
	while !file.eof_reached():
		var word = file.get_line()
		if word.length() <= easyWordLenght:
			easyWords.append(word)
		elif word.length() <= normalWordLenght:
			normalWords.append(word)
		else:
			extremeWords.append(word)
	
	file.close()
func LoadHighScore():
	var listedScores: Array[String]
	var file = FileAccess.open(scoreFile, FileAccess.READ)
	while !file.eof_reached():
		listedScores.append(file.get_line())
	
	file.close()
	
	for scr in listedScores:
		var comp = int(scr)
		if comp > highScore:
			highScore = comp
func SaveHighScore():
	highScore = score
	var file = FileAccess.open(scoreFile, FileAccess.WRITE)
	file.store_line(str(highScore))
	
	file.close()

func GetRandomWord() -> String:
	match difficulty:
		1: return GetEasyWord()
		2: return GetNormalWord()
		3: return GetExtremeWord()
	
	return GetEasyWord()
func GetHigherWord() -> String:
	var bonusDif = difficulty + 1
	match bonusDif:
		2: return GetNormalWord()
		3: return GetExtremeWord()
	
	return GetExtremeWord() 
func GetEasyWord() -> String:
	if easyWords.size() <= 0:
		return "error"
	return easyWords[randi_range(1, easyWords.size() - 2)]
func GetNormalWord() -> String:
	if normalWords.size() <= 0:
		return "error"
	return normalWords[randi_range(1, normalWords.size() - 2)]
func GetExtremeWord() -> String:
	if extremeWords.size() <= 0:
		return "error"
	return extremeWords[randi_range(1, extremeWords.size() - 2)]

func AddScore(amount: int):
	score += amount * difficulty
	scoreDisplay.text = "SCORE: " + str(visualScore)

func GameTimer():
	if !roundTimer:
		var realtime = Time.get_datetime_string_from_system(false, false)
		timeDisplay.text = "TIME\n" + realtime.substr(11, 8)
		
		return
	
	var timeString: String = "TIME\n%01d:%02d:%02d"
	
	var total: float = roundTimer.time_left
	@warning_ignore("narrowing_conversion")
	var minute: int = total / 60
	var second: int = floor(total - (60 * minute))
	var value: float = total - (60 * minute) - second
	var mili: int = floor(value * 100)
	
	timeDisplay.text = timeString % [minute, second, mili]
	
	if total <= 0:
		EndGame()

#janky day/night cycle, don't touch unless you have to
func DayNightCycle(delta: float):
	dayTime = dayTime + delta if dayCountUp else dayTime - delta
	if dayNightCycleStep == 0:
		skybox.environment.background_color = daySky
		if dayTime > dayLenght:
			dayNightCycleStep = 1
			dayTime = 0
		if dayTime < 0:
			dayCountUp = true
			dayTime = dayLenght
	
	elif dayNightCycleStep == 1:
		skybox.environment.background_color = lerp(daySky, redSky, dayTime / sunDownLenght)
		if dayTime > sunDownLenght:
			dayNightCycleStep = 2
			dayTime = 0
		if dayTime < 0:
			dayNightCycleStep = 0
			dayTime = dayLenght
	
	elif dayNightCycleStep == 2:
		skybox.environment.background_color = lerp(redSky, nightSky, dayTime / nightFallLenght)
		if dayTime > nightFallLenght:
			dayNightCycleStep = 3
			dayTime = 0
		if dayTime < 0:
			dayNightCycleStep = 1
			dayTime = sunDownLenght
	
	elif  dayNightCycleStep == 3:
		skybox.environment.background_color = nightSky
		if dayTime > dayLenght:
			dayCountUp = false
			dayTime = -1
		if dayTime < 0:
			dayNightCycleStep = 2
			dayTime = nightFallLenght
	 
	pass

func SetDifEasy():
	difficulty = 1
	MoveDifDisplay(difficultyTargets[0])
func SetDifNormal():
	difficulty = 2
	MoveDifDisplay(difficultyTargets[1])
func SetDifExtreme():
	difficulty = 3
	MoveDifDisplay(difficultyTargets[2])
func MoveDifDisplay(target: Node3D):
	difficultyDisplay.reparent(target)
	difficultyDisplay.position = Vector3(0.5, 0, 0)

func StartGame():
	for n in difficultyTargets:
		n.process_mode = Node.PROCESS_MODE_DISABLED
		n.visible = false
	
	startTarget.process_mode = Node.PROCESS_MODE_DISABLED
	startTarget.visible = false
	
	roundTimer = get_tree().create_timer(gameLenght)
func EndGame():
	for n in difficultyTargets:
		n.process_mode = Node.PROCESS_MODE_ALWAYS
		n.visible = true
	
	startTarget.process_mode = Node.PROCESS_MODE_ALWAYS
	startTarget.visible = true
	
	roundTimer = null
	endGameSig.emit()
	
	highScoreDisplay.text = "HIGH-SCORE: " + str(highScore)
	SetDifEasy()
	scoreDisplay.text = "SCORE: 0"
	newHighScore = false
	score = 0
	visualScore = 0
