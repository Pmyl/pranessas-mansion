extends Node

var room_code
var max_connect_time = 20 #if this time is exceeded when joining a game, a fail message is displayed

func _on_Host_pressed():
	if $Main/RoomCode.text != "":
		room_code = $Main/RoomCode.text
		$HolePunch.start_traversal(room_code, true, global.client_name) #Attempt to connect to server as host
		prepare_lobby("ROOM CODE:" + room_code)

func _on_Join_pressed():
	if $Main/RoomCode.text != "":
		room_code = $Main/RoomCode.text
		$HolePunch.start_traversal(room_code, false, global.client_name) #Attempt to connect to server as client
		prepare_lobby("Connecting to game...")
		$FailTimer.start(max_connect_time)

func prepare_lobby(lobby_message):
	$Main.visible = false
	$Preparing.visible = true

func _on_HolePunch_hole_punched(_my_port, _hosts_port, _hosts_address): #When signal recieved that server punched holes to each client
	yield(get_tree(), "idle_frame")
	if $HolePunch.is_host:
		print("Wait some time before starting")
		$ConnectTimer.start(2) #Waiting for port to become unused to start game
	else:
		print("Wait some time before starting to allow host to start")
		$ConnectTimer.start(10) #Waiting for host to start game

func _on_ConnectTimer_timeout():
	if $HolePunch.is_host:
		print("Start server lobby")
		global.own_port = $HolePunch.own_port
		var lobbyServer = preload("res://LobbyServer.tscn")
		add_child(lobbyServer.instance())
	else:
		print("Start client lobby")
		global.own_port = $HolePunch.own_port
		global.host_address = $HolePunch.host_address
		global.host_port = $HolePunch.host_port
		var lobbyClient = preload("res://LobbyClient.tscn")
		add_child(lobbyClient.instance())


func _on_FailTimer_timeout():
	$Main.visible = true
	$Preparing.visible = false
