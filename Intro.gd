extends Control

var fading_in = true


func _process(_delta):
	$RichTextLabel.set_modulate(lerp($RichTextLabel.get_modulate(), Color(1,1,1,1 if fading_in else 0), 0.03))
	
	if Input.is_action_just_pressed("ui_accept"):
		$GoMenu.stop()
		$FadingOut.stop()
		go_menu()


func _on_FadingOut_timeout():
	fading_in = false


func _on_GoMenu_timeout():
	go_menu()

func go_menu():
	if OS.is_debug_build():
		get_tree().change_scene("res://Main.tscn")
	else:
		get_tree().change_scene("res://main_webrtc.tscn")
