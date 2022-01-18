extends GhostState

# we have to change how ghost is handled in the network
# instead of rpc-ing random changes we have to send the data every frame
# data like: current state, movement, animation frame, etc
func physics_update(delta):
	owner.Health.visible = false
	owner.forced_motion = false
	owner.stop_motion = false
	owner.HitboxCollision.disabled = false
	owner.ScaryAuraCollision.disabled = false
	owner.MOTION_SPEED = owner.speed
	if not global.is_playing_online or owner.is_network_master():
		owner.AnimatedSprite.visible = true
		owner.AnimatedSprite.modulate.a = .5
		if Input.is_action_just_pressed("ui_home"):
			if global.is_playing_online:
				owner.rpc("start_running")
			#else:
				#start_running()
	else:
		owner.AnimatedSprite.visible = false
