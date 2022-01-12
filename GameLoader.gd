extends Node

signal game_ready()
var players_done = []
var player_info = {}

func run(players):
	players_done = []
	player_info = players
	print("pre configure game")
	get_tree().set_pause(true) # Pre-pause
	# var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = load("res://Game.tscn").instance()
	get_node("/root").add_child(world)

	# Load my player
	# print("adding my player")
	# create_player(selfPeerID, global.player_name, selfPeerID == 1)

	# Load other players
	print("adding all players - count ", player_info.size())
	for p in player_info:
		create_player(p, player_info[p].name, player_info[p].is_ghost)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	print("I'm done preconfiguring")
	rpc_id(1, "done_preconfiguring")

func create_player(id, name, is_ghost):
	print("creating player ", id, " ", name, " ghost:", is_ghost)
	var player
	if is_ghost:
		player = preload("res://Ghost.tscn").instance()
	else:
		player = preload("res://Seeker.tscn").instance()
	player.set_name(str(id))
	player.set_network_master(id) # Will be explained later
	player.set_player_name(name)
	get_node("/root/Game/Players").add_child(player)

remotesync func done_preconfiguring():
	var who = get_tree().get_rpc_sender_id()
	print("Done preconfiguring message from ", who)
	
	if who == 1 and player_info.size() == 0:
		print("Starting solo game")
		rpc("post_configure_game")
	else:
		# Here are some checks you can do, for example
		assert(get_tree().is_network_server())
		assert(who in player_info) # Exists
		assert(not who in players_done) # Was not added yet

		players_done.append(who)

		if players_done.size() == player_info.size() || player_info.size() == 0:
			rpc("post_configure_game")

remotesync func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	print("check post configure sender: ", get_tree().get_rpc_sender_id())
	if 1 == get_tree().get_rpc_sender_id():
		print("unpausing")
		get_tree().set_pause(false)
		
		if 1 == get_tree().get_network_unique_id():
			get_node("/root/Game").rpc("start_game")
		emit_signal("game_ready")

