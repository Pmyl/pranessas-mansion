extends Control

func _ready():
	print("attempting connection to: ", global.server_ip_to_connect_to)
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(global.server_ip_to_connect_to, 4444)
	
	match result:
		OK:
			continue_game(peer)
		_:
			back_to_main()

func continue_game(peer):
	get_tree().network_peer = peer
	
	$Lobby.connect("player_registered", self, "add_player_name")
	$Lobby.connect("player_disconnected", self, "remove_player_name")
	$Lobby.connect("player_is_ghost", self, "display_ghost_player")
	$Lobby.connect("game_ready", self, "hide_lobby")
	$Lobby.connect("game_finished", self, "show_lobby")
	$Lobby.connect("connected_to_server", self, "hide_connecting")
	$Lobby.start()

func display_ghost_player(id):
	$PlayersContainer/PlayerList.set_ghost(id)

func back_to_main():
	print("wrong connection configuration")
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

