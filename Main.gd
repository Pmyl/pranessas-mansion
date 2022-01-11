extends Node

func _ready():
	get_node("Server IP").set_text(global.server_ip_to_connect_to)
	get_node("Player name").set_text(global.player_name)

func _on_Server_pressed():
	global.player_name = get_node("Player name").get_text()
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://LobbyServer.tscn")


func _on_Client_pressed():
	global.player_name = get_node("Player name").get_text()
	global.server_ip_to_connect_to = get_node("Server IP").get_text()
	global.host_address = get_node("Server IP").get_text()
	# warning-ignore:return_value_discarded
	get_tree().change_scene("res://LobbyClient.tscn")
