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
	
	real_pos.x = position.x
	real_pos.y = position.y
	real_pos.z = position.z

func _process(delta: float) -> void:
	var p := DoubleVector.new()
	for i in targets.size():
		p.x = targets[i].global_position.x - global_position.x + real_pos.x
		p.y = targets[i].global_position.y - global_position.y + real_pos.y
		p.z = targets[i].global_position.z - global_position.z + real_pos.z
		Targets.update_target_pos(target_idxs[i], p.x, p.y, p.z)
	
	if weapons and weapons[0]:
		attack_target = Targets.list[0].real_pos
		var global := attack_target.vec3()
		
		weapons[0].target = weapons[0].to_local(global)
		weapons[1].target = weapons[1].to_local(global)


func _physics_process(_delta: float) -> void:
	real_pos.x += position.x - prev.x
	real_pos.y += position.y - prev.y
	real_pos.z += position.z - prev.z
	prev = position
	
	for thruster in thrusters:
		apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - global_position)
	for rc in rcs:
		apply_force(rc.magnitude * rc.global_basis.z * int(rc.active), rc.global_position - global_position)
	

func _exit_tree() -> void:
	for t in target_idxs:
		Targets.free_target(t)
