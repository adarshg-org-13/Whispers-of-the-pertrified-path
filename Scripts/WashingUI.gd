extends CanvasLayer

func _ready():
	if has_node("WashProgressBar"):
		$WashProgressBar.visible = false
	if has_node("MoneyPopup"):
		$MoneyPopup.visible = false
	
	# Style the progress bar
	if has_node("WashProgressBar"):
		$WashProgressBar.custom_minimum_size = Vector2(200, 30)
