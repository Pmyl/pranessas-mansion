extends Node

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
	
	var lobby = load("res://Lobby.tscn")
	var lobby_instance = lobby.instance()
	get_parent().call_deferred("add_child", lobby_instance)


func back_to_main():
	print("wrong connection configuration")
	get_tree().change_scene("res://Main.tscn")
