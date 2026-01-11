extends CanvasLayer

func _ready():
	print("=== WashingUI _ready() Starting ===")
	print("   UI Node Path: ", get_path())
	print("   UI has children: ", get_child_count())
	
	# List all children
	for child in get_children():
		print("   - Child: ", child.name, " (", child.get_class(), ")")
	
	# Safely hide progress bar
	var progress_bar = get_node_or_null("WashProgressBar")
	if progress_bar:
		progress_bar.visible = false
		progress_bar.custom_minimum_size = Vector2(200, 30)
		print("✅ WashProgressBar found and hidden")
	else:
		print("❌ WashProgressBar NOT FOUND")
	
	# Safely hide money popup
	var popup = get_node_or_null("MoneyPopup")
	if popup:
		popup.visible = false
		print("✅ MoneyPopup found and hidden")
	else:
		print("❌ MoneyPopup NOT FOUND")
	
	# Check money label exists
	var money_label = get_node_or_null("MoneyLabel")
	if money_label:
		money_label.text = "Money: $0"
		print("✅ MoneyLabel found and set")
	else:
		print("❌ MoneyLabel NOT FOUND")
	
	# Check prompt label exists
	var prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.text = ""
		print("✅ PromptLabel found and set")
	else:
		print("❌ PromptLabel NOT FOUND")
	
	print("=== WashingUI _ready() Complete ===")

# Test function - call this from console
func test_prompt():
	var prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.text = "TEST: Press E to wash car"
		print("Test prompt set!")
	else:
		print("Cannot set test prompt - label not found")
