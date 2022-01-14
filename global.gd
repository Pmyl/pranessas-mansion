extends Node

var own_port = 0
var host_port = 4444
var host_address = "localhost"

var server_ip_to_connect_to = "localhost"
var player_name = "Incognito"

var webrtc_url = "wss://pran-webrtc-lobby.herokuapp.com"

var game_time = 300

var client_name  = ""

func _ready():
	randomize()
	client_name = "fisso" + str(randi())
