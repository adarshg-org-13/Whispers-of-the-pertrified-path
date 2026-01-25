extends Label

var current_day: int = 1
var game_hours: int = 8    
var game_minutes: int = 0
var game_seconds: float = 0.0

const GAME_SPEED: float = 60.0 

func _ready():
	update_display()

func _process(delta):
	game_seconds += delta * GAME_SPEED
	
	if game_seconds >= 60.0:
		game_minutes += int(game_seconds / 60.0)
		game_seconds = fmod(game_seconds, 60.0)
	
	if game_minutes >= 60:
		game_hours += int(game_minutes / 60)
		game_minutes = game_minutes % 60
	
	if game_hours >= 22:
		current_day += 1
		game_hours = 8 
		game_minutes = 0
		game_seconds = 0
		
	update_display()

func update_display():
	text = "Day %d | %02d:%02d" % [current_day, game_hours, game_minutes]

#END
