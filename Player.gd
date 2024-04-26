extends CharacterBody2D

var speed = 100
var acceleration = 1000

var water_material = preload("res://assets/player/WaterMaterial.tres")

@onready var animated_sprite = $AnimatedSprite2D
@onready var water_particles = $WaterParticles
@onready var water_trailing_particles = $WaterTrailingParticles
@onready var world = get_parent().get_node("World")

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	$Username.text = ServerConnection.multiplayer_bridge.get_user_presence_for_peer(name.to_int()).username
	if is_multiplayer_authority(): $Camera2D.enabled = true
	
func _process(delta):
	animate()

func _physics_process(delta):
	if is_multiplayer_authority(): move(delta)
	
func move(delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = velocity.move_toward(speed * (0.5 if world.is_in_water(position) else 1) * direction, acceleration * delta)
	move_and_slide()

func animate():
	if world.is_in_water(position):
		animated_sprite.material = water_material
		water_particles.visible = true
		if abs(velocity.x) < 10 and abs(velocity.y) < 10:
			water_particles.emitting = false
			water_trailing_particles.emitting = false
		else:
			water_particles.emitting = true
			water_trailing_particles.emitting = true
	else:
		animated_sprite.material = null
		water_particles.emitting = false
		water_trailing_particles.emitting = false
		water_particles.visible = false
		
	if abs(velocity.x) < 10 and abs(velocity.y) < 10:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("walking")
		if velocity.x != 0:
			animated_sprite.scale.x=sign(velocity.x)

func toggle_speaking(is_speaking):
	$Speaking.visible = is_speaking

