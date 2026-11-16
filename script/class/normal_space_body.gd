extends RigidBody3D
class_name NormalSpaceBody

@onready var real_trans: DoubleTransform = DoubleTransform.from_transform(global_transform)
var thrusters: Array[Thruster]
var rcs: Array[RCS]
var weapons: Array[Weapon]
var weapon_intervals: PackedFloat64Array
var weapon_times: PackedFloat64Array
var weapon_jitter: PackedFloat64Array
var prev: Vector3

var attack_target := DoubleVector.new(0.0, 3.0, -10.0)

var targets: Array[Target] = []
var target_idxs: Array[int] = []
@onready var trail: Path3D = get_node_or_null("Trail")

func _ready() -> void:
	can_sleep = false
	add_to_group("space_bodies")
	for child in find_children("*", "", true, true):
		if child is Thruster:
			thrusters.append(child)
		elif child is RCS:
			rcs.append(child)
		elif child is Weapon:
			weapons.append(child)
			weapon_intervals.append(60.0/child.rpm)
			weapon_times.append(0)
			weapon_jitter.append(0.5)
		elif child is Target:
			child.real_pos = DoubleVector.from_vec3(child.global_position - global_position).add(real_trans.origin)
			target_idxs.append(Targets.add_target(child))
			targets.append(child)
	
	self.hit.connect(func ():
		queue_free())
	
	if trail:
		trail.curve.point_count = 4
		print(trail.curve.get_point_position(0))
		while trail.curve.point_count < 4:
			trail.curve.add_point(Vector3.ZERO)

var is_firing: bool = false

func _process(_delta: float) -> void:
	if trail:
		for i in trail.curve.point_count - 1:
			trail.curve.set_point_position(i, trail.curve.get_point_position(i + 1))
		trail.curve.set_point_position(trail.curve.point_count - 1, global_position)
	for i in targets.size():
		targets[i].real_pos.x = targets[i].global_position.x - global_position.x + real_trans.origin.x
		targets[i].real_pos.y = targets[i].global_position.y - global_position.y + real_trans.origin.y
		targets[i].real_pos.z = targets[i].global_position.z - global_position.z + real_trans.origin.z
	
	if Targets.is_target_live(0) == false:
		for weapon in weapons:
			weapon.has_target = false
		return
	attack_target = Targets.list[0]
	var global := attack_target.sub(Globals.origin).to_vec3()
	
	for weapon in weapons:
		weapon.has_target = true
		weapon.target = weapon.to_local(global)
	
	if is_firing == true:
		for w in weapons.size():
			var weapon := weapons[w]
			if weapon.barrelvisbuf == false:
				weapon.barrel_end.visible = false
			weapon.barrelvisbuf = false
			#weapon.barrel_end.visible = false
			weapon_times[w] -= _delta
			
			if weapon.is_ontarget:
				var i = 0
				while weapon_times[w] < 0:
					i += 1
					weapon.barrel_end.visible = true
					weapon.barrel_end.rotation.z = randf_range(-PI, PI)
					weapon.target_ray.force_raycast_update()
					
					#if weapon.target_ray.is_colliding():
					var vel := -weapon.pivot.global_basis.z * 150
					var at := (weapon.barrel_end.global_position - global_position
							+ ( absf(weapon_times[w]) * vel))
					
					Projectiles.create(
						DoubleVector.from_vec3(at).add(real_trans.origin), 
						weapon.pivot.global_basis, 
						vel,
						weapon.projectile_mass, 
						weapon.projectile_scale
						)
					apply_impulse(-weapon.projectile_mass * vel, 
						weapon.barrel_end.global_position - global_position)
					#print(absf(weapon_times[w]))
					weapon_times[w] += weapon_intervals[w] * (1 + (randf() - 0.5) * weapon_jitter[w])
				#print(i)
			else:
				weapon_times[w] = maxf(0, weapon_times[w])
	else:
		for weapon in weapons:
			if weapon.barrelvisbuf == false:
				weapon.barrel_end.visible = false
			weapon.barrelvisbuf = false

func start_firing() -> void:
	is_firing = true
	
	for w in weapons.size():
		weapon_times[w] = 0.0

func stop_firing() -> void:
	is_firing = false

signal hit

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	real_trans.origin.x += state.transform.origin.x - prev.x
	real_trans.origin.y += state.transform.origin.y - prev.y
	real_trans.origin.z += state.transform.origin.z - prev.z
	prev = state.transform.origin
	
	if (thrusters or rcs) == false:
		return
	
	for thruster in thrusters:
		if thruster.throttle == 0.0: continue
		state.apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - state.transform.origin)
	
	if not rcs:
		return
	
	var force_sum := Vector3.ZERO
	var torque_sum := Vector3.ZERO
	
	# NOTE: if its looking slightly off, CHECK IF THE !!!COLLISIONS SHAPES!!! ARE CENTERED!!!!
	# Times this has happened count: 3
	for rc in rcs:
		if rc.active == false: continue
		var force := rc.global_basis.z * rc.magnitude
		force_sum += force
		
		var torque := (rc.global_position - state.transform.origin).cross(force)
		torque_sum += torque
	
	state.apply_central_force(force_sum)
	state.apply_torque(torque_sum)

func _exit_tree() -> void:
	for t in target_idxs:
		Targets.free_target(t)
