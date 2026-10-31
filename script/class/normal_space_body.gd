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
			print("RCS")
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

var applied := false
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	real_trans.origin.x += state.transform.origin.x - prev.x
	real_trans.origin.y += state.transform.origin.y - prev.y
	real_trans.origin.z += state.transform.origin.z - prev.z
	real_trans.basis = DoubleBasis.from_basis(state.transform.basis).snappedf(1e-5)
	prev = state.transform.origin
	
	for thruster in thrusters:
		state.apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - state.transform.origin)
	
	var force_sum := DoubleVector.new()
	var torque_sum := DoubleVector.new()
	
	for rc in rcs:
		if rc.active == false: continue
		var direction := real_trans.basis.mul(rc.local_transform.basis).z
		var x := rc.magnitude * direction.x
		var y := rc.magnitude * direction.y 
		var z := rc.magnitude * direction.z
		
		#print(direction.z)
		
		
		var force := DoubleVector.new(x, y, z)
		
		force_sum.x += x
		force_sum.y += y
		force_sum.z += z
		
		var a := rc.global_position.x - state.transform.origin.x
		var b := rc.global_position.y - state.transform.origin.y
		var c := rc.global_position.z - state.transform.origin.z
		
		var torque := DoubleVector.new(a,b,c).cross(force)
		torque_sum.x += torque.x
		torque_sum.y += torque.y
		torque_sum.z += torque.z
		
	
	if rcs:
		#print(torque_sum)
		#apply_central_force(force_sum.to_vec3())
		#state.linear_velocity += force_sum.to_vec3() * state.inverse_mass * state.step
		state.angular_velocity += torque_sum.mul(DoubleVector.from_vec3(real_trans.basis.to_basis() * state.inverse_inertia)).to_vec3() * state.step
		#apply_torque(torque_sum.to_vec3())
		#print(torque_sum.to_vec3())
		applied = true
		
		#print(state.inverse_inertia.inverse())


func _exit_tree() -> void:
	for t in target_idxs:
		Targets.free_target(t)
