extends Node

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://before_game.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://settings_menu.tscn")
	
func _on_quit_game_pressed() -> void:
	get_tree().quit()

#END
