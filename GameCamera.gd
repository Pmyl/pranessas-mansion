extends Camera2D

export var zoom_time = 2

onready var original_zoom_x = zoom.x
onready var original_zoom_y = zoom.y
onready var original_position = position

onready var target_zoom_x = zoom.x
onready var target_zoom_y = zoom.y
onready var target_position = position

func _process(delta):
	zoom.x = lerp(zoom.x, target_zoom_x, delta)
	zoom.y = lerp(zoom.y, target_zoom_y, delta)
	position = lerp(position, target_position, delta)

func zoom_to(body):
	target_zoom_x = original_zoom_x/2
	target_zoom_y = original_zoom_y/2
	target_position = body.position
	$ZoomTimer.start(zoom_time)


func restore_zoom():
	target_zoom_x = original_zoom_x
	target_zoom_y = original_zoom_y
	target_position = original_position


func _on_ZoomTimer_timeout():
	restore_zoom()
