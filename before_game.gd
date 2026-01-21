extends Control

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial_scene.tscn")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		get_tree().change_scene_to_file("res://main_menu.tscn")
