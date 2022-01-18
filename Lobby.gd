extends Node

signal player_registered(info)
signal player_disconnected(info)
signal connected_to_server()
signal player_is_ghost(id)
signal game_ready()
signal game_finished()
var my_info
var ghost_id
var player_info = {}
var players_done = []

func start():
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_ok")
	# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connected_fail")
	# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	var current_id = get_tree().get_network_unique_id()
	my_info = { id = current_id, name = global.player_name, is_ghost = current_id == 1 }
	player_info[current_id] = my_info

	emit_signal("player_registered", my_info)

remotesync func set_ghost_id(id):
	print("Now ghost is: ", id)
	
	for pid in player_info:
		if player_info[pid].is_ghost:
			player_info[pid].is_ghost = false
			ghost_id = pid

	ghost_id = id
	player_info[ghost_id].is_ghost = true
	
	emit_signal("player_is_ghost", id)

remotesync func close_connection():
	get_tree().network_peer = null
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Main.tscn")

func _player_connected(id):
	print("player connected: sending my info (", my_info, ") to them (id: ", id, ")")
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id):
	print("disconnect player", id)
	emit_signal("player_disconnected", player_info[id])
	player_info.erase(id) # Erase player from info.

func _connected_ok():
	print("client: connected ok")
	emit_signal("connected_to_server")

func _server_disconnected():
	print("client: server kicked us")
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Main.tscn")

func _connected_fail():
	print("client: failed to connect")
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Main.tscn")

remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	print("register player id:", id, " and info ", info)
	player_info[id] = info
	emit_signal("player_registered", info)

	# Call function to update lobby UI here

remotesync func pre_configure_game():
	players_done = []
	print("pre configure game")
	get_tree().set_pause(true) # Pre-pause
	# var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = load("res://Game.tscn").instance()
	world.connect("game_over", self, "game_over")
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
			get_node("/root/Game").rpc("start_game", true)
		emit_signal("game_ready")

func game_over():
	get_node("/root").get_node("Game").queue_free()
	emit_signal("game_finished")
