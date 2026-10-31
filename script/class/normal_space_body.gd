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
	


#func _process(delta: float) -> void:
	#for i in targets.size():
		#targets[i].real_pos.x = targets[i].global_position.x - global_position.x + real_pos.x
		#targets[i].real_pos.y = targets[i].global_position.y - global_position.y + real_pos.y
		#targets[i].real_pos.z = targets[i].global_position.z - global_position.z + real_pos.z
		
	#attack_target = Targets.list[0]
	#var global := attack_target.vec3()
	#
	#for weapon in weapons:
		#weapon.target = weapon.to_local(global)

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
