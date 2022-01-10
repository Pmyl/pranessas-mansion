extends Control

signal on_click(id)

var id = null
var player_name = null
var is_ghost = false

func set_up(id_to_set, name_to_set, is_ghost_to_set):
	id = id_to_set
	player_name = name_to_set
	is_ghost = is_ghost_to_set
	$Button.text = build_text()

func build_text():
	var text = player_name
	if id == 1:
		text += " (Host)"

	if id == get_tree().get_network_unique_id():
		text += " (You)"
	
	if is_ghost:
		text = "GHOST - " + text
	
	return text

func set_as_ghost():
	is_ghost = true
	$Button.text = build_text()

func unset_as_ghost():
	is_ghost = false
	$Button.text = build_text()


func _on_Button_pressed():
	emit_signal("on_click", id)
