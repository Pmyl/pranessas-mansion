extends Control

signal lobby_sealed()

onready var client = $Client

var player_info = {}

func _ready():
	client.connect("lobby_joined", self, "_lobby_joined")
	client.connect("lobby_sealed", self, "_lobby_sealed")
	client.connect("connected", self, "_connected")
	client.connect("disconnected", self, "_disconnected")
	client.rtc_mp.connect("peer_connected", self, "_mp_peer_connected")
	client.rtc_mp.connect("peer_disconnected", self, "_mp_peer_disconnected")
	client.rtc_mp.connect("server_disconnected", self, "_mp_server_disconnect")
	client.rtc_mp.connect("connection_succeeded", self, "_mp_connected")


func _process(delta):
	client.rtc_mp.poll()
	while client.rtc_mp.get_available_packet_count() > 0:
		_log(client.rtc_mp.get_packet().get_string_from_utf8())


func _connected(id):
	player_info[id] = { id = id, name = str(id), is_ghost = id == 1 }
	_log("Signaling server connected with ID: %d" % id)


func _disconnected():
	_log("Signaling server disconnected: %d - %s" % [client.code, client.reason])


func _lobby_joined(lobby):
	_log("Joined lobby %s" % lobby)


func _lobby_sealed():
	emit_signal("lobby_sealed", player_info)
	_log("Lobby has been sealed")


func _mp_connected():
	_log("Multiplayer is connected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_server_disconnect():
	_log("Multiplayer is disconnected (I am %d)" % client.rtc_mp.get_unique_id())


func _mp_peer_connected(id: int):
	player_info[id] = { id = id, name = str(id), is_ghost = id == 1 }
	_log("Multiplayer peer %d connected" % id)


func _mp_peer_disconnected(id: int):
	_log("Multiplayer peer %d disconnected" % id)


func _log(msg):
	print(msg)
	$VBoxContainer/TextEdit.text += str(msg) + "\n"


func ping():
	_log(client.rtc_mp.put_packet("ping".to_utf8()))


func _on_Peers_pressed():
	var d = client.rtc_mp.get_peers()
	_log(d)
	for k in d:
		_log(client.rtc_mp.get_peer(k))


func start():
	# replaced $VBoxContainer/Connect/Host.text with ws://54.147.40.190:9080
	client.start("ws://54.147.40.190:9080", $VBoxContainer/Connect/RoomSecret.text)


func _on_Seal_pressed():
	client.seal_lobby()


func stop():
	client.stop()

remote func send_message(text):
	print("My id is ", client.rtc_mp.get_unique_id(), " and I received ", text, " from ", get_tree().get_rpc_sender_id())


func _on_Send_pressed():
	rpc("send_message", $VBoxContainer/HBoxContainer/LineEdit.text)
