extends Node

var lobby_instance

func _ready():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(4444, 3)
	get_tree().network_peer = peer
	
	var lobby = load("res://Lobby.tscn")
	lobby_instance = lobby.instance()
	get_parent().call_deferred("add_child", lobby_instance)
	
	var ips = []
	
	for ip in IP.get_local_addresses():
		if not ":" in ip:
			ips.append(ip)

	get_node("IPs").set_text(str(ips))
	

func _on_Start_pressed():
	get_tree().set_refuse_new_network_connections(true)
	lobby_instance.rpc("pre_configure_game")
	queue_free()
