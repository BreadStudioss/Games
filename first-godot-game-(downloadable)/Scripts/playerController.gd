extends CharacterBody2D

# Player Componenets
const JUMP_VELOCITY = -700.0
var health = 100
var speed = 500.0
var score = 0
@onready var animated_sprite = $AnimatedSprite2D

# Attack Components
var canDash = true
var canExplode = true
var attackONE = false
var isAttacking = false
var dashRange = false
var dash_areas = []
@onready var explosion = $explosion
@onready var explosionCooldown = $"../Timers/AttackCooldowns/Explosion"
@onready var dashCooldown = $"../Timers/AttackCooldowns/Dash"

# Upgrades Components
var canShield = false
var scoreMultiply = false
var canAssist = false
@onready var shieldCooldown = $"../Timers/Cooldowns/shieldCooldown"
@onready var scoreCooldown = $"../Timers/Cooldowns/scoreCooldown"
@onready var assistCooldown = $"../Timers/Cooldowns/assistCooldown"

# Enemy Components
var isCollidingE1 = false
var isCollidingE2 = false
var enemies1_list = []
var enemies2_list = []
var all_enemies_one
var all_enemies_two
@onready var enemy1 = null
@onready var enemy2 = null

#Audio
@onready var dashSound = $"../Node/Dash"
@onready var explosionsSound =  $"../Node/Explosion"
@onready var hitHurtSound = $"../Node/HitHurt"
@onready var jumpSound = $"../Node/Jump"
@onready var upgradeSound = $"../Node/PowerUp"

@onready var camera = $Camera2D
var level := ""


func _physics_process(delta: float) -> void:
	$score.text = "score: " + str(score)
	$playerHealth.value = health

	if health > 100:
		health = 100
	elif health < 0:
		health = 0

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$"../Node/Jump".play()
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")

	if is_on_floor() and not attackONE and not isAttacking:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	elif not is_on_floor() and not attackONE and not isAttacking:
		animated_sprite.play("jump")

	if direction < 0:
		animated_sprite.flip_h = true

	elif direction > 0:
		animated_sprite.flip_h = false

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()


func _input(event: InputEvent) -> void:
	# Move Level Down
	if event.is_action_pressed("down"):
		set_collision_mask_value(1, false)

		velocity.y = 500
		# Re-enable after a short delay
		await get_tree().create_timer(0.15).timeout
		set_collision_mask_value(1, true)

	# Attacks
	if event.is_action_pressed("attack1"):
		attackONE = true
		hitHurtSound.pitch_scale = randf_range(0.8, 1.2) 
		hitHurtSound.play()
		camera.add_trauma(0.2) # Big shake
		Attack1()
		

	if event.is_action_pressed("attack2") and canDash == true:
		canDash = false
		$"../Node/Dash".play()
		dashCooldown.start()
		camera.add_trauma(0.3) # Big shake
		Attack2()
	elif event.is_action_pressed("attack2") and canDash == false:
		flash_color(Color.AQUA, 0.4)

	if event.is_action_pressed("attack3") and canExplode == true:
		canExplode = false
		$"../Node/Explosion".play()
		explosionCooldown.start()
		camera.add_trauma(1) # Big shake
		Attack3()
	elif event.is_action_pressed("attack3") and canExplode == false:
		flash_color(Color.AQUA, 0.5)


func Attack1():
	# N (Physical Attack)
	if attackONE == true:
		var moves = ["punch", "kick"]
		animated_sprite.play(moves.pick_random())
		$physicalAttackParticles.emitting = true

		# handle enemy one damage
		if is_instance_valid(enemy1):
			if isCollidingE1 == true:
				takeDamage(enemy1, 5)
			elif dashRange == true:
				takeDamage(enemy1, 10)

		# handle enemy two damage
		if is_instance_valid(enemy2):
			if isCollidingE2 == true:
				takeDamage(enemy2, 3)
			elif dashRange == true:
				takeDamage(enemy2, 6)

		await animated_sprite.animation_finished
		attackONE = false


func Attack2():
	# shift (dash + hit)
	if not isAttacking:
		isAttacking = true
		animated_sprite.play("dash")
		$dashParticles.emitting = true
		speed *= 1.5

		# --- IMPACT LOGIC ---
		# Check for enemies during the dash
		if is_instance_valid(enemy1) and dashRange:
			takeDamage(enemy1, 15) # High damage for dashing through

		if is_instance_valid(enemy2) and dashRange:
			takeDamage(enemy2, 10)
		# --------------------

		await animated_sprite.animation_finished

		# Reset state
		$dashParticles.emitting = false
		speed = 500
		isAttacking = false


func Attack3():
	# M (Explosive)
	if not isAttacking:
		if is_instance_valid(explosion): # Check if the node still exists
			isAttacking = true
			set_physics_process(false) # Disables movement calculations
			animated_sprite.play("explode")
			velocity = Vector2.ZERO
			explosion.play("explode")
			await explosion.animation_finished
			isAttacking = false
			set_physics_process(true) # Disables movement calculationsd

			# Handle enemy one damage
			all_enemies_one = get_tree().get_nodes_in_group("enemies1")

			for enemy in all_enemies_one:
				if enemy is Area2D:
					continue # Skip this loop iteration if it's an area
				if level == "one":
					takeDamage(enemy, 20)

			# Handle enemy two damage
			all_enemies_two = get_tree().get_nodes_in_group("enemies2")

			if level == "two":
				for enemy in all_enemies_two:
					if enemy is Area2D:
						continue # Skip this loop iteration if it's an area
					takeDamage(enemy, 20)


func takeDamage(target, amount):
	target.health -= amount
	target.health_Text.text = str(target.health)


func _on_area_2d_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()

	# Handle Enemy Type 1
	if parent.is_in_group("enemies1"):
		if not enemies1_list.has(parent):
			enemies1_list.append(parent)
		isCollidingE1 = true
		enemy1 = parent

	# Handle Enemy Type 2
	elif parent.is_in_group("enemies2"):
		if not enemies2_list.has(parent):
			enemies2_list.append(parent)
		isCollidingE2 = true
		enemy2 = parent

	# Handle Levels
	if area.name == "Level1":
		level = "one"
	elif area.name == "Level2":
		level = "two"

	# Handle Dash Ranges
	if "DashRange" in area.name:
		dash_areas.append(area)
		dashRange = true

	# Handle Health Upgrade
	if "healthUpgrade" in area.name:
		health += 50
		parent.queue_free()
		upgradeSound.play()

	# Handle Shield Upgrade
	if "shieldU" in area.name:
		canShield = true
		shieldCooldown.start()
		$shieldU.modulate = Color.WHITE_SMOKE
		parent.queue_free()
		upgradeSound.play()

	# Handle Score Upgrade
	if "scoreU" in area.name:
		scoreMultiply = true
		scoreCooldown.start()
		$scoreU.modulate = Color.WHITE_SMOKE
		parent.queue_free()
		upgradeSound.play()

	if "playerDetector" in area.name:
		canAssist = true
		assistCooldown.start()
		$assistU.modulate = Color.WHITE_SMOKE
		area.queue_free()
		upgradeSound.play()
		

func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()

	# Remove from Enemy 1 list
	if enemies1_list.has(parent):
		enemies1_list.erase(parent)
		if enemies1_list.is_empty():
			isCollidingE1 = false
			enemy1 = null

	# Remove from Enemy 2 list
	elif enemies2_list.has(parent):
		enemies2_list.erase(parent)
		if enemies2_list.is_empty():
			isCollidingE2 = false
			enemy2 = null

	# Clean up Level string
	if area.name == "Level1" and level == "one":
		level = ""
	elif area.name == "Level2" and level == "two":
		level = ""

	# Remove from Dash list
	if dash_areas.has(area):
		dash_areas.erase(area)
		if dash_areas.is_empty():
			dashRange = false


# Cooldowns
func _on_shield_cooldown_timeout() -> void:
	if canShield == true:
		$shieldU.modulate = Color.BLACK
		canShield = false # Replace with function body.


func _on_score_cooldown_timeout() -> void:
	if scoreMultiply == true:
		$scoreU.modulate = Color.BLACK
		scoreMultiply = false # Replace with function body. # Replace with function body.


func _on_assist_cooldown_timeout() -> void:
	if canAssist == true:
			$assistU.modulate = Color.BLACK
			canAssist = false # Replace with function body. # Replace with function body.

# ATTACK COOLDOWNS
func _on_dash_timeout() -> void:
	canDash = true # Replace with function body.


func _on_explosion_timeout() -> void:
	canExplode = true # Replace with function body.


func flash_color(color: Color, duration: float) -> void:
	animated_sprite.modulate = color
	await get_tree().create_timer(duration).timeout
	animated_sprite.modulate = Color.WHITE
