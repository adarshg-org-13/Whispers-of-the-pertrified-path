extends Node3D

# Washing settings
@export var max_dirt_level = 100.0
@export var money_per_wash = 50
@export var wash_speed = 10.0
@export var dirt_spots_count = 30

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
var car_mesh

var dirt_container

# Signals
signal car_washed(money_earned)
signal reached_destination(car)

func _ready():
	dirt_container = Node3D.new()
	add_child(dirt_container)
	car_mesh = find_mesh_instance(self)
	create_dirt_spots()
	current_dirt_level = max_dirt_level
	update_visual_dirt()
	
	# Add to washable group
	add_to_group("washable_cars")

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

func move_to_target(delta):
	var current_pos = global_transform.origin
	var direction = (target_position - current_pos).normalized()
	var distance = current_pos.distance_to(target_position)
	
	# Check if reached destination
	if distance < 0.5:
		is_moving = false
		has_reached_destination = true
		emit_signal("reached_destination", self)
		return
	
	# Move forward
	global_transform.origin += direction * move_speed * delta
	
	# Rotate to face target
	var look_pos = target_position
	look_pos.y = global_transform.origin.y  # Keep same Y to avoid tilting
	var target_basis = global_transform.looking_at(look_pos, Vector3.UP).basis
	global_transform.basis = global_transform.basis.slerp(target_basis, rotation_speed * delta)

func set_target(pos: Vector3):
	target_position = pos
	is_moving = true
	has_reached_destination = false

func set_speed(speed: float):
	move_speed = speed

func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result
	return null

func create_dirt_spots():
	for i in range(dirt_spots_count):
		var spot = MeshInstance3D.new()
		
		var quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(0.15, 0.15)
		spot.mesh = quad_mesh
		
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		
		var dirt_colors = [
			Color(0.2, 0.15, 0.1, 0.7),
			Color(0.15, 0.1, 0.05, 0.6),
			Color(0.1, 0.1, 0.1, 0.65),
			Color(0.25, 0.2, 0.15, 0.5),
		]
		mat.albedo_color = dirt_colors[i % dirt_colors.size()]
		
		spot.set_surface_override_material(0, mat)
		
		spot.transform.origin = Vector3(
			randf_range(-1.2, 1.2),
			randf_range(0.2, 1.5),
			randf_range(-2.0, 2.0)
		)
		
		spot.rotation_degrees.z = randf_range(0, 360)
		
		dirt_container.add_child(spot)
		dirt_spots.append({
			"node": spot,
			"original_scale": spot.scale,
			"visible": true
		})

func update_visual_dirt():
	var dirt_percentage = current_dirt_level / max_dirt_level
	var visible_count = int(dirt_percentage * dirt_spots_count)
	
	for i in range(dirt_spots.size()):
		var spot_data = dirt_spots[i]
		var should_be_visible = i < visible_count
		
		if spot_data.visible != should_be_visible:
			spot_data.visible = should_be_visible
			
			if should_be_visible:
				spot_data.node.visible = true
				spot_data.node.scale = spot_data.original_scale
			else:
				# Create tween for fade out
				var tween = create_tween()
				tween.tween_property(spot_data.node, "scale", Vector3.ZERO, 0.2)
				tween.tween_callback(func(): spot_data.node.visible = false)

func start_washing():
	if has_reached_destination and current_dirt_level > 0:
		is_being_washed = true

func stop_washing():
	is_being_washed = false

func on_wash_complete():
	is_being_washed = false
	emit_signal("car_washed", money_per_wash)
	print("Car is clean! Earned $" + str(money_per_wash))
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
		
		sparkle.transform.origin = Vector3(
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
	return (current_dirt_level / max_dirt_level) * 100

func is_dirty():
	return current_dirt_level > 0

func can_be_washed():
	return has_reached_destination and current_dirt_level > 0
