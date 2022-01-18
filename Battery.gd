extends Area2D

export var spawn_on_ready = false
var active = false

func _ready():
	if spawn_on_ready:
		if global.is_playing_online:
			rpc("spawn")
		else:
			spawn()

remotesync func spawn():
	if not active:
		$AnimatedSprite.play("Spawn")
		$AnimatedSprite.connect("animation_finished", self, "_activate", [], CONNECT_ONESHOT)
		
		if global.is_host:
			$TimeToLive.start(40)


remotesync func destroy():
	active = false
	# $AnimatedSprite.play("Disappear")
	# wait for animation to end
	queue_free()


func _activate():
	active = true
	$AnimatedSprite.play("Idle")


func _on_Battery_body_entered(body):
	if (not global.is_playing_online or body.is_network_master()) and active and not "ghosts" in body.get_groups():
		if global.is_playing_online:
			rpc("destroy")
		else:
			destroy()
		body.call_deferred("add_battery_charge")


func _on_TimeToLive_timeout():
	if global.is_playing_online:
		rpc("destroy")
	else:
		destroy()
