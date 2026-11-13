extends Node

@export var target: NormalSpaceBody

const LOWER_BOUND = 0.0
const UPPER_BOUND = 1.0

var intent_z: float = 0.0

var bvls_context: BVLS.Context
var pd_controller := SpringController.new(1.9, 1.65)

var target_col: PackedFloat64Array = []
var activation: PackedFloat64Array = []
var locked_target: Quaternion = Quaternion.IDENTITY

func _ready() -> void:
	var n := target.rcs.size()
	
	var lower: PackedFloat64Array
	lower.resize(n)
	lower.fill(LOWER_BOUND)
	var upper: PackedFloat64Array
	upper.resize(n)
	upper.fill(UPPER_BOUND)
	
	bvls_context = BVLS.Context.new(build_rcs_matrix(), lower, upper)


var was_angular_velocity_low := true
func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("fire"):
		target.fire.emit()
	
	if Input.is_action_pressed("kill_rotation"):
		if target.angular_velocity.length() < (TAU * 3.0 / 360) and was_angular_velocity_low == false:
			was_angular_velocity_low = true
			locked_target = target.quaternion
	else:
		was_angular_velocity_low = false
	
	intent_z = Input.get_axis("throttle_decrease", "throttle_increase")
	intent_z *= delta * 2
	for t in target.thrusters:
		t.throttle = clampf(t.throttle + intent_z , 0, 1)

	activation = BVLS.solve_bvls2(bvls_context, get_target_col())
	
	apply_activation()
	update_globals()

func apply_activation() -> void:
	for i in target.rcs.size():
		target.rcs[i].active = activation[i] > 0.5

func get_target_col() -> PackedFloat64Array:
	var linear_intent := Vector3.ZERO
	var rotation_intent := Vector3.ZERO
	
	if Input.is_action_just_pressed("sas"):
		locked_target = target.quaternion
	
	if Input.is_action_pressed("sas") or Input.is_action_pressed("kill_rotation"):
		var error := attitude_error(target.quaternion, locked_target)

		#var alpha_cmd := - k_d * (target.quaternion.inverse() * target.angular_velocity)
		var local_angular_velocity := target.quaternion.inverse() * target.angular_velocity
		var alpha_cmd: Vector3
		# only include error relative to locked when on sas or near to zero rotation, else just act on current angular_velocity
		if Input.is_action_pressed("sas") or target.angular_velocity.length() < (TAU * 3.0 / 360):
			alpha_cmd = pd_controller.pd_activation(error, -local_angular_velocity)
		else:
			alpha_cmd = pd_controller.pd_activation(Vector3.ZERO, -local_angular_velocity)
		
		rotation_intent = alpha_cmd
	
	rotation_intent.x += Input.get_axis("pitch_down", "pitch_up")
	rotation_intent.y += Input.get_axis("yaw_right", "yaw_left")
	rotation_intent.z += Input.get_axis("roll_cw", "roll_acw")
	
	rotation_intent *= target.mass
	linear_intent *= target.mass
	
	return [linear_intent.x, linear_intent.y, linear_intent.z, rotation_intent.x, rotation_intent.y, rotation_intent.z]

func update_globals() -> void:
	Globals.ship_linear_velocity = target.linear_velocity
	Globals.ship_angular_velocity = target.angular_velocity
	Globals.rcs_activation = activation
	Globals.thruster_throttle = target.thrusters[0].throttle

static func attitude_error(q: Quaternion, t: Quaternion) -> Vector3:
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

func build_rcs_matrix():
	var rcs_matrix: Array[PackedFloat64Array]
	
	for rc in target.rcs:
		if rc.enabled == false: 
			rcs_matrix.append([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
			continue
		rcs_matrix.append(get_rcs_wrench(rc))
	
	return rcs_matrix

static func get_rcs_wrench(rcs: RCS) -> PackedFloat64Array:
	var force := rcs.local_transform.basis.z.snappedf(1e-5).scale(rcs.magnitude)
	var offset := rcs.local_transform.origin.snappedf(1e-5)
	
	return DoubleVector.get_wrench(force, offset)

func edit_rcs_row(idx: int, new: PackedFloat64Array) -> void:
	assert(new.size() == 6)
	bvls_context.A[idx] = new
