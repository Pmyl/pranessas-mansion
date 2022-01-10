extends Label

func set_ghost(ghost):
	ghost.connect("health_change", self, "_on_health_change")

func _on_health_change(health):
	text = str(health)
