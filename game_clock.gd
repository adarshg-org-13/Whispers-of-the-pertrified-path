extends Control

# Time variables
var game_hours: int = 7  # Start at 7:00 AM
var game_minutes: int = 0
var game_seconds: float = 0.0
var current_day: int = 1
var time_stopped: bool = false

# Time scale: 24 in-game hours = 20 real minutes (1200 seconds)
# So 1 real second = 72 in-game seconds
const GAME_SPEED: float = 72.0

# Time limits
const START_HOUR: int = 7  # 7 AM
const END_HOUR: int = 12   # 12 PM (noon)

# UI Elements (assign these in the editor)
@onready var time_label = $TimeLabel
@onready var day_label = $DayLabel
@onready var period_label = $PeriodLabel

func _ready():
	update_ui()

func _process(delta):
	# Don't update time if it has stopped
	if time_stopped:
		return
	
	# Update game time
	game_seconds += delta * GAME_SPEED
	
	# Convert seconds to minutes and hours
	if game_seconds >= 60.0:
		game_minutes += int(game_seconds / 60.0)
		game_seconds = fmod(game_seconds, 60.0)
	
	if game_minutes >= 60:
		game_hours += int(game_minutes / 60)
		game_minutes = game_minutes % 60
	
	# Check if we've reached 12 PM (noon)
	if game_hours >= END_HOUR:
		game_hours = END_HOUR
		game_minutes = 0
		game_seconds = 0.0
		time_stopped = true
		print("Time has stopped at 12:00 PM")
		# You can emit a signal here if you want to trigger something when time stops
		on_time_stopped()
	
	update_ui()

func update_ui():
	# Format time as 12-hour format
	var display_hours = game_hours % 12
	if display_hours == 0:
		display_hours = 12
	
	var period = "AM" if game_hours < 12 else "PM"
	var time_string = "%d:%02d %s" % [display_hours, game_minutes, period]
	
	# Update labels
	if time_label:
		time_label.text = time_string
	if day_label:
		day_label.text = "Day %d" % current_day
	if period_label:
		period_label.text = get_time_of_day()

func get_time_of_day() -> String:
	if game_hours >= 7 and game_hours < 12:
		return "Morning"
	elif game_hours >= 12:
		return "Noon"
	else:
		return "Morning"

func get_sky_color() -> Color:
	# Returns a color for sky/lighting based on time of day
	if game_hours >= 7 and game_hours < 9:  # Early morning
		return Color(1.0, 0.7, 0.5)
	elif game_hours >= 9 and game_hours < 12:  # Late morning
		return Color(0.53, 0.81, 0.92)
	else:  # Noon
		return Color(0.6, 0.85, 1.0)

# Called when time stops at 12 PM
func on_time_stopped():
	# Add your logic here for when the clock stops
	# For example: show end of day summary, save progress, etc.
	pass

# Optional: Reset the clock to start time
func reset_clock():
	game_hours = START_HOUR
	game_minutes = 0
	game_seconds = 0.0
	time_stopped = false
	update_ui()

# Optional: Check if time has stopped
func is_time_stopped() -> bool:
	return time_stopped
