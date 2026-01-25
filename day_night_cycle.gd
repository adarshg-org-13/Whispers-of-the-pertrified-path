extends Node3D

## Configuration
@export var day_start_hour: float = 8.0     # Starts at 8:00 AM
@export var minutes_per_game_hour: float = 1.0 # 1 game hour = 1 real minute

## Node References
# Make sure these names match your scene tree exactly
@onready var sun: DirectionalLight3D = $DirectionalLight3D 
@onready var world_env: WorldEnvironment = $WorldEnvironment

## Internal Variables
var time: float = 0.0
var time_speed: float = 0.0

func _ready() -> void:
	# Start the game at 8:00 AM
	time = day_start_hour / 24.0
	
	# Calculation for real-time speed:
	# 1.0 (full day) divided by (24 hours * 60 seconds)
	# This ensures 1 hour of game time passes every 60 seconds.
	time_speed = 1.0 / (24.0 * minutes_per_game_hour * 60.0)

func _process(delta: float) -> void:
	# Move time forward
	time += delta * time_speed
	
	# Reset at midnight
	if time >= 1.0:
		time = 0.0
	
	update_lighting()

func update_lighting() -> void:
	# 1. Sun Rotation
	# (time * 2PI) + PI/2 aligns the sun disk with the light rays correctly
	var sun_rotation = (time * 2.0 * PI) + (PI / 2.0)
	sun.rotation.x = sun_rotation
	
	# 2. Light Intensity
	# Brightest at 0.5 (Noon), dark at 0.0 (Midnight)
	var intensity = clamp(-cos(time * 2.0 * PI), 0.0, 1.0)
	sun.light_energy = intensity * 2.0
	
	# 3. Sky Brightness
	if world_env:
		# background_energy_multiplier controls the sky's actual glow
		world_env.environment.background_energy_multiplier = max(intensity, 0.05)

## Helper function for UI or Debugging
func get_time_as_string() -> String:
	var total_hours = time * 24.0
	var hours = int(total_hours)
	var mins = int((total_hours - hours) * 60)
	return "%02d:%02d" % [hours, mins]

#END
