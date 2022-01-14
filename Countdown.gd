extends Control


signal on_timeout()


func _ready():
	$Timer.wait_time = global.game_time
	_show_time(global.game_time)


func start():
	$Timer.start()
	$Tick.start(0.1)
	$TickSwitch.start(2)


func stop():
	$Timer.stop()
	$Tick.stop()
	$TickSwitch.stop()


func time_to_string(time):
	return "%01d:%02d" % [time / 60, int(time) % 60]


func _on_Tick_timeout():
	_show_time($Timer.time_left)


func _show_time(time):
	$Label.text = time_to_string(time)


func _on_TickSwitch_timeout():
	$Tick.stop()
	$Tick.start(1)


func _on_Timer_timeout():
	emit_signal("on_timeout")
