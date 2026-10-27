extends RigidBody3D
class_name NormalSpaceBody

@onready var real_pos: DoubleVector = DoubleVector.new(position.x, position.y, position.z)
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
			child.real_pos = DoubleVector.from_vec3(child.global_position - global_position).add(real_pos)
			target_idxs.append(Targets.add_target(child))
			targets.append(child)


func _process(delta: float) -> void:
	for i in targets.size():
		targets[i].real_pos.x = targets[i].global_position.x - global_position.x + real_pos.x
		targets[i].real_pos.y = targets[i].global_position.y - global_position.y + real_pos.y
		targets[i].real_pos.z = targets[i].global_position.z - global_position.z + real_pos.z
		
			#Targets.update_target_pos(target_idxs[i], p.x, p.y, p.z)
	
	attack_target = Targets.list[0]
	var global := attack_target.vec3()
	
	for weapon in weapons:
		print(global_position)
		weapon.target = weapon.to_local(global)

func _physics_process(_delta: float) -> void:
	real_pos.x += global_position.x - prev.x
	real_pos.y += global_position.y - prev.y
	real_pos.z += global_position.z - prev.z
	prev = global_position
	
	for thruster in thrusters:
		apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - global_position)
	for rc in rcs:
		apply_force(rc.magnitude * rc.global_basis.z * int(rc.active), rc.global_position - global_position)
	

func _exit_tree() -> void:
	for t in target_idxs:
		Targets.free_target(t)
