extends Node2D


remotesync func start_game():
	print("Game started!")
	var selfPeerID = get_tree().get_network_unique_id()
	if selfPeerID == 1:
		var players = get_node("Players").get_children()
		var initial_x = 100
		for p in players:
			var pos = Vector2(initial_x, 100)
			print("setting position of player ", p.name, " to: ", pos)
			p.rpc("set_initial_position", pos)
			initial_x += 300
