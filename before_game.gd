extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_2_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://main.tscn")
	
func _on_back_button_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("esc"):
		get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_button_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://tutorial_scene.tscn")
