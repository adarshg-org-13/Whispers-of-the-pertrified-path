extends Control

func _ready():
	hide()
	$AnimationPlayer.play("RESET")
	
func resume():
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  # Hide cursor for gameplay
	$AnimationPlayer.play_backwards("blur")
	
func pause():
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Show cursor for menu
	$AnimationPlayer.play("blur")

func _unhandled_input(event):
	if event.is_action_pressed("esc"):
		if get_tree().paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()

func _on_resume_pressed():
	resume()

func _on_restart_pressed():
	resume()
	get_tree().reload_current_scene()
	
func _on_quit_pressed():
	get_tree().quit()
