extends CharacterBody2D

const SPEED = 50.0
@onready var anim = $animator


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		face_direction(direction)
	else:
		velocity = Vector2.ZERO
		anim.play("idle")

	move_and_slide()
	
func face_direction(dir : Vector2):
	if (dir.x > 0 and dir.y > 0):
		anim.play("run_f")
		anim.flip_h = true
	elif (dir.x < 0 and dir.y < 0):
		anim.play("run_b")
		anim.flip_h = false
	elif (dir.x < 0 and dir.y > 0):
		anim.play("run_f")
		anim.flip_h = false
	elif dir.x > 0 and dir.y < 0:
		anim.play("run_b")
		anim.flip_h = true
		
	if Input.is_action_pressed("move_up"):
		anim.play("run_b")
	elif Input.is_action_pressed("move_down"):
		anim.play("run_f");
	elif Input.is_action_just_pressed("move_right"):
		anim.play("run_f");
		anim.flip_h = true
	elif Input.is_action_pressed("move_left"):
		anim.play("run_f")
		anim.flip_h = false
