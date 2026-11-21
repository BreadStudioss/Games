extends Node2D

@onready var player = $Player
signal player_died

# Timers
@onready var waveTimer = $Timers/WaveTimer
@onready var enemyOneTimer = $Timers/SpawnE1
@onready var enemyTwoTimer = $Timers/SpawnE2
@onready var upgradeTimer = $Timers/UpgradeTimer

# Enemies
@onready var eOneScript = load("res://Scripts/enemy1_animator.gd")
@onready var eTwoScript = load("res://Scripts/enemy2_animator.gd")
var enemy1Scene = preload("res://Scenes/enemy_1.tscn")
var enemy2Scene = preload("res://Scenes/enemy_2.tscn")

# Dictionaries
@onready var upgrades = {
	"healthU": preload("res://Scenes/health_increase.tscn"),
	"shieldU": preload("res://Scenes/shield.tscn"),
	"scoreU": preload("res://Scenes/score_multiply.tscn"),
	"assistU": preload("res://Scenes/assistant.tscn"),
}
@onready var spawn_points = {
	"SPAWN_ONE_LEFT": $Portals/Portal1L/Spawn1L,
	"SPAWN_ONE_RIGHT": $Portals/Portal1R/Spawn1R,
	"SPAWN_TWO_LEFT": $Portals/Portal2L/Spawn2L,
	"SPAWN_TWO_RIGHT": $Portals/Portal2R/Spawn2R,
}

var wave := 0
var died = false


func _process(delta: float) -> void:
	$Player/wave.text = "wave " + str(wave)
	$DeathScreen.global_position = Vector2(player.global_position.x - 300, player.global_position.y - 250)
	if player.health <= 0 and not died:
		death()


func _on_wave_timer_timeout() -> void:
	wave += 1

	$Player/wave.text = "wave " + str(wave)
	enemyOneTimer.wait_time -= 0.5
	enemyTwoTimer.wait_time -= 0.5
	upgradeTimer.wait_time -= 0.5

	EnemyOneAnimator.damage += 2
	EnemyTwoAnimator.damage += 1


func instantiate_enemy_one(pos, size):
	var enemy_one = enemy1Scene.instantiate()
	enemy_one.position = pos
	enemy_one.scale = size
	enemy_one.add_to_group("enemies1")
	add_child(enemy_one)


func instantiate_enemy_two(pos, size):
	var enemy_two = enemy2Scene.instantiate()
	enemy_two.position = pos
	enemy_two.scale = size
	enemy_two.add_to_group("enemies2")
	add_child(enemy_two)


func instantiate_upgrade(pos):
	var upgradeOptions = [
		upgrades["healthU"],
		upgrades["shieldU"],
		upgrades["scoreU"],
		upgrades["assistU"],
	].pick_random()

	var upgrade = upgradeOptions.instantiate()
	upgrade.position = pos
	upgrade.scale = Vector2(2.5, 2.5)
	add_child(upgrade)


func _on_spawn_e_1_timeout() -> void:
	var spawn_pos = [
		spawn_points["SPAWN_ONE_LEFT"].global_position,
		spawn_points["SPAWN_ONE_RIGHT"].global_position,
	].pick_random()
	instantiate_enemy_one(spawn_pos, Vector2(4, 4))


func _on_spawn_e_2_timeout() -> void:
	var spawn_pos = [
		spawn_points["SPAWN_TWO_LEFT"].global_position,
		spawn_points["SPAWN_TWO_RIGHT"].global_position,
	].pick_random()
	instantiate_enemy_two(spawn_pos, Vector2(5.6, 5.6))


func _on_upgrade_timer_timeout() -> void:
	var upgradePositionX = randf_range(100, 1100)
	var upgradePositionY = randf_range(220, 400)
	instantiate_upgrade(Vector2(upgradePositionX, upgradePositionY)) # Replace with function body


func death(duration = 1.0):
	var tween = create_tween()
	# The target color is black (Color(0, 0, 0, 1))
	# The 'modulate' property is a Color.
	tween.tween_property(player, "modulate", Color(0, 0, 0, 1), duration)
	# Optional: connect a callback for when the fade is complete
	await tween.finished
	$DeathScreen.visible = true
	died = true
	
	$Node/Recycles.stop()
	emit_signal("player_died")



func resetGame():
	died = false
	$DeathScreen.visible = false
	$Node/Recycles.play()
	
	get_tree().call_group("enemies1", "queue_free")
	get_tree().call_group("enemies2", "queue_free")
	enemyOneTimer.wait_time = 10
	enemyTwoTimer.wait_time = 10
	
	get_tree().call_group("upgrades", "queue_free")
	upgradeTimer.wait_time = 15

	wave = 0
	$Player/scoreU.modulate = Color.BLACK
	$Player/shieldU.modulate = Color.BLACK
	$Player/assistU.modulate = Color.BLACK
	
	var spawnPos = Vector2(231, 367)
	player.canDash = true
	player.canExplode = true
	player.canShield = false
	player.scoreMultiply = false
	player.canAssist = false
	player.global_position = spawnPos
	player.score = 0
	player.health = 100
	player.modulate = Color.WHITE


func _on_player_died() -> void:
	if not $Node/death.playing:
		$Node/death.play()
