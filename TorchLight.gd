extends Area2D

export var consume = 10
export var max_charge = 100
export var no_charge_amount = -20
export var min_charge = 20
var is_on = false
var emits_light = false

onready var charge = max_charge
onready var torch_light_size = $TorchLight.region_rect.size.y
onready var collision_x = $LightCollision.position.x
onready var collision_size_x = $LightCollision.shape.extents.x

puppet var puppet_charge = max_charge
puppet var puppet_is_on = is_on

func _ready():
	if is_network_master():
		rset("puppet_charge", charge)

func _physics_process(delta):
	if is_network_master():
		if is_on and charge > no_charge_amount:
			charge -= consume * delta
			rset("puppet_charge", charge)
	else:
		charge = puppet_charge
		is_on = puppet_is_on
	
	if is_on and charge > no_charge_amount:
		emits_light = true
		$TorchLight.visible = true
		$LightCollision.disabled = false
		$TorchCollision.disabled = false
		$TorchLight.region_rect.size.y = clamp(torch_light_size * charge / max_charge, min_charge, torch_light_size)
		$LightCollision.shape.extents.x = collision_size_x * charge / max_charge
		$LightCollision.position.x = collision_x + (collision_size_x - collision_size_x * charge / max_charge)
	else:
		emits_light = false
		$TorchLight.visible = false
		$LightCollision.disabled = true
		$TorchCollision.disabled = true
	

func toggle():
	is_on = !is_on
	rset("puppet_is_on", is_on)
