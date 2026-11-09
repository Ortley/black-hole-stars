extends Node

@export var target: NormalSpaceBody

const LOWER_BOUND = 0.0
const UPPER_BOUND = 1.0

var intent_yaw: float = 0.0
var intent_pitch: float = 0.0
var intent_roll: float = 0.0

var intent_z: float = 0.0

var n: int = 0
var bvls_context: BVLS.Context

func _ready() -> void:
	n = target.rcs.size()
	
	var lower: PackedFloat64Array
	lower.resize(n)
	lower.fill(LOWER_BOUND)
	var upper: PackedFloat64Array
	upper.resize(n)
	upper.fill(UPPER_BOUND)
	
	bvls_context = BVLS.Context.new(build_matrix(), lower, upper)

var wn := 1.9
var zeta := 1.65
var k_p := wn ** 2
var k_d := zeta * 2 * wn

var target_col: PackedFloat64Array = []
var result: Array = []
var locked_target: Quaternion = Quaternion.IDENTITY

func attitude_error(q: Quaternion, t: Quaternion) -> Vector3:
	var error := q.inverse() * t # target orientation relative to current orientation
	if error.w < 0.0: # like 330deg -> -30deg
		error = Quaternion(-error.x, -error.y, -error.z, -error.w)
	var v := Vector3(error.x,error.y, error.z) # axis
	var s := v.length()
	if s < 1e-9: # angle / s is janky on near-zero s atan2
		return 2.0 * v
	# https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
	var angle := 2.0 * atan2(s, error.w)
	return v * (angle / s)

var was_angular_velocity_low := true
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("kill_rotation"):
		if target.angular_velocity.length() < (TAU * 3.0 / 360) and was_angular_velocity_low == false:
			was_angular_velocity_low = true
			locked_target = target.quaternion
	else:
		was_angular_velocity_low = false
	print(was_angular_velocity_low)
	print(target.angular_velocity.length())
	print(locked_target)
	if Input.is_action_just_pressed("sas"):
		#if target.linear_velocity.is_zero_approx() == false:
		locked_target = target.quaternion#Basis.looking_at(-target.linear_velocity).get_rotation_quaternion()
	
	var rotation_intent = Vector3.ZERO
	if Input.is_action_pressed("sas") or Input.is_action_pressed("kill_rotation"):
		var error := attitude_error(target.quaternion, locked_target)
		
		var alpha_cmd := - k_d * (target.quaternion.inverse() * target.angular_velocity)
		
		# only include error relative to locked when on sas or near to zero rotation, else just act on current angular_velocity
		if Input.is_action_pressed("sas") or target.angular_velocity.length() < (TAU * 3.0 / 360):
			alpha_cmd += k_p * error
		
		rotation_intent = alpha_cmd
	var linear_intent := Vector3.ZERO
	if Input.is_action_pressed("kill_rotation"):
		linear_intent = -k_d * (target.global_basis.inverse() * target.linear_velocity)
	
	rotation_intent.y += Input.get_axis("test_cam_right", "test_cam_left")
	rotation_intent.x += Input.get_axis("test_cam_forward", "test_cam_backward")
	rotation_intent.z += -Input.get_axis("roll_left", "roll_right")
	
	rotation_intent *= target.mass
	linear_intent *= target.mass
	
	intent_z = Input.get_axis("throttle_decrease", "throttle_increase")
	
	target_col = PackedFloat64Array([linear_intent.x, linear_intent.y, linear_intent.z, rotation_intent.x, rotation_intent.y, rotation_intent.z])
	result = BVLS.solve_bvls2(bvls_context, target_col)
	print(target_col)
	print(result)
	#print(result.map(func (x): return snappedf(x, 0.1)))
	
	for i in target.rcs.size():
		target.rcs[i].active = result[i] > 0.5
	for t in target.thrusters:
		t.throttle = clampf(t.throttle + intent_z * delta * 2, 0, 1)
	
	Globals.ship_linear_velocity = target.linear_velocity
	Globals.ship_angular_velocity = target.angular_velocity
	Globals.rcs_activation = result
	Globals.thruster_throttle = target.thrusters[0].throttle
	#speed.text = "%s m/s" % snappedf(target.linear_velocity.length(), 0.1)

func build_matrix():
	var rcs_matrix: Array[PackedFloat64Array]
	
	for rcs in target.rcs:
		if rcs.enabled == false: 
			rcs_matrix.append([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
			continue
		var force := rcs.local_transform.basis.z.snappedf(1e-5).scale(rcs.magnitude)
		
		var offset := rcs.local_transform.origin.snappedf(1e-5)
		var torque := offset.cross(force)
		
		var row = PackedFloat64Array([
			(force.x), (force.y), (force.z), 
			(torque.x), (torque.y), (torque.z)
		])
		
		rcs_matrix.append(row)
	
	return rcs_matrix
