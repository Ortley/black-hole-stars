extends Node

@export var target: NormalSpaceBody

const LOWER_BOUND = 0.0
const UPPER_BOUND = 1.0
@onready var speed: Label = $"../UI/Control/MarginContainer/CenterContainer/HBoxContainer/Speed"

var intent_yaw: float = 0.0
var intent_pitch: float = 0.0
var intent_roll: float = 0.0

var intent_z: float = 0.0

var n: int = 0

var lower: PackedFloat64Array
var upper: PackedFloat64Array

var rcs_matrix: Array[PackedFloat64Array] # m x n
var activation: PackedFloat64Array # m x 1

func _ready() -> void:
	build_matrix()
	
	lower.resize(n)
	lower.fill(LOWER_BOUND)
	upper.resize(n)
	upper.fill(UPPER_BOUND)

var tick = 0
var target_col: PackedFloat64Array = []
var result: Array = []
var locked_target: Vector3 = Vector3.ONE
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("sas"):
		locked_target = target.rotation
	if Input.is_action_pressed("sas"):
		var diff := locked_target - (target.rotation + 2 * target.angular_velocity)
		intent_yaw = diff.y * 1000
		intent_pitch = diff.x * 1000
		intent_roll = diff.z * 1000
	else:
		intent_yaw = Input.get_axis("test_cam_right", "test_cam_left") * 1000
		intent_pitch = Input.get_axis("test_cam_forward", "test_cam_backward") * 1000
		intent_roll = -Input.get_axis("roll_left", "roll_right") * 1000
	
	intent_z = Input.get_axis("throttle_decrease", "throttle_increase")
	
	target_col = PackedFloat64Array([0.0, 0.0, 0.0, intent_pitch, intent_yaw, intent_roll])
	result = BVLS.solve_bvls(rcs_matrix, target_col, lower, upper)
	
	for i in n:
		target.rcs[i].active = result[i] > 0.5
	for t in target.thrusters:
		t.throttle = clampf(t.throttle + intent_z * delta * 2, 0, 1)
	
	
	speed.text = "%s m/s" % snappedf(target.linear_velocity.length(), 0.1)

func build_matrix():
	n = 0
	
	rcs_matrix.clear()
	
	for rcs in target.rcs:
		var force := (target.global_basis.inverse() * rcs.global_basis).z.normalized() * rcs.magnitude
		#var torque := (rcs.global_position - target.global_position).cross(force)
		
		var offset := target.global_basis.inverse() * (rcs.global_position - target.global_position)
		var torque := offset.cross(force)
		
		var row = PackedFloat64Array([
			snappedf(force.x, 1e-3), snappedf(force.y, 1e-3), snappedf(force.z, 1e-3), 
			snappedf(torque.x, 1e-3), snappedf(torque.y, 1e-3), snappedf(torque.z, 1e-3)
		])
		
		rcs_matrix.append(row)
	
	print(rcs_matrix)
	n = rcs_matrix.size()
