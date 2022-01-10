extends Node2D

var seeker_positions = []

func _ready():
	var selfPeerID = get_tree().get_network_unique_id()
	if selfPeerID == 1:
		seeker_positions.append($Seeker1Position.position)
		seeker_positions.append($Seeker2Position.position)
		seeker_positions.append($Seeker3Position.position)
		seeker_positions.append($Seeker4Position.position)
		seeker_positions.shuffle()

remotesync func start_game():
	print("Game started!")
	var selfPeerID = get_tree().get_network_unique_id()
	var players = get_node("Players").get_children()

	if selfPeerID == 1:
		for p in players:
			var pos
			if "ghosts" in p.get_groups():
				pos = $GhostPosition.position
			else:
				pos = seeker_positions.pop_front()
			print("setting position of player ", p.name, " to: ", pos)
			p.rpc("set_initial_position", pos)
	
	for p in players:
		if "ghosts" in p.get_groups():
			$GhostHealth.set_ghost(p)
