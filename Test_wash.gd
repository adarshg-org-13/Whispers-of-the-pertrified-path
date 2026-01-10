extends Control

func _ready():
	# Safely hide progress bar
	var progress_bar = get_node_or_null("WashProgressBar")
	if progress_bar:
		progress_bar.visible = false
		progress_bar.custom_minimum_size = Vector2(200, 30)
	else:
		print("❌ ERROR: WashProgressBar not found!")
		print("   Make sure you have a ProgressBar node named 'WashProgressBar'")
	
	# Safely hide money popup
	var popup = get_node_or_null("MoneyPopup")
	if popup:
		popup.visible = false
	else:
		print("❌ ERROR: MoneyPopup not found!")
		print("   Make sure you have a Label node named 'MoneyPopup'")
	
	# Check money label exists
	var money_label = get_node_or_null("MoneyLabel")
	if money_label:
		money_label.text = "Money: $0"
		print("✅ MoneyLabel found")
	else:
		print("❌ ERROR: MoneyLabel not found!")
		print("   Make sure you have a Label node named 'MoneyLabel'")
	
	# Check prompt label exists
	var prompt_label = get_node_or_null("PromptLabel")
	if prompt_label:
		prompt_label.text = ""
		print("✅ PromptLabel found")
	else:
		print("❌ ERROR: PromptLabel not found!")
		print("   Make sure you have a Label node named 'PromptLabel'")
	
	print("--- WashingUI _ready() complete ---")
#```

#---

## **Step 3: Run the Game and Check Console**

#1. **Save the script** (Ctrl+S)
#2. **Run the game** (F5)
#3. **Look at the Output console** (bottom panel)

#You'll see messages like:
#- ✅ `"✅ MoneyLabel found"` ← Good!
#- ❌ `"❌ ERROR: WashProgressBar not found!"` ← This tells you what's missing!

#---

## **Step 4: Fix Missing Nodes**

#Based on what the console says, add the missing nodes:

### **If "MoneyLabel not found":**

#1. Open WashingUI scene
#2. Right-click **WashingUI** → Add Child Node → **Label**
#3. Rename it to **exactly** `MoneyLabel`
#4. In Inspector:
   #- Text: "Money: $0"
   #- Position: Top-right corner
   #- Horizontal Alignment: Right

### **If "PromptLabel not found":**

#1. Right-click **WashingUI** → Add Child Node → **Label**
#2. Rename to `PromptLabel`
#3. In Inspector:
#   - Text: "" (leave empty)
#   - Position: Center-bottom
#   - Horizontal Alignment: Center

### **If "WashProgressBar not found":**

#1. Right-click **WashingUI** → Add Child Node → **ProgressBar**
#2. Rename to `WashProgressBar`
#3. In Inspector:
 #  - Min Value: 0
  # - Max Value: 100
   #- Position: Below PromptLabel

### **If "MoneyPopup not found":**

#1. Right-click **WashingUI** → Add Child Node → **Label**
#2. Rename to `MoneyPopup`
#3. In Inspector:
#   - Text: "+$50"
#   - Position: Center of screen
#   - Font Size: 32

#---

## **Step 5: Verify Node Names in Scene Tree**

#Click on each node and make sure the name in the **Scene panel** matches EXACTLY:
#```
#✅ Correct:
 #  - MoneyLabel
 #  - PromptLabel
 #  - WashProgressBar
  # - MoneyPopup

#❌ Wrong:
 #  - moneylabel (lowercase)
  # - Money Label (space)
  # - ProgressBar (generic name)
  # - Label (generic name)
