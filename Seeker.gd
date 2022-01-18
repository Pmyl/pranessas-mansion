extends "res://Player.gd"

export var torch_on_walk_speed = 70
export var min_ghost_detection = 100
export var close_ghost_detection = 50
export var detection_close_audio_pitch = 0.18
export var detection_far_audio_pitch = 0.1

signal on_death(body)
signal on_revive()

var ghost = null
var ghost_distance = 0
var dead = false
var game_ended = false
var position_to_follow_path = null

func _ready():
	$GhostDetection/CollisionShape2D.shape.radius = min_ghost_detection

func _physics_process(_delta):
	if (not global.is_playing_online or is_network_master()) and not dead and not game_ended:
		if position_to_follow_path == null:
			var angle = position.angle_to_point(get_global_mouse_position())
			if global.is_playing_online:
				rpc("set_torch_rotation", angle)
			else:
				set_torch_rotation(angle)
			
			if Input.is_action_just_pressed("click"):
				$TorchLight.toggle()
			
			if $TorchLight.emits_light:
				MOTION_SPEED = torch_on_walk_speed
			else:
				MOTION_SPEED = speed
			
			# To fix: This has to happen also when the seeker is dead
			if ghost != null:
				ghost_distance = global_position.distance_to(ghost.global_position)

				if ghost_distance <= close_ghost_detection:
					$GhostDetectionAudio.pitch_scale = detection_close_audio_pitch
					$GhostDetectionSprite.play("close")
				else:
					$GhostDetectionAudio.pitch_scale = detection_far_audio_pitch
					$GhostDetectionSprite.play("far")
		else:
			position = get_node(position_to_follow_path).position
			


remotesync func set_torch_rotation(angle):
	$TorchLight.call_deferred("set_rotation", angle)


func _on_Hurtbox_area_entered(area):
	if (not global.is_playing_online or is_network_master()) and not game_ended:
		if "ghosts" in area.get_parent().get_groups():
			if global.is_playing_online:
				area.get_parent().rpc("ko_seeker", get_path())
			else:
				area.get_parent().ko_seeker(get_path())
			$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
			print("Player ", name, ": DED")
			#if global.is_playing_online:
			#	rpc("player_hit", area.get_parent().get_path())
			#else:
			#	player_hit()

remotesync func force_follow(path):
	if not global.is_playing_online or is_network_master():
		position_to_follow_path = path
		stop_motion = true

remotesync func released():
	if not global.is_playing_online or is_network_master():
		dead = true
		position_to_follow_path = null

#remotesync func player_hit(ghost_path):
#	if not game_ended:
#		dead = true
#		follow_ghost = get_node(ghost_path)
#		if global.is_host:
#			emit_signal("on_death", self)


func _on_GhostDetection_area_entered(area):
	if (not global.is_playing_online or is_network_master()) and not game_ended:
		if not $GhostDetectionAudio.playing:
			$GhostDetectionAudio.pitch_scale = detection_far_audio_pitch
			$GhostDetectionAudio.play()
		ghost = area


func _on_GhostDetection_area_exited(_area):
	if (not global.is_playing_online or is_network_master()) and not game_ended:
		ghost = null
		$GhostDetectionSprite.play("none")
		$GhostDetectionAudio.stop()

func declared_winner():
	$AnimatedSprite.play("SeekerVictory")
	stop_motion = true
	game_ended = true

func declared_loser():
	stop_motion = true
	game_ended = true

remotesync func add_battery_charge():
	$TorchLight.refill()
