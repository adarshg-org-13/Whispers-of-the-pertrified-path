extends Node3D

#==================================
# 💲 WASHING SETTINGS (Enhanced)
#==================================
@export var max_dirt_level = 100.0
@export var wash_speed = 10.0
@export var dirt_spots_count = 30

@export_group("Price Settings")
@export var min_money_per_wash = 30
@export var max_money_per_wash = 80

@export_group("Dirt Visuals")
@export var dirt_material: StandardMaterial3D 
@export var dirt_scale_min = 0.5
@export var dirt_scale_max = 1.2
@export var dirt_quad_size = 0.3

#==================================
# ⚙️ INTERNAL VARIABLES
#==================================
var target_position = Vector3.ZERO
var move_speed = 3.0
var rotation_speed = 2.0
var is_moving = false
var has_reached_destination = false

var current_dirt_level = max_dirt_level
var is_being_washed = false
var dirt_spots = []
var money_to_earn = 0 
var dirt_container: Node3D 

signal car_washed(money_earned)
signal reached_destination(car)

func _ready():
	randomize()
	dirt_container = Node3D.new()
	add_child(dirt_container)
	money_to_earn = randi_range(min_money_per_wash, max_money_per_wash)
	
	create_dirt_spots()
	current_dirt_level = max_dirt_level
	update_visual_dirt()
	add_to_group("washable_cars")

func _process(delta):
	if is_moving and not has_reached_destination:
		move_to_target(delta)
	
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
	
	if distance < 0.5:
		is_moving = false
		has_reached_destination = true
		emit_signal("reached_destination", self)
		return
	
	global_position += direction * move_speed * delta
	
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
# 🎨 DIRT VISUALS (Fixed Zones & Fade Logic)
#==================================
func create_dirt_spots():
	if not dirt_material: return
		
	for i in range(dirt_spots_count):
		var spot = MeshInstance3D.new()
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(dirt_quad_size, dirt_quad_size)
		spot.mesh = quad_mesh
		
		var spot_material = dirt_material.duplicate()
		spot_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		spot_material.params_cull_mode = BaseMaterial3D.CULL_DISABLED
		spot.set_surface_override_material(0, spot_material)

		var scale_factor = randf_range(dirt_scale_min, dirt_scale_max)
		var final_scale = Vector3(scale_factor, scale_factor, scale_factor)
		spot.scale = final_scale
		
		# --- ZONE-BASED PLACEMENT ---
		var zone_selector = randi() % 3
		match zone_selector:
			0: # LEFT DOOR
				spot.position = Vector3(-1.2, randf_range(0.8, 1.3), randf_range(-0.5, 0.5))
				spot.rotation_degrees = Vector3(0, -90, 0)
			1: # RIGHT DOOR
				spot.position = Vector3(1.1, randf_range(0.8, 1.3), randf_range(-0.5, 0.5))
				spot.rotation_degrees = Vector3(0, 90, 0)
			2: # REAR (Pos Z due to 180-deg flip)
				spot.position = Vector3(randf_range(-0.4, 0.5), randf_range(1.1, 1.9), 2.8)
				spot.rotation_degrees = Vector3(0, 0, 0)
		
		dirt_container.add_child(spot)
		
		# Save in dictionary
		dirt_spots.append({
			"node": spot,
			"original_scale": final_scale,
			"material": spot_material,
			"offset": randf() * 0.2 # Unique offset so they don't fade all at once
		})

func update_visual_dirt():
	# Calculate global dirt percentage (1.0 to 0.0)
	var global_dirt_pct = current_dirt_level / max_dirt_level
	
	for i in range(dirt_spots.size()):
		var spot_data = dirt_spots[i]
		var spot_node = spot_data["node"]
		var spot_material = spot_data["material"]
		
		if not is_instance_valid(spot_node): continue

		# NEW FADE LOGIC: Individual fade threshold
		# Each spot stays at 1.0 alpha until the global dirt drops below its personal threshold
		var my_threshold = float(i) / float(dirt_spots_count)
		
		if global_dirt_pct > my_threshold:
			spot_node.visible = true
			# Smoothly fade based on how far we are past the threshold
			var local_fade = clamp((global_dirt_pct - my_threshold) * 5.0, 0.0, 1.0)
			spot_material.albedo_color.a = local_fade
		else:
			spot_node.visible = false
			spot_material.albedo_color.a = 0.0

#==================================
# 🧼 WASHING LOGIC
#==================================
func start_washing():
	if has_reached_destination and current_dirt_level > 0:
		is_being_washed = true

func stop_washing():
	is_being_washed = false

func on_wash_complete():
	is_being_washed = false
	# Ensure absolutely everything is hidden
	for spot in dirt_spots:
		spot["node"].visible = false
	emit_signal("car_washed", money_to_earn)
	add_sparkle_effect()

func add_sparkle_effect():
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
		
		sparkle.position = Vector3(randf_range(-1, 1), randf_range(0.8, 1.5), randf_range(-1.5, 1.5))
		dirt_container.add_child(sparkle)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sparkle, "scale", Vector3.ZERO, 0.5)
		tween.tween_property(sparkle, "position:y", sparkle.position.y + 0.5, 0.5)
		tween.chain().tween_callback(sparkle.queue_free)

func get_dirt_percentage():
	return (current_dirt_level / max_dirt_level) * 100

func is_dirty():
	return current_dirt_level > 0

func can_be_washed():
	return has_reached_destination and current_dirt_level > 0
