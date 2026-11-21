extends CharacterBody2D

@export var speed := 500.0
@export var bounce_force := 900.0
@export var bounce_duration := 0.15
@export var bounce_arc_strength := 0.5
@export var damage := 5

@onready var player = $"../Player"

var target_enemy: Node2D
var last_enemy: Node2D

var bouncing := false
var bounce_dir := Vector2.ZERO
var bounce_timer := 0.0


func _ready():
	find_target()
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta):
	if not player.canAssist and not bouncing:
		velocity = Vector2.ZERO
		move_and_slide()
		
		var detector = get_node_or_null("playerDetector")
		if detector == null:
			queue_free()
		return

	# --- Bounce movement ---
	if bouncing:
		velocity = bounce_dir * bounce_force
		bounce_timer -= delta
		
		if bounce_timer <= 0:
			bouncing = false
			find_target()
	else:
		if target_enemy == null or not is_instance_valid(target_enemy):
			find_target()
			
			if target_enemy == null:
				velocity = Vector2.ZERO
				move_and_slide()
				return
		
		var dir = (target_enemy.global_position - global_position).normalized()
		velocity = dir * speed

	move_and_slide()


func get_all_enemies() -> Array:
	var enemies := []
	enemies += get_tree().get_nodes_in_group("enemies1")
	enemies += get_tree().get_nodes_in_group("enemies2")
	return enemies


func find_target():
	var enemies = get_all_enemies()
	
	if enemies.size() == 0:
		target_enemy = null
		return

	var possible := []
	for e in enemies:
		if e != last_enemy:
			possible.append(e)

	if possible.size() == 0:
		possible = enemies

	target_enemy = possible.pick_random()


# 🔥 KEY FIX FUNCTION
func get_enemy_from_area(area):
	# If the area itself is the enemy
	if area.is_in_group("enemies1") or area.is_in_group("enemies2"):
		if area.has_method("take_damage"):
			return area
	
	# Otherwise try parent
	var parent = area.get_parent()
	if parent and (parent.is_in_group("enemies1") or parent.is_in_group("enemies2")):
		return parent
	
	return null


func _on_hitbox_area_entered(area):
	var enemy = get_enemy_from_area(area)
	if enemy == null:
		return

	# ✅ Always use REAL enemy node
	last_enemy = enemy

	find_target()
	
	# ✅ Reliable damage call
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# --- Bounce direction ---
	if target_enemy:
		var dir = (target_enemy.global_position - global_position).normalized()
		var perp = Vector2(-dir.y, dir.x) * randf_range(-bounce_arc_strength, bounce_arc_strength)
		bounce_dir = (dir + perp).normalized()
	else:
		var fallback = global_position - enemy.global_position
		if fallback.length() == 0:
			fallback = Vector2.RIGHT
		bounce_dir = fallback.normalized()

	bouncing = true
	bounce_timer = bounce_duration
