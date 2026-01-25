extends Control

func _on_game_controls_button_pressed() -> void:
	get_tree().change_scene_to_file("res://settings_menu.tscn")
	
func _input(event):
	if Input.is_action_just_pressed("esc"):
		get_tree().change_scene_to_file("res://settings_menu.tscn")

#END
