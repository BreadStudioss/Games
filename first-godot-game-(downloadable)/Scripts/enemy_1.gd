extends CharacterBody2D

const SPEED = 300.0
var canAttack = false
var canEmitt = false
var is_dying = false

var getAttacked = false
var attack_signal_connected = false

var health = 25

@onready var health_Text = $EnemyHealth
@onready var raycast = $RayCast2D
@onready var target = $"../Player"
@onready var animator = $enemyAnimtor
@onready var attackParticles: GPUParticles2D = $attackParticles
@onready var deathParticles: GPUParticles2D = $deathParticles
@onready var particle_mat := attackParticles.process_material as ParticleProcessMaterial


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	# Check if player is in range to attack
	health_Text.text = str(health)

	if raycast.is_colliding():
		var targetP = raycast.get_collider()
		if targetP.name == "Player":
			canAttack = true
			velocity.x = 0
			canEmitt = true
		else:
			canEmitt = false
			canAttack = false
	else:
		canEmitt = false
		canAttack = false
		var direction = sign(target.global_position.x - global_position.x)
		velocity.x = direction * SPEED

	# Flip sprite, raycast, and particles
	if target.global_position.x < global_position.x:
		animator.flip_h = true
		raycast.target_position.x = -abs(raycast.target_position.x)
		particle_mat.gravity.x = -100
	elif target.global_position.x > global_position.x:
		animator.flip_h = false
		raycast.target_position.x = abs(raycast.target_position.x)
		particle_mat.gravity.x = 100

	if is_instance_valid(self):
		if health <= 0 and not is_dying:
			health = 0
			is_dying = true
			enemyDie()

	move_and_slide()


func enemyDie():
	if target.scoreMultiply == true:
		target.score += 400
	else:
		target.score += 200

	health_Text.text = ""
	# 1. Play animation
	animator.play("Die")
	await animator.animation_finished

	# 2. Hide the Sprite, NOT the whole enemy
	animator.visible = false
	$EnemyHealth.visible = false
	# 3. Fire particles and WAIT for them
	deathParticles.emitting = true
	await deathParticles.finished

	# 4. Now it's safe to remove the enemy
	queue_free()


func take_damage(damage):
	health -= damage
