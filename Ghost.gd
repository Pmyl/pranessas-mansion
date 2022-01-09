extends "res://Player.gd"

var is_running = false

func _ready():
	if is_network_master():
		$AnimatedSprite.visible = true
	else:
		$AnimatedSprite.visible = false

func _physics_process(_delta):
	if Input.is_action_just_pressed("ui_home"):
		rpc("start_running")
	elif Input.is_action_just_released("ui_home"):
		rpc("stop_running")

remotesync func start_running():
	MOTION_SPEED = 160
	$AnimatedSprite.visible = true

remotesync func stop_running():
	MOTION_SPEED = 90
	if not is_network_master():
		$AnimatedSprite.visible = false
