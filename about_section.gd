extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_about_section_button_pressed() -> void:
	pass # Replace with function body.
	get_tree().change_scene_to_file("res://settings_menu.tscn")
	
func _input(event):
	if Input.is_action_just_pressed("esc"):
		get_tree().change_scene_to_file("res://settings_menu.tscn")
