extends Control

func _ready():
	$PlayersContainer/PlayerList.set_server_mode()

	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(4444, 3)
	get_tree().network_peer = peer
	
	$Lobby.connect("player_registered", self, "add_player_name")
	$Lobby.connect("player_disconnected", self, "remove_player_name")
	$Lobby.connect("player_is_ghost", self, "display_ghost_player")
	$Lobby.connect("game_ready", self, "hide_lobby")
	$Lobby.connect("game_finished", self, "show_lobby")
	$Lobby.start()
	
	var ips = []
	for ip in IP.get_local_addresses():
		if not ":" in ip:
			ips.append(ip)
	get_node("IPs").set_text(str(ips))


func broadcast_ghost_selection(id):
	print("Broadcast ghost selection: ", id)
	$Lobby.rpc("set_ghost_id", id)

func display_ghost_player(id):
	$PlayersContainer/PlayerList.set_ghost(id)

func _on_Start_pressed():
	get_tree().set_refuse_new_network_connections(true)
	$Lobby.rpc("pre_configure_game")

func _on_Cancel_pressed():
	get_tree().set_refuse_new_network_connections(true)
	$Lobby.rpc("close_connection")

func add_player_name(info):
	print("Adding player ", info)
	$PlayersContainer/PlayerList.add_player(info)

func remove_player_name(info):
	$PlayersContainer/PlayerList.remove_player(info)

func _on_PlayerList_make_ghost(id):
	broadcast_ghost_selection(id)

func hide_lobby():
	visible = false

func show_lobby():
	visible = true
	get_tree().set_refuse_new_network_connections(false)
