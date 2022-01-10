extends Control

enum PlayerListMode {
	Client,
	Server
}

signal make_ghost(id)

var current_mode = PlayerListMode.Client

func set_server_mode():
	current_mode = PlayerListMode.Server

func set_ghost(id):
	for item in get_children():
		if item.id == id:
			item.set_as_ghost()
		else:
			item.unset_as_ghost()

func add_player(info):
	var item = load("res://PlayerListItem.tscn")
	var item_instance = item.instance()
	add_child(item_instance)
	item_instance.set_up(info.id, info.name, info.is_ghost)
	item_instance.connect("on_click", self, "emit_make_ghost")
	if current_mode == PlayerListMode.Server:
		item_instance.get_node("Button").flat = false
		item_instance.get_node("Button").disabled = false

func remove_player(info):
	var replace_ghost
	for item in get_children():
		if item.id == info.id:
			if item.is_ghost:
				replace_ghost = true
			item.queue_free()
	if replace_ghost:
		emit_make_ghost(get_children()[0].id)

func emit_make_ghost(id):
	emit_signal("make_ghost", id)
