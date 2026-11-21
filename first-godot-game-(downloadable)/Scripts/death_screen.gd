extends ColorRect

@onready var player = $"../Player"
@onready var score = $"../Player/score"
@onready var gameManager = $".."

@onready var scoreList = []
var high_score = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gameManager.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)


func _on_player_died() -> void:
	if gameManager.died == true:
		$scoreText.text = score.text

		scoreList.append(player.score)
		print(scoreList)
		high_score = scoreList.max()
		$highscore.text ="highscore: " + str(high_score)
		


func _on_yes_button_pressed() -> void:
	gameManager.player_died.connect(_on_player_died, CONNECT_ONE_SHOT)
	gameManager.resetGame()
