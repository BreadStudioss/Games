extends CharacterBody2D

@export var speed := 50.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $wait_time
@onready var customer_anim: AnimatedSprite2D = $AnimatedSprite2D

var store_routes = []
var current_route = []
var current_point := 0
var waiting := false
var previous_route := -1


func _ready():
	add_to_group("customer")

	store_routes = [
		[
			$"../CustomerPaths/Store1/one_three",
			$"../CustomerPaths/Store1/one_two",
			$"../CustomerPaths/Store1/one_one"
		],
		[
			$"../CustomerPaths/Store2/two_three",
			$"../CustomerPaths/Store2/two_two",
			$"../CustomerPaths/Store2/two_one"
		],
		[
			$"../CustomerPaths/Store3/three_three",
			$"../CustomerPaths/Store3/three_two",
			$"../CustomerPaths/Store3/three_one"
		]
	]

	pick_new_route()


func pick_new_route():
	var new_route = randi_range(0, store_routes.size() - 1)

	while new_route == previous_route:
		new_route = randi_range(0, store_routes.size() - 1)

	previous_route = new_route
	current_route = store_routes[new_route]
	current_point = 0
	waiting = false

	navigation_agent.target_position = current_route[0].global_position


func _physics_process(delta):

	if waiting:
		velocity = Vector2.ZERO
		customer_anim.stop()
		customer_anim.frame = 1
		return

	if navigation_agent.is_navigation_finished():

		if current_point < current_route.size() - 1:
			current_point += 1
			navigation_agent.target_position = current_route[current_point].global_position

		else:
			velocity = Vector2.ZERO
			waiting = true
			timer.start()
			return

	var next_position = navigation_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)

	# Animation direction
	if direction.y > 0:
		customer_anim.play("move_f")
		customer_anim.flip_h = direction.x < 0
	else:
		customer_anim.play("move_b")
		customer_anim.flip_h = direction.x < 0

	velocity = direction * speed
	move_and_slide()


func _on_wait_time_timeout():
	await get_tree().create_timer(3.0).timeout
	pick_new_route()
