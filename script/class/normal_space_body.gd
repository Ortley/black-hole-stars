extends RigidBody3D
class_name NormalSpaceBody

@onready var real_trans: DoubleTransform = DoubleTransform.from_transform(global_transform)
var thrusters: Array[Thruster]
var rcs: Array[RCS]
var weapons: Array[Weapon]
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
		elif child is Target:
			child.real_pos = DoubleVector.from_vec3(child.global_position - global_position).add(real_trans.origin)
			target_idxs.append(Targets.add_target(child))
			targets.append(child)
			
	
	self.fire.connect(func (): 
		for weapon in weapons:
			if weapon.is_ontarget:
				print(weapon.fire_timeout)
				if weapon.fire_timeout < 0:
					weapon.target_ray.force_raycast_update()
					
					#if weapon.target_ray.is_colliding():
					Projectiles.create(
						DoubleVector.from_vec3(weapon.barrel_end.global_position - global_position + 0.0 * ( absf(weapon.fire_timeout) * -weapon.pivot.global_basis.z * 100)).add(real_trans.origin), 
						weapon.pivot.global_basis, 
						-weapon.pivot.global_basis.z * 100
						)
					weapon.fire_timeout += weapon.fire_timing
		)
	self.hit.connect(func ():
		queue_free())
	
	if trail:
		trail.curve.point_count = 4
		print(trail.curve.get_point_position(0))
		while trail.curve.point_count < 4:
			trail.curve.add_point(Vector3.ZERO)


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
	var global := attack_target.to_vec3()
	
	for weapon in weapons:
		weapon.has_target = true
		weapon.target = weapon.to_local(global)

signal fire
signal hit

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	real_trans.origin.x += state.transform.origin.x - prev.x
	real_trans.origin.y += state.transform.origin.y - prev.y
	real_trans.origin.z += state.transform.origin.z - prev.z
	prev = state.transform.origin
	
	for thruster in thrusters:
		if thruster.throttle == 0.0: continue
		state.apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - state.transform.origin)
	
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
	
	if rcs:
		state.apply_central_force(force_sum)
		state.apply_torque(torque_sum)
	
	

func _exit_tree() -> void:
	for t in target_idxs:
		Targets.free_target(t)
