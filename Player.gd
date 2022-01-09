extends KinematicBody2D

const MOTION_SPEED = 90.0

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()


func _physics_process(_delta):
	var motion = Vector2()

	if is_network_master():
		if Input.is_action_pressed("left"):
			motion += Vector2(-1, 0)
		if Input.is_action_pressed("right"):
			motion += Vector2(1, 0)
		if Input.is_action_pressed("up"):
			motion += Vector2(0, -1)
		if Input.is_action_pressed("down"):
			motion += Vector2(0, 1)

		rset("puppet_motion", motion)
		rset("puppet_pos", position)
	else:
		position = puppet_pos
		motion = puppet_motion

	# FIXME: Use move_and_slide
	motion = move_and_slide(motion * MOTION_SPEED)
	if not is_network_master():
		puppet_pos = position # To avoid jitter


func set_player_name(new_name):
	get_node("Label").set_text(new_name)


remotesync func set_initial_position(pos):
	if is_network_master():
		position = pos
		rset("puppet_pos", position)


func _ready():
	puppet_pos = position
