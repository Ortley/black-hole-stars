extends RigidBody3D
class_name NormalSpaceBody

@onready var real_pos: DoubleVector = DoubleVector.new(position.x, position.y, position.z)
var thrusters: Array[Thruster]
var rcs: Array[RCS]
var prev: Vector3

func _ready() -> void:
	can_sleep = false
	add_to_group("space_bodies")
	for child in find_children("*", "", true, true):
		if child is Thruster:
			thrusters.append(child)
		elif child is RCS:
			rcs.append(child)
	real_pos.x = position.x
	real_pos.y = position.y
	real_pos.z = position.z

func _physics_process(delta: float) -> void:
	real_pos.x += position.x - prev.x
	real_pos.y += position.y - prev.y
	real_pos.z += position.z - prev.z
	prev = position
	
	for thruster in thrusters:
		apply_force(thruster.magnitude * thruster.global_basis.z * thruster.throttle, thruster.global_position - global_position)
	for rc in rcs:
		#print(rc.throttle)
		#apply_force(rc.magnitude * rc.global_basis.z * rc.throttle, rc.global_position - global_position)
		apply_force(rc.magnitude * rc.global_basis.z * int(rc.active), rc.global_position - global_position)
	
