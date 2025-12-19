extends CharacterBody3D

# Kirmada Enemy AI Script
# Features: Chase behavior, Sound detection, Teleportation ability

# Health properties
@export var max_health: float = 250.0  # Mini-boss health
@export var current_health: float = 250.0
@export var health_regen_rate: float = 2.0  # HP per second when out of combat
@export var health_regen_delay: float = 8.0  # Seconds before regen starts
@export var damage_flash_duration: float = 0.2

# Movement properties
@export var speed: float = 7.0  # Slightly less than player's 7.5
@export var acceleration: float = 8.0
@export var friction: float = 10.0

# Sound detection properties
@export var sound_detection_radius: float = 15.0
@export var sound_response_time: float = 0.3

# Teleport properties
@export var teleport_range: float = 10.0
@export var teleport_cooldown: float = 5.0
@export var teleport_distance_min: float = 5.0  # Minimum distance to teleport

# State management
enum State { IDLE, PATROL, CHASE, INVESTIGATING, DEAD }
var current_state = State.IDLE

# References
var player: Node3D = null
var nav_agent: NavigationAgent3D
var mesh_instance: MeshInstance3D  # For damage flash effect

# Internal variables
var last_known_player_pos: Vector3
var teleport_timer: float = 0.0
var can_teleport: bool = true
var investigation_timer: float = 0.0
var heard_sounds: Array = []
var time_since_last_damage: float = 0.0
var is_dead: bool = false
var original_material: Material

func _ready():
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Setup navigation agent
	nav_agent = NavigationAgent3D.new()
	add_child(nav_agent)
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 2.0
	
	# Get mesh for damage effects
	mesh_instance = find_child("MeshInstance3D")
	if mesh_instance and mesh_instance.get_surface_override_material_count() > 0:
		original_material = mesh_instance.get_surface_override_material(0)
	
	# Connect to sound system
	get_tree().call_group("sound_emitters", "connect_listener", self)
	
	# Initialize health
	current_health = max_health

func _physics_process(delta):
	# Don't do anything if dead
	if is_dead:
		return
	
	# Update timers
	time_since_last_damage += delta
	
	# Health regeneration when out of combat
	if time_since_last_damage >= health_regen_delay and current_health < max_health:
		current_health = min(current_health + health_regen_rate * delta, max_health)
	
	# Update teleport cooldown
	if not can_teleport:
		teleport_timer -= delta
		if teleport_timer <= 0:
			can_teleport = true
	
	# State machine
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.INVESTIGATING:
			_investigate_behavior(delta)
		State.DEAD:
			return
	
	# Apply movement
	if velocity.length() > 0:
		velocity = velocity.lerp(Vector3.ZERO, friction * delta)
	
	move_and_slide()

func _idle_behavior(delta):
	# Check for player in sight or sounds
	if player and can_see_player():
		current_state = State.CHASE
		last_known_player_pos = player.global_position
	elif heard_sounds.size() > 0:
		investigate_sound()

func _chase_behavior(delta):
	if not player:
		current_state = State.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Update last known position if we can see player
	if can_see_player():
		last_known_player_pos = player.global_position
		
		# Try to teleport if conditions are met
		if can_teleport and distance_to_player > teleport_distance_min and distance_to_player <= teleport_range:
			teleport_near_player()
	
	# Navigate to last known position
	nav_agent.target_position = last_known_player_pos
	
	if nav_agent.is_navigation_finished():
		if not can_see_player():
			current_state = State.IDLE
		return
	
	# Move towards player
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	velocity = velocity.lerp(direction * speed, acceleration * delta)
	
	# Look at target
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

func _investigate_behavior(delta):
	investigation_timer -= delta
	
	# Navigate to sound location
	if nav_agent.is_navigation_finished():
		if investigation_timer <= 0:
			current_state = State.IDLE
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	velocity = velocity.lerp(direction * (speed * 0.7), acceleration * delta)
	
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)
	
	# Check if player is found during investigation
	if player and can_see_player():
		current_state = State.CHASE

func can_see_player() -> bool:
	if not player:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP,
		player.global_position + Vector3.UP
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == player:
		return true
	return false

func teleport_near_player():
	if not player or not can_teleport:
		return
	
	var player_pos = player.global_position
	var distance = global_position.distance_to(player_pos)
	
	# Only teleport if within range
	if distance > teleport_range:
		return
	
	# Calculate teleport position (behind or to the side of player)
	var direction_to_player = (player_pos - global_position).normalized()
	var random_angle = randf_range(-PI/3, PI/3)  # Random angle for unpredictability
	var teleport_direction = direction_to_player.rotated(Vector3.UP, random_angle)
	
	# Teleport 3-5 meters away from player
	var teleport_distance = randf_range(3.0, 5.0)
	var teleport_pos = player_pos - teleport_direction * teleport_distance
	teleport_pos.y = player_pos.y  # Keep same height
	
	# Perform teleport
	global_position = teleport_pos
	look_at(player_pos, Vector3.UP)
	
	# Start cooldown
	can_teleport = false
	teleport_timer = teleport_cooldown
	
	# Optional: Add teleport effect
	_spawn_teleport_effect()
	
	print("Kirmada teleported near player!")

func _spawn_teleport_effect():
	# Add particle effect or animation here
	# For now, just a placeholder
	pass

# Called by sound emitters (like player footsteps)
func on_sound_heard(sound_position: Vector3, sound_volume: float):
	var distance = global_position.distance_to(sound_position)
	
	# Check if sound is within detection radius
	if distance <= sound_detection_radius:
		# Louder sounds or closer sounds are more noticeable
		var detection_chance = (1.0 - distance / sound_detection_radius) * sound_volume
		
		if randf() < detection_chance:
			heard_sounds.append({
				"position": sound_position,
				"time": Time.get_ticks_msec()
			})
			
			# React to sound if not already chasing
			if current_state != State.CHASE:
				investigate_sound()

func investigate_sound():
	if heard_sounds.is_empty():
		return
	
	# Investigate the most recent sound
	var sound = heard_sounds.pop_back()
	nav_agent.target_position = sound.position
	current_state = State.INVESTIGATING
	investigation_timer = 5.0  # Investigate for 5 seconds
	
	print("Kirmada heard a sound and is investigating!")

# Call this from player's movement script when making footstep sounds
# Example: get_tree().call_group("enemies", "on_sound_heard", global_position, 1.0)

# Health and damage system
func take_damage(damage: float, attacker: Node3D = null):
	if is_dead:
		return
	
	current_health -= damage
	time_since_last_damage = 0.0  # Reset regen timer
	
	# Flash effect
	_damage_flash()
	
	# React to damage
	if attacker:
		last_known_player_pos = attacker.global_position
		if current_state != State.CHASE:
			current_state = State.CHASE
	
	print("Kirmada took %d damage! Health: %d/%d" % [damage, current_health, max_health])
	
	# Check for death
	if current_health <= 0:
		die()

func _damage_flash():
	if not mesh_instance:
		return
	
	# Create red flash material
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color(1, 0.2, 0.2)
	
	# Apply flash
	if mesh_instance.get_surface_override_material_count() > 0:
		mesh_instance.set_surface_override_material(0, flash_material)
	
	# Reset after delay
	await get_tree().create_timer(damage_flash_duration).timeout
	if mesh_instance and original_material:
		mesh_instance.set_surface_override_material(0, original_material)

func die():
	if is_dead:
		return
	
	is_dead = true
	current_state = State.DEAD
	
	print("Kirmada has been defeated!")
	
	# Death animation/effect
	_play_death_animation()
	
	# Disable collision
	collision_layer = 0
	collision_mask = 0
	
	# Wait before removing
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _play_death_animation():
	# Add death particle effect or animation here
	# For now, simple fade out
	var tween = create_tween()
	if mesh_instance:
		tween.tween_property(mesh_instance, "transparency", 1.0, 2.0)

func heal(amount: float):
	if is_dead:
		return
	
	current_health = min(current_health + amount, max_health)
	print("Kirmada healed %d HP! Health: %d/%d" % [amount, current_health, max_health])

func get_health_percentage() -> float:
	return current_health / max_health

# Signal for UI health bar
signal health_changed(current: float, maximum: float)
