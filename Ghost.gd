extends "res://Player.gd"

enum GhostState {
	Walk,
	Run,
	HitStun
	HitRun
}

var is_running = false
var health = 100
var state = GhostState.Walk
var light_hits = 0

func _ready():
	set_walk()

func _physics_process(_delta):
	match state:
		GhostState.Walk:
			forced_motion = false
			stop_motion = false
			MOTION_SPEED = 90
			if is_network_master():
				$AnimatedSprite.visible = true
				$AnimatedSprite.modulate.a = .5
				if Input.is_action_just_pressed("ui_home"):
					rpc("start_running")
				elif Input.is_action_just_released("ui_home"):
					rpc("stop_running")
			else:
				$AnimatedSprite.visible = false

		GhostState.Run:
			forced_motion = false
			stop_motion = false
			MOTION_SPEED = 160
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1
			if Input.is_action_just_released("ui_home"):
				rpc("set_walk")

		GhostState.HitRun:
			forced_motion = true
			stop_motion = false
			MOTION_SPEED = 160
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1

		GhostState.HitStun:
			forced_motion = false
			stop_motion = true
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1

remotesync func start_running():
	print("Ghost: RUUUUUUN")
	state = GhostState.Run

remotesync func set_walk():
	print("Ghost: I'm walking...")
	state = GhostState.Walk

remotesync func hit():
	print("Ghost: I'm Hit!")
	state = GhostState.HitRun
	if is_network_master():
		$HitRunTimer.start(5)

remotesync func hit_stun():
	print("Ghost: OMG!")
	state = GhostState.HitStun
	if is_network_master():
		$HitStunTimer.start(1)

func keep_hit():
	$HitRunTimer.start(5)

func lighted():
	print("lighted")
	light_hits += 1
	match state:
		GhostState.HitRun:
			keep_hit()
		GhostState.HitStun:
			pass
		_:
			rpc("hit_stun")

func unlighted():
	print("unlighted")
	light_hits -= 1
	
	if light_hits == 0 and state == GhostState.HitStun:
		rpc("set_walk")

func _on_Hitbox_area_entered(_area):
	if is_network_master():
		lighted()

func _on_Hitbox_area_exited(area):
	if is_network_master():
		unlighted()

func _on_HitRunTimer_timeout():
	if light_hits == 0:
		rpc("set_walk")

func _on_HitStunTimer_timeout():
	if state == GhostState.HitStun:
		rpc("hit")
