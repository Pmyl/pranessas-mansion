extends Node

var my_info

func _ready():
	randomize()
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
	
	my_info = { name = global.player_name }

var player_info = {}

func _player_connected(id):
	print("player connected: sending my info (", my_info, ") to them (id: ", id, ")")
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id):
	print("disconnect player", id)
	player_info.erase(id) # Erase player from info.

func _connected_ok():
	print("client: connected ok")

func _server_disconnected():
	print("client: server kicked us")
	get_tree().change_scene("res://Main.tscn")

func _connected_fail():
	print("client: failed to connect")
	get_tree().change_scene("res://Main.tscn")

remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	# Store the info
	print("register player id:", id, " and info ", info)
	player_info[id] = info

	# Call function to update lobby UI here

remotesync func pre_configure_game():
	print("pre configure game")
	get_tree().set_pause(true) # Pre-pause
	var selfPeerID = get_tree().get_network_unique_id()

	# Load world
	var world = load("res://Game.tscn").instance()
	get_node("/root").add_child(world)

	print("adding my player")
	# Load my player
	
	create_player(selfPeerID, global.player_name, selfPeerID == 1)

	print("adding other players - count ", player_info.size())
	# Load other players
	for p in player_info:
		create_player(p, player_info[p].name, p == 1)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	rpc_id(1, "done_preconfiguring")

func create_player(id, name, is_ghost):
	var player
	if is_ghost:
		player = preload("res://Ghost.tscn").instance()
	else:
		player = preload("res://Player.tscn").instance()
	player.set_name(str(id))
	player.set_network_master(id) # Will be explained later
	player.set_player_name(name)
	get_node("/root/Game/Players").add_child(player)

var players_done = []
remotesync func done_preconfiguring():
	print("done_preconfiguring")
	var who = get_tree().get_rpc_sender_id()
	
	if who == 1:
		if player_info.size() == 0:
			print("Starting solo game")
			rpc("post_configure_game")
		else:
			pass
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
		# Game starts now!
