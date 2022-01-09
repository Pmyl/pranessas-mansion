extends "res://Player.gd"


func _physics_process(_delta):
	if is_network_master():
		var angle = position.angle_to_point(get_global_mouse_position())
		rpc("set_torch_rotation", angle)

remotesync func set_torch_rotation(angle):
	$TorchLight.call_deferred("set_rotation", angle)
