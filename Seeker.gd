extends "res://Player.gd"

export var torch_on_walk_speed = 70
export var min_ghost_detection = 100
export var close_ghost_detection = 50
export var detection_close_audio_pitch = 0.18
export var detection_far_audio_pitch = 0.1

signal on_death()
signal on_revive()

var ghost = null
var ghost_distance = 0

func _ready():
	$GhostDetection/CollisionShape2D.shape.radius = min_ghost_detection

func _physics_process(_delta):
	if is_network_master():
		var angle = position.angle_to_point(get_global_mouse_position())
		rpc("set_torch_rotation", angle)
		
		if Input.is_action_just_pressed("click"):
			$TorchLight.toggle()
		
		if $TorchLight.emits_light:
			MOTION_SPEED = torch_on_walk_speed
		else:
			MOTION_SPEED = speed
		
		if ghost != null:
			ghost_distance = global_position.distance_to(ghost.global_position)

			if ghost_distance <= close_ghost_detection:
				$GhostDetectionAudio.pitch_scale = detection_close_audio_pitch
				$GhostDetectionSprite.play("close")
			else:
				$GhostDetectionAudio.pitch_scale = detection_far_audio_pitch
				$GhostDetectionSprite.play("far")


remotesync func set_torch_rotation(angle):
	$TorchLight.call_deferred("set_rotation", angle)


func _on_Hurtbox_area_entered(_area):
	if is_network_master():
		print("Player ", name, ": DED")
		rpc_id(1, "player_hit")

remotesync func player_hit():
	emit_signal("on_death")


func _on_GhostDetection_area_entered(area):
	if is_network_master():
		if not $GhostDetectionAudio.playing:
			$GhostDetectionAudio.pitch_scale = detection_far_audio_pitch
			$GhostDetectionAudio.play()
		ghost = area


func _on_GhostDetection_area_exited(_area):
	if is_network_master():
		ghost = null
		$GhostDetectionSprite.play("none")
		$GhostDetectionAudio.stop()
