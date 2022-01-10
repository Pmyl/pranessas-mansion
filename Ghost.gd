extends "res://Player.gd"

enum GhostState {
	Walk,
	Run,
	HitStun
	HitRun
}

export var run_speed = 160
export var health = 100
export var stun_duration = 1.5
export var damage_tick = 0.1
export var initial_health_down_pitch = 1.6
export var health_down_pitch_rate = 0.05
export var health_down_max_pitch = 2.4

signal health_change(health)

onready var last_walking_health = health

var is_running = false
var state = GhostState.Walk
var light_hits = 0

func _ready():
	set_walk()
	$Health.text = str(health)

func _physics_process(_delta):
	match state:
		GhostState.Walk:
			$Health.visible = false
			forced_motion = false
			stop_motion = false
			$Hitbox/CollisionShape2D.disabled = false
			$ScaryAura/CollisionShape2D.disabled = false
			MOTION_SPEED = speed
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
			$Health.visible = false
			forced_motion = false
			stop_motion = false
			MOTION_SPEED = run_speed
			$Hitbox/CollisionShape2D.disabled = false
			$ScaryAura/CollisionShape2D.disabled = false
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1
			if Input.is_action_just_released("ui_home"):
				rpc("set_walk")

		GhostState.HitRun:
			$Health.visible = true
			forced_motion = true
			stop_motion = false
			MOTION_SPEED = run_speed
			$Hitbox/CollisionShape2D.disabled = true
			$ScaryAura/CollisionShape2D.disabled = false
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1

		GhostState.HitStun:
			$Health.visible = true
			forced_motion = false
			stop_motion = true
			$Hitbox/CollisionShape2D.disabled = true
			$ScaryAura/CollisionShape2D.disabled = true
			$AnimatedSprite.visible = true
			$AnimatedSprite.modulate.a = 1

remotesync func start_running():
	print("Ghost: RUUUUUUN")
	state = GhostState.Run

remotesync func set_walk():
	print("Ghost: I'm walking...")
	state = GhostState.Walk
	last_walking_health = health

remotesync func hit():
	print("Ghost: I'm Hit!")
	state = GhostState.HitRun
	if is_network_master():
		$HitRunTimer.start(5)

remotesync func hit_stun():
	print("Ghost: OMG!")
	state = GhostState.HitStun
	if is_network_master():
		$HitStunTimer.start(stun_duration)
		$HitTimer.start(damage_tick)

remotesync func update_health(new_health):
	health = new_health
	emit_signal("health_change", health)
	$Health.text = str(health)
	$SoundHealthDown.pitch_scale = min(
		health_down_max_pitch,
		initial_health_down_pitch + (last_walking_health - new_health) * health_down_pitch_rate
	)
	$SoundHealthDown.play()

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
		$HitTimer.stop()
		rpc("set_walk")

func _on_HitRunTimer_timeout():
	if light_hits == 0:
		rpc("set_walk")

func _on_HitStunTimer_timeout():
	if state == GhostState.HitStun:
		rpc("hit")

func _on_HitTimer_timeout():
	if state in [GhostState.HitStun, GhostState.HitRun] and light_hits > 0:
		rpc("update_health", health - light_hits)

func _on_Hurtbox_area_entered(_area):
	if is_network_master():
		lighted()

func _on_Hurtbox_area_exited(area):
	if is_network_master():
		unlighted()
