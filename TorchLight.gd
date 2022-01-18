extends Node2D

export (Array) var textures = []
export var consume := 10.0
export var max_charge := 100.0
export var no_charge_amount := -20.0
export var min_charge := 20.0
var is_on = true
var emits_light = false
# raycasts has to start from behind to avoid clipping small walls, 12 is the amount
# or cast_to.y increased in every raycast. This is used for calculations when reducing
# the size
var raycasts_extended_size := 12

onready var TorchLight = $TorchLight
onready var charge = max_charge
onready var raycasts = [$RayCast, $LeftRayCast, $RightRayCast]
onready var raycasts_size = [
	$RayCast.cast_to.y - raycasts_extended_size,
	$LeftRayCast.cast_to.y - raycasts_extended_size,
	$RightRayCast.cast_to.y - raycasts_extended_size
]

puppet var puppet_charge = max_charge
puppet var puppet_is_on = is_on

func _ready():
	if global.is_playing_online and is_network_master():
		rset("puppet_charge", charge)

func _physics_process(delta):
	if not global.is_playing_online or is_network_master():
		if is_on and charge > no_charge_amount:
			charge -= consume * delta
			if global.is_playing_online:
				rset("puppet_charge", charge)
			
			for raycast in raycasts:
				light_targets(raycast)
	else:
		charge = puppet_charge
		is_on = puppet_is_on
	
	if is_on and charge > no_charge_amount:
		emits_light = true
		TorchLight.enabled = true
		
		if charge < min_charge:
			TorchLight.texture = textures.back()
			for i in range(raycasts.size()):
				var raycast = raycasts[i]
				var raycast_size = raycasts_size[i]
				raycast.cast_to.y = raycast_size * min_charge / max_charge + raycasts_extended_size
		else:
			var charge_reference = charge - min_charge
			var total_charge_reference = max_charge - min_charge
			var index_reference = charge_reference * textures.size() / total_charge_reference
			TorchLight.texture = textures[floor(textures.size() - index_reference)]
			for i in range(raycasts.size()):
				var raycast = raycasts[i]
				var raycast_size = raycasts_size[i]
				raycast.cast_to.y = raycast_size * charge / max_charge + raycasts_extended_size
	else:
		emits_light = false
		TorchLight.enabled = false
	

func light_targets(raycast):
	var objects_collide = []
	while raycast.is_colliding():
		var obj = raycast.get_collider()
		if "obstacles" in obj.get_groups():
			break
		objects_collide.append(obj)
		raycast.add_exception(obj)
		raycast.force_raycast_update()

	for obj in objects_collide:
		if global.is_playing_online:
			obj.get_parent().rpc("lighted")
		else:
			obj.get_parent().lighted()
		raycast.remove_exception(obj)


func refill():
	charge = max_charge


func toggle():
	is_on = !is_on
	if global.is_playing_online:
		rset("puppet_is_on", is_on)

