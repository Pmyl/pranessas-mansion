extends Node2D

signal game_over()
var seeker_positions = []

func _ready():
	var selfPeerID = get_tree().get_network_unique_id()
	if selfPeerID == 1:
		seeker_positions.append($Seeker1Position.position)
		seeker_positions.append($Seeker2Position.position)
		seeker_positions.append($Seeker3Position.position)
		seeker_positions.append($Seeker4Position.position)
		seeker_positions.shuffle()

var dead_seekers = 0

remotesync func start_game():
	print("Game started!")
	var selfPeerID = get_tree().get_network_unique_id()
	var players = get_node("Players").get_children()

	if selfPeerID == 1:
		for p in players:
			var pos
			if "ghosts" in p.get_groups():
				p.connect("on_death", self, "trigger_seekers_win")
				pos = $GhostPosition.position
			else:
				p.connect("on_death", self, "check_ghost_win")
				p.connect("on_revive", self, "revived")
				pos = seeker_positions.pop_front()
			print("setting position of player ", p.name, " to: ", pos)
			p.rpc("set_initial_position", pos)
	
	for p in players:
		if "ghosts" in p.get_groups():
			$GhostHealth.set_ghost(p)

remotesync func seekers_win():
	emit_signal("game_over")

remotesync func ghost_win():
	emit_signal("game_over")

func trigger_seekers_win():
	rpc("seekers_win")

func check_ghost_win():
	dead_seekers += 1
	var seekers = get_node("Players").get_children().size() - 1
	print("Check ghost win - Dead seekers: ", dead_seekers, " Current seekers: ", seekers)
	if dead_seekers == seekers:
		rpc("ghost_win")

func revived():
	dead_seekers -= 1
