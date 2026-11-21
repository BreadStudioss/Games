extends AnimatedSprite2D

class_name EnemyOneAnimator

@onready var player = $"../../Player"
@onready var enemy = $".."
@onready var camera = $"../../Player/Camera2D"

static var damage := 5


func _ready() -> void:
	play("Attack")


func _on_animation_finished() -> void:
	if enemy.canEmitt == true and enemy.health > 0:
		play("Attack")
		enemy.attackParticles.emitting = true
		if not player.canShield:
			player.health -= damage
			camera.add_trauma(0.2) # Big shake
	else:
		play("Walk")

	if enemy.health <= 0:
		enemy.visible = false
