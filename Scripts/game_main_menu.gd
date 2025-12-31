extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _unhandled_input(event: InputEvent) -> void:
	pass


func _on_start_game_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://before_game.tscn")


func _on_settings_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://settings_menu.tscn")
	
func _on_quit_game_pressed() -> void:
	pass # Replace with function body.
	get_tree().quit()
