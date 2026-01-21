extends Label

var current_day: int = 0
var game_hours: int = 7
var game_minutes: int = 0
var game_seconds: float = 0.0

const GAME_SPEED: float = 72.0

func _ready():
	update_day_display()

func _process(delta):
	game_seconds += delta * GAME_SPEED
	
	if game_seconds >= 60.0:
		game_minutes += int(game_seconds / 60.0)
		game_seconds = fmod(game_seconds, 60.0)
	
	if game_minutes >= 60:
		game_hours += int(game_minutes / 60)
		game_minutes = game_minutes % 60
	
	if game_hours >= 24:
		current_day += 1
		game_hours = 0
		update_day_display()

func update_day_display():
	text = "Day %d" % current_day

func set_day(day: int):
	current_day = day
	update_day_display()
