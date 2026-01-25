extends CanvasLayer

func _ready():
	var progress_bar = get_node_or_null("WashProgressBar")
	if progress_bar:
		progress_bar.visible = false
		progress_bar.custom_minimum_size = Vector2(200, 30)
	
	var popup = get_node_or_null("MoneyPopup")
	if popup:
		popup.visible = false
	
	var money_label = get_node_or_null("MoneyLabel")
	if money_label:
		money_label.text = "Money: $0"
	
	var prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.text = ""

#END
