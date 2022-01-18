class_name GhostState
extends State

var ghost: Ghost

func _ready() -> void:
	yield(owner, "ready")
	ghost = owner as Ghost
	assert(ghost != null)
