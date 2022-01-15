extends Node2D

signal game_over()
var seeker_positions = []
var next_battery_to_spawn = 0
var battery_positions = []

func _ready():
	var selfPeerID = get_tree().get_network_unique_id()
	if selfPeerID == 1:
		seeker_positions.append($PlayersPositions/Seeker1Position.position)
		seeker_positions.append($PlayersPositions/Seeker2Position.position)
		seeker_positions.append($PlayersPositions/Seeker3Position.position)
		seeker_positions.append($PlayersPositions/Seeker4Position.position)
		seeker_positions.shuffle()
		
		battery_positions.append($BatteriesPositions/Battery1.position)
		battery_positions.append($BatteriesPositions/Battery2.position)
		battery_positions.append($BatteriesPositions/Battery3.position)
		battery_positions.append($BatteriesPositions/Battery4.position)
		battery_positions.append($BatteriesPositions/Battery5.position)
		battery_positions.append($BatteriesPositions/Battery6.position)
		battery_positions.shuffle()

var dead_seekers = 0

remotesync func start_game():
	print("Game started!")
	var is_host = get_tree().get_network_unique_id() == 1
	var players = get_node("Players").get_children()

	if is_host:
		for p in players:
			var pos
			if "ghosts" in p.get_groups():
				p.connect("on_death", self, "trigger_seekers_win")
				pos = $PlayersPositions/GhostPosition.position
			else:
				p.connect("on_death", self, "check_ghost_win")
				p.connect("on_revive", self, "revived")
				pos = seeker_positions.pop_front()
			print("setting position of player ", p.name, " to: ", pos)
			p.rpc("set_initial_position", pos)
		$BatterySpawner.start(30)
	
	for p in players:
		if "ghosts" in p.get_groups():
			$GhostHealth.set_ghost(p)
	
	$Countdown.start()


remotesync func seekers_win():
	var players = get_node("Players").get_children()
	for p in players:
		if not "ghosts" in p.get_groups():
			print("%s won!" % p.name)
			p.declared_winner()
		else:
			print("%s lost :(" % p.name)
			p.declared_loser()
	$VictoryDuration.start(8)
	$Countdown.stop()
	$BatterySpawner.stop()

remotesync func ghost_win():
	var players = get_node("Players").get_children()
	for p in players:
		if "ghosts" in p.get_groups():
			print("%s won!" % p.name)
			p.declared_winner()
		else:
			print("%s lost :(" % p.name)
			p.declared_loser()
	$VictoryDuration.start(8)
	$Countdown.stop()
	$BatterySpawner.stop()

func trigger_seekers_win():
	rpc("seekers_win")

func check_ghost_win():
	dead_seekers += 1
	var seekers = get_node("Players").get_children().size() - 1
	print("Check ghost win - Dead seekers: ", dead_seekers, " Total seekers: ", seekers)
	if dead_seekers == seekers:
		rpc("ghost_win")

func revived():
	dead_seekers -= 1


func _on_Countdown_on_timeout():
	trigger_seekers_win()


func _on_VictoryDuration_timeout():
	emit_signal("game_over")


func _on_BatterySpawner_timeout():
	var battery_position = battery_positions[next_battery_to_spawn]
	next_battery_to_spawn = (next_battery_to_spawn + 1) % battery_positions.size()
	rpc("spawn_battery", battery_position)


remotesync func spawn_battery(battery_position):
	var battery_instance = preload("res://Battery.tscn").instance()
	battery_instance.position = battery_position
	add_child(battery_instance)
	battery_instance.spawn()
