class_name Ghost
extends "res://Player.gd"

enum GhostState {
	Walk,
	Run,
	HitStun
	HitRun,
	KillRun,
	Won,
	Lost
}

export var run_speed = 160
export var health = 100
export var damage_per_second = 10
export var stun_duration = 1.5
export var initial_health_down_pitch = 1.6
export var health_down_pitch_rate = 0.05
export var health_down_max_pitch = 2.4
export var kill_run_time := 3.0

signal health_change(health)
signal on_death()

onready var last_walking_health = health
onready var Health = $Health
onready var HitboxCollision = $Hitbox/CollisionShape2D
onready var ScaryAuraCollision = $ScaryAura/CollisionShape2D
onready var AnimatedSprite = $AnimatedSprite
onready var HurtboxCollision = $Hurtbox/CollisionShape2D

puppet var puppet_visible_on_hit = false

var is_running = false
var state = GhostState.Walk
var light_hits = 0
var game_ended = false
var has_been_hit = false
var visible_on_hit = false
var damage_tick = 0.1
# has to be higher than damage_tick
var visibility_time_on_hit = 0.3
var is_dragging_seeker = null

func _ready():
	set_walk()
	Health.text = str(health)

func _physics_process(_delta):
	if global.is_playing_online and not is_network_master():
		visible_on_hit = puppet_visible_on_hit

	match state:
		GhostState.Walk:
			Health.visible = false
			forced_motion = false
			stop_motion = false
			HitboxCollision.disabled = false
			ScaryAuraCollision.disabled = false
			MOTION_SPEED = speed
			if not global.is_playing_online or is_network_master():
				AnimatedSprite.visible = true
				AnimatedSprite.modulate.a = .5
				if Input.is_action_just_pressed("ui_home"):
					if global.is_playing_online:
						rpc("start_running")
					else:
						start_running()
			else:
				AnimatedSprite.visible = false

		GhostState.Run:
			Health.visible = false
			forced_motion = false
			stop_motion = false
			MOTION_SPEED = run_speed
			HitboxCollision.disabled = false
			ScaryAuraCollision.disabled = false
			AnimatedSprite.visible = true
			AnimatedSprite.modulate.a = 1
			if Input.is_action_just_released("ui_home"):
				if global.is_playing_online:
					rpc("set_walk")
				else:
					set_walk()

		GhostState.HitRun:
			forced_motion = true
			stop_motion = false
			MOTION_SPEED = run_speed
			HitboxCollision.disabled = true
			ScaryAuraCollision.disabled = false
			if global.is_playing_online and not is_network_master():
				Health.visible = visible_on_hit
				AnimatedSprite.visible = visible_on_hit
				AnimatedSprite.modulate.a = 1
			else:
				AnimatedSprite.visible = true
				Health.visible = true
				AnimatedSprite.modulate.a = 1 if visible_on_hit else .5

		GhostState.HitStun:
			forced_motion = false
			stop_motion = true
			HitboxCollision.disabled = true
			ScaryAuraCollision.disabled = true
			if global.is_playing_online and not is_network_master():
				AnimatedSprite.visible = visible_on_hit
				Health.visible = visible_on_hit
				AnimatedSprite.modulate.a = 1
			else:
				AnimatedSprite.visible = true
				Health.visible = true
				AnimatedSprite.modulate.a = 1 if visible_on_hit else .5

		GhostState.KillRun:
			forced_motion = true
			stop_motion = false
			MOTION_SPEED = run_speed
			HitboxCollision.disabled = true
			ScaryAuraCollision.disabled = false
			AnimatedSprite.visible = true
			Health.visible = true
			AnimatedSprite.modulate.a = 1
		
		GhostState.Won:
			stop_motion = true
			AnimatedSprite.visible = true
			AnimatedSprite.modulate.a = 1
			AnimatedSprite.play("GhostVictory")
			HitboxCollision.disabled = true
			HurtboxCollision.disabled = true
			ScaryAuraCollision.disabled = true
		
		GhostState.Lost:
			stop_motion = true
			AnimatedSprite.visible = true
			AnimatedSprite.modulate.a = 1
			HitboxCollision.disabled = true
			HurtboxCollision.disabled = true
			ScaryAuraCollision.disabled = true

remotesync func start_running():
	print("Ghost: RUUUUUUN")
	state = GhostState.Run

remotesync func set_walk():
	if is_dragging_seeker != null and (not global.is_playing_online or is_network_master()):
		if global.is_playing_online:
			get_node(is_dragging_seeker).rpc("released")
		else:
			get_node(is_dragging_seeker).released()
		is_dragging_seeker = null
			
	print("Ghost: I'm walking...")
	state = GhostState.Walk
	last_walking_health = health

remotesync func hit():
	print("Ghost: I'm Hit!")
	state = GhostState.HitRun
	if not global.is_playing_online or is_network_master():
		$HitRunTimer.start(5)

remotesync func hit_stun():
	print("Ghost: OMG!")
	state = GhostState.HitStun
	if not global.is_playing_online or is_network_master():
		if is_dragging_seeker != null:
			if global.is_playing_online:
				get_node(is_dragging_seeker).rpc("released")
			else:
				get_node(is_dragging_seeker).released()
			is_dragging_seeker = null
				
		$HitStunTimer.start(stun_duration)
		$HitTickTimer.start(damage_tick)

remotesync func update_health(new_health):
	health = new_health
	emit_signal("health_change", health)
	Health.text = str(health)
	$SoundHealthDown.pitch_scale = min(
		health_down_max_pitch,
		initial_health_down_pitch + (last_walking_health - new_health) * health_down_pitch_rate
	)
	$SoundHealthDown.play()
	if health == 0:
		print("Ghost: I'm dead!")
		emit_signal("on_death")

func keep_hit():
	$HitRunTimer.start(5)

remotesync func lighted():
	if not global.is_playing_online or is_network_master():
		visible_on_hit = true
		if global.is_playing_online:
			rset("puppet_visible_on_hit", true)
		$HitVisibilityTimer.start(visibility_time_on_hit)
		has_been_hit = true
		match state:
			GhostState.HitRun:
				keep_hit()
			GhostState.HitStun, GhostState.Won, GhostState.Lost:
				pass
			_:
				if global.is_playing_online:
					rpc("hit_stun")
				else:
					hit_stun()

func _on_HitRunTimer_timeout():
	if light_hits == 0 and state == GhostState.HitRun:
		if global.is_playing_online:
			rpc("set_walk")
		else:
			set_walk()

func _on_HitStunTimer_timeout():
	if state == GhostState.HitStun:
		if global.is_playing_online:
			rpc("hit")
		else:
			hit()

func _on_HitTickTimer_timeout():
	if not state in [GhostState.HitStun, GhostState.HitRun]:
		$HitTickTimer.stop()
	elif has_been_hit:
		var new_health = max(0, health - damage_tick * damage_per_second)
		if global.is_playing_online:
			rpc("update_health", new_health)
		else:
			update_health(new_health)
		has_been_hit = false
		

func declared_winner():
	state = GhostState.Won


func declared_loser():
	state = GhostState.Lost


func _on_HitVisibilityTimer_timeout():
	visible_on_hit = false
	if global.is_playing_online:
		rset("puppet_visible_on_hit", false)

remotesync func ko_seeker(seeker_path):
	if not global.is_playing_online or is_network_master():
		if global.is_playing_online:
			get_node(seeker_path).rpc("force_follow", get_path())
		else:
			get_node(seeker_path).force_follow(get_path())
		state = GhostState.KillRun
		$KillRunTimer.start(kill_run_time)
		# implement state machine with enter/exit and implement the release
		# in the KillRun exit function. is_dragging_seeker should not exists
		# right now it's polluting random functions in this file
		is_dragging_seeker = seeker_path


func _on_KillRunTimer_timeout():
	if state == GhostState.KillRun:
		set_walk()
