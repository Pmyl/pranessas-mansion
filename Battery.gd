extends Area2D


var active = false


remotesync func spawn():
	if not active:
		$AnimatedSprite.play("Spawn")
		$AnimatedSprite.connect("animation_finished", self, "_activate", [], CONNECT_ONESHOT)
		
		if get_tree().get_network_unique_id() == 1:
			$TimeToLive.start(40)


remotesync func destroy():
	active = false
	$AnimatedSprite.play("Invisible")


func _activate():
	active = true
	$AnimatedSprite.play("Idle")


func _on_Battery_body_entered(body):
	if body.is_network_master() and active and not "ghosts" in body.get_groups():
		rpc("destroy")
		body.call_deferred("add_battery_charge")


func _on_TimeToLive_timeout():
	rpc("destroy")
