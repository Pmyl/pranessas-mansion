extends KinematicBody2D

export var speed = 90
var forced_motion = false
var stop_motion = false
var motion = Vector2()
var last_direction = Vector2.DOWN

onready var MOTION_SPEED = speed

puppet var puppet_pos = Vector2()
puppet var puppet_motion = Vector2()


func _physics_process(_delta):
	if is_network_master():
		if stop_motion:
			motion = Vector2()
		else:
			if forced_motion:
				motion = last_direction
			else:
				motion = Vector2()

			var newMotion = Vector2()
			if Input.is_action_pressed("left"):
				newMotion += Vector2(-1, 0)
			if Input.is_action_pressed("right"):
				newMotion += Vector2(1, 0)
			if Input.is_action_pressed("up"):
				newMotion += Vector2(0, -1)
			if Input.is_action_pressed("down"):
				newMotion += Vector2(0, 1)
			
			newMotion = newMotion.normalized()

			if newMotion.length() != 0:
				motion = newMotion
				last_direction = motion

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
