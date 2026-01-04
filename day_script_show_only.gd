extends Label

# Day counter
var current_day: int = 0

# Time variables
var game_hours: int = 7  # Start at 7:00 AM
var game_minutes: int = 0
var game_seconds: float = 0.0

# Time scale: 24 in-game hours = 20 real minutes (1200 seconds)
# So 1 real second = 72 in-game seconds
const GAME_SPEED: float = 72.0

func _ready():
	update_day_display()

func _process(delta):
	# Update game time
	game_seconds += delta * GAME_SPEED
	
	# Convert seconds to minutes and hours
	if game_seconds >= 60.0:
		game_minutes += int(game_seconds / 60.0)
		game_seconds = fmod(game_seconds, 60.0)
	
	if game_minutes >= 60:
		game_hours += int(game_minutes / 60)
		game_minutes = game_minutes % 60
	
	# When 24 hours pass, go to next day
	if game_hours >= 24:
		current_day += 1
		game_hours = 0
		update_day_display()
		print("Now on Day %d" % current_day)

func update_day_display():
	text = "Day %d" % current_day

# Call this to manually set a specific day
func set_day(day: int):
	current_day = day
	update_day_display()
