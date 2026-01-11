extends Node3D

#==================================
# 💲 WASHING SETTINGS (Enhanced)
#==================================
@export var max_dirt_level = 100.0
@export var wash_speed = 10.0
@export var dirt_spots_count = 30

# Random Price Range
@export_group("Price Settings")
@export var min_money_per_wash = 30  # Minimum possible earnings
@export var max_money_per_wash = 80  # Maximum possible earnings

# Dirt Visuals (Decal)
@export_group("Dirt Visuals")
@export var dirt_material: StandardMaterial3D # Drag your transparent PNG material here!
@export var dirt_scale_min = 0.5             # Random scale for variety
@export var dirt_scale_max = 1.2
@export var dirt_quad_size = 0.3             # Base size of the dirt spot mesh

#==================================
# ⚙️ INTERNAL VARIABLES
#==================================
# Movement settings
var target_position = Vector3.ZERO
var move_speed = 3.0
var rotation_speed = 2.0
var is_moving = false
var has_reached_destination = false

# Washing variables
var current_dirt_level = max_dirt_level
var is_being_washed = false
var dirt_spots = []
var money_to_earn = 0 # Stores the randomized price
var dirt_container: Node3D # Container for all dirt spot nodes

# Signals
signal car_washed(money_earned)
signal reached_destination(car)

func _ready():
	randomize() # Ensure random values are generated
	
	# Initialize dirt container
	dirt_container = Node3D.new()
	add_child(dirt_container)
	
	# Set randomized price
	money_to_earn = randi_range(min_money_per_wash, max_money_per_wash)
	
	create_dirt_spots()
	current_dirt_level = max_dirt_level
	update_visual_dirt()
	
	# Add to washable group
	add_to_group("washable_cars")
	
	# Debug info
	print("🚗 Car ready at position: ", global_position)
	print("   Dirt level: ", current_dirt_level)
	print("   Wash Price: $", money_to_earn)
	print("   In washable_cars group: ", is_in_group("washable_cars"))

func _process(delta):
	# Handle movement
	if is_moving and not has_reached_destination:
		move_to_target(delta)
	
	# Handle washing
	if is_being_washed and current_dirt_level > 0:
		current_dirt_level -= wash_speed * delta
		current_dirt_level = max(0, current_dirt_level)
		update_visual_dirt()
		
		if current_dirt_level <= 0:
			on_wash_complete()

#==================================
# 🚶 MOVEMENT FUNCTIONS
#==================================
func move_to_target(delta):
	var current_pos = global_position
	var direction = (target_position - current_pos).normalized()
	var distance = current_pos.distance_to(target_position)
	
	# Check if reached destination
	if distance < 0.5:
		is_moving = false
		has_reached_destination = true
		emit_signal("reached_destination", self)
		return
	
	# Move forward
	global_position += direction * move_speed * delta
	
	# Rotate to face target
	var look_pos = target_position
	look_pos.y = global_position.y
	look_at(look_pos, Vector3.UP)

func set_target(pos: Vector3):
	target_position = pos
	is_moving = true
	has_reached_destination = false

func set_speed(speed: float):
	move_speed = speed

#==================================
# 🎨 DIRT VISUALS (PNG Implementation)
#==================================

func create_dirt_spots():
	if not dirt_material:
		print("❌ ERROR: dirt_material is not set in the Inspector!")
		return
		
	print("=== Creating Dirt Spots with PNGs ===")
	
	for i in range(dirt_spots_count):
		var spot = MeshInstance3D.new()
		
		# Use QuadMesh
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(dirt_quad_size, dirt_quad_size)
		spot.mesh = quad_mesh
		
		# Set the material instance (Local To Scene helps here)
		# We duplicate the material so each dirt spot can be scaled/tweaked independently
		var spot_material = dirt_material.duplicate()
		spot.set_surface_override_material(0, spot_material)

		# Random scale for variety
		var scale_factor = randf_range(dirt_scale_min, dirt_scale_max)
		spot.scale = Vector3(scale_factor, scale_factor, scale_factor)
		
		# 1. Random Positioning around the car
		var radius = 1.2 # Increased radius slightly
		spot.position = Vector3(
			randf_range(-radius, radius),
			randf_range(0.5, 1.5), # Assuming car is between Y=0.5 and Y=1.5
			randf_range(-radius, radius)
		)
		
		# 2. Critical Fix: Rotation
		# Rotate the quad mesh to stand up vertically so it's visible.
		# If your car is Z-forward, this rotation works well for side/top placement.
		spot.rotation_degrees.x = 90.0
		
		# 3. Critical Fix: Offset
		# Add a tiny vertical offset to prevent Z-fighting with the car mesh.
		# Since we rotated it, adding to the Y-axis moves it outwards slightly.
		spot.position.y += 0.01 
		
		# Add to dirt container
		dirt_container.add_child(spot)
		
		dirt_spots.append({
			"node": spot,
			"original_scale": spot.scale,
			"visible": true
		})
	
	print("✅ Created ", dirt_spots.size(), " dirt spots.")

# Inside CarWashable.gd

func update_visual_dirt():
	# 1. Calculate the current overall dirt percentage (0.0 = clean, 1.0 = dirty)
	var dirt_percentage = current_dirt_level / max_dirt_level
	
	# The number of dirt spots that should still be fully visible
	var fully_visible_count = int(dirt_percentage * dirt_spots_count)
	
	for i in range(dirt_spots.size()):
		var spot_data = dirt_spots[i]
		var spot_node = spot_data.node
		
		# Ensure the node and material are valid
		if not is_instance_valid(spot_node):
			continue
			
		# Get the instance of the material attached to this spot
		var spot_material: StandardMaterial3D = spot_node.get_surface_override_material(0)
		if not spot_material:
			continue

		# --- FADING LOGIC ---
		
		if i < fully_visible_count:
			# This spot is still fully dirty (index is less than the visible threshold)
			# Ensure it is visible and fully opaque.
			spot_node.visible = true
			spot_material.albedo_color.a = 1.0 
			
			# Reset scale in case it was partially scaled down
			spot_node.scale = spot_data.original_scale
			
		else:
			# This spot should be fading or fully invisible
			
			# Calculate how much this spot should be faded based on its position in the list
			# Spots at the beginning of the "fully_visible_count" range fade last.
			
			# Distance from the fully visible line (0 to 1)
			var fade_distance = (float(i) - fully_visible_count) / (dirt_spots_count - fully_visible_count + 1)
			
			# Invert the fade distance to get the new alpha (1.0 = opaque, 0.0 = transparent)
			# We will fade the spots in the range [fully_visible_count, dirt_spots_count]
			var new_alpha = 1.0 - clamp(fade_distance * 3.0, 0.0, 1.0) # * 3.0 speeds up the fade
			
			# Apply the fading alpha
			spot_material.albedo_color.a = new_alpha
			
			# Hide completely when faded out
			if new_alpha <= 0.01:
				spot_node.visible = false
			else:
				spot_node.visible = true # Ensure node is visible while fading

#==================================
# 🧼 WASHING LOGIC
#==================================

func start_washing():
	if has_reached_destination and current_dirt_level > 0:
		is_being_washed = true
		print("🧽 Washing started!")

func stop_washing():
	is_being_washed = false

func on_wash_complete():
	is_being_washed = false
	# Use the randomized price
	emit_signal("car_washed", money_to_earn) 
	print("✨ Car is clean! Earned $" + str(money_to_earn))
	add_sparkle_effect()

func add_sparkle_effect():
	# ... (Sparkle effect code remains the same as your original) ...
	for i in range(3):
		var sparkle = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(0.1, 0.1)
		sparkle.mesh = quad
		
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_color = Color(1, 1, 1, 0.8)
		sparkle.set_surface_override_material(0, mat)
		
		sparkle.position = Vector3(
			randf_range(-1, 1),
			randf_range(0.5, 1.2),
			randf_range(-1.5, 1.5)
		)
		
		dirt_container.add_child(sparkle)
		
		# Animate sparkle
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sparkle, "scale", Vector3.ZERO, 0.5)
		tween.tween_property(sparkle, "position:y", sparkle.position.y + 0.5, 0.5)
		tween.chain()
		tween.tween_callback(sparkle.queue_free)


func get_dirt_percentage():
	# Returns percentage cleaned (0=dirty, 100=clean) for the UI
	return (current_dirt_level / max_dirt_level) * 100

func is_dirty():
	return current_dirt_level > 0

func can_be_washed():
	return has_reached_destination and current_dirt_level > 0

#==================================
# 🐞 DEBUG FUNCTIONS
#==================================
func _input(event):
	# Press "D" key to debug dirt
	if Input.is_key_pressed(KEY_D):
		print("=== DIRT DEBUG ===")
		print("Dirt container global position: ", dirt_container.global_position)
		print("Dirt spots count: ", dirt_spots.size())
		print("Car global position: ", global_position)
		print("Current Wash Price: $", money_to_earn)
		
		for i in range(min(3, dirt_spots.size())):
			var spot = dirt_spots[i].node
			print("  Spot ", i, ":")
			print("    Position: ", spot.position)
			print("    Global Position: ", spot.global_position)
			print("    Visible: ", spot.visible)
