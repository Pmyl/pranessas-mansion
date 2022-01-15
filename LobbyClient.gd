extends Control

func _ready():
	print("attempting connection to: %s on port %s with my port %s" % [global.host_address, int(global.host_port), int(global.own_port)])
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(str(global.host_address), int(global.host_port), 0, 0, int(global.own_port))
	
	match result:
		OK:
			continue_game(peer)
		_:
			back_to_main()

func continue_game(peer):
	get_tree().network_peer = peer
	
	# warning-ignore:return_value_discarded
	$Lobby.connect("player_registered", self, "add_player_name")
	# warning-ignore:return_value_discarded
	$Lobby.connect("player_disconnected", self, "remove_player_name")
	# warning-ignore:return_value_discarded
	$Lobby.connect("player_is_ghost", self, "display_ghost_player")
	# warning-ignore:return_value_discarded
	$Lobby.connect("game_ready", self, "hide_lobby")
	# warning-ignore:return_value_discarded
	$Lobby.connect("game_finished", self, "show_lobby")
	# warning-ignore:return_value_discarded
	$Lobby.connect("connected_to_server", self, "hide_connecting")
	$Lobby.start()

func display_ghost_player(id):
	$PlayersContainer/PlayerList.set_ghost(id)

func back_to_main():
	print("wrong connection configuration")
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Main.tscn")

func add_player_name(info):
	$PlayersContainer/PlayerList.add_player(info)

func remove_player_name(info):
	$PlayersContainer/PlayerList.remove_player(info)

func hide_connecting():
	$AttemptingConnection.visible = false

func _on_Cancel_pressed():
	$Lobby.close_connection()

func hide_lobby():
	visible = false

func show_lobby():
	visible = true

