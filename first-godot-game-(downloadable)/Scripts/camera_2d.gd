extends Camera2D

@export var decay := 0.8
@export var max_offset := Vector2(20, 20) # safer default
@export var max_roll := 0.05

var trauma := 0.0
var trauma_power := 2
var noise = FastNoiseLite.new()
var noise_y := 0.0

func _ready():	
	# Reset ONLY visual shake properties
	offset = Vector2.ZERO
	rotation = 0
	
	randomize()
	noise.seed = randi()
	noise.frequency = 0.5

func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		_apply_shake(delta)
	else:
		offset = Vector2.ZERO
		rotation = 0

func _apply_shake(delta):
	var amount = pow(trauma, trauma_power)
	noise_y += delta * 60  # smoother movement
	
	var x = max_offset.x * amount * noise.get_noise_2d(0, noise_y)
	var y = max_offset.y * amount * noise.get_noise_2d(100, noise_y)
	var r = max_roll * amount * noise.get_noise_2d(200, noise_y)
	
	offset = Vector2(x, y)
	rotation = r

func add_trauma(amount: float):
	trauma = clamp(trauma + amount, 0.0, 1.0)
