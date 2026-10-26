extends Node

# https://en.wikipedia.org/wiki/Non-negative_least_squares

const LOWER_BOUND = 0.0
const UPPER_BOUND = 1.0
@onready var speed: Label = $"../UI/Control/MarginContainer/CenterContainer/HBoxContainer/Speed"

@export var target: NormalSpaceBody
var intent_yaw: float = 0.0
var intent_pitch: float = 0.0
var intent_roll: float = 0.0

var intent_z: float = 0.0

var m: int = 6
var n: int = 0

var rcs_matrix: Array[PackedFloat64Array] # m x n
var activation: PackedFloat64Array # m x 1

func _ready() -> void:
	build_matrix()

var tick = 0
var target_col: PackedFloat64Array = []
var result: Array = []
var locked_target: Vector3 = Vector3.ONE
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("sas"):
		locked_target = target.rotation
	if Input.is_action_pressed("sas"):
		var diff = locked_target - (target.rotation + 2 * target.angular_velocity)
		intent_yaw = diff.y * 1000
		intent_pitch = diff.x * 1000
		intent_roll = diff.z * 1000
	else:
		intent_yaw = Input.get_axis("test_cam_right", "test_cam_left") * 1000
		intent_pitch = Input.get_axis("test_cam_forward", "test_cam_backward") * 1000
		intent_roll = -Input.get_axis("roll_left", "roll_right") * 1000
	
	intent_z = Input.get_axis("throttle_decrease", "throttle_increase")
	
	target_col = PackedFloat64Array([0.0, 0.0, 0.0, intent_pitch, intent_yaw, intent_roll])
	result = solve_bvls(rcs_matrix, target_col)
	
	for i in n:
		target.rcs[i].active = result[i] > 0.5
	for t in target.thrusters:
		t.throttle = clampf(t.throttle + intent_z * delta * 2, 0, 1)
	
	
	speed.text = "%s m/s" % snappedf(target.linear_velocity.length(), 0.1)

func solve_bvls(
	A: Array[PackedFloat64Array], 
	b: PackedFloat64Array, 
	tolerance: float = 1e-5
) -> PackedFloat64Array:
	# 1.If this is a cold start, set F = U = ∅, L = {1, · · · , n}, and set 
	# every element of x to its lower bound
	# F - indices of "free" components of x that are strictly between their 
	# lower and upper bounds
	var free: Array[bool] = []
	free.resize(n)
	free.fill(false)
	var upper: Array[bool] = []
	upper.resize(n)
	upper.fill(false)
	var x := PackedFloat64Array()
	x.resize(n)
	x.fill(LOWER_BOUND)
	
	var w := gradient(A, b, x)
	# main loop
	for _outer in 3 * n:
		# Compute w = AT (b − Ax), the negative of the gradient of the squared objective
		
		if _outer == 3 * n - 1:
			print("!!! reached cap")

		# KKT test conditions + step 4
		var j := -1
		var best := tolerance
		
		# GOTO step 12 if ...
		for i in n:
			# F = {1, · · · , n}, or ...
			if free[i]:
				continue
			# w_j <= 0 for j in Lower and w_j >= 0 for j in Upper 
			# combined with step 4
			var v := -w[i] if upper[i] else w[i] # s_t * w_t
			if v > best:
				best = v;
				j = i
		# Successful convergence = no violation above tolerance
		if j == -1:
			break
		
		# 5. Move t* to the set F
		free[j] = true
		
		var z = solve_free(A, b, x, free, j)
		if z == null:
			free[j] = false
			w[j] = 0.0
			continue # GOTO step 3
		
		# Stops infinite recursion
		# steps 7..11
		var guard := 0
		while not all_free_inside(z, LOWER_BOUND, UPPER_BOUND, free) and guard < 2 * n:
			guard += 1
			
			var alpha := INF
			var q := -1
			for jp in n:
				if not free[jp]:
					continue
				if not (z[jp] <= LOWER_BOUND or UPPER_BOUND <= z[jp]):
					continue
				var d: float = z[jp] - x[jp]
				var bound := LOWER_BOUND if z[jp] <= LOWER_BOUND else UPPER_BOUND
				var ratio := 0.0 if d == 0.0 else (bound - x[jp]) / d
				if ratio < alpha:
					alpha = ratio
					q = jp # simpler than doing the whole J chain stuff
			for i in n:
				if free[i]:
					x[i] += alpha * (z[i] - x[i])
			
			# Forces q onto bounds
			x[q] = LOWER_BOUND if z[q] <= LOWER_BOUND else UPPER_BOUND
			for i in n:
				if not free[i]:
					continue
				if x[i] <= LOWER_BOUND:
					x[i] = LOWER_BOUND
					free[i] = false
					upper[i] = false
				elif x[i] >= UPPER_BOUND:
					x[i] = UPPER_BOUND
					free[i] = false
					upper[i] = true
			z = solve_free(A, b, x, free) # GOTO step 6
			if z == null:
				break
		if z != null:
			x = z
		w = gradient(A, b, x) # step 2
	
	return x


#
## Step 2
#func _solve_bvls_inner(
	#A: Array[PackedFloat64Array], 
	#target_col: PackedFloat64Array, 
	#tolerance: float, 
	#free: Array[bool], 
	#upper: Array[bool], 
	#x: PackedFloat64Array
#) -> PackedFloat64Array:

func all_free_inside(z: PackedFloat64Array, l: float, u: float, free: Array[bool]) -> bool:
	for j in z.size():
		if free[j] and (z[j] <= l or u <= z[j]):
			return false
	return true

var resid: PackedFloat64Array
# w = A^T * (b -Ax)
func gradient(A: Array[PackedFloat64Array], b: PackedFloat64Array, x: PackedFloat64Array) -> PackedFloat64Array:
	# residual
	var r := b.duplicate()
	for j in n:
		for i in m:
			r[i] -= A[j][i] * x[j]
	resid = r
	# dual vector
	var w := PackedFloat64Array()
	w.resize(n)
	for j in n:
		w[j] = dot(A[j], r)
	return w

func dot(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	var prod := 0.0
	for i in a.size():
		prod += a[i] * b[i]
	return prod

func solve_free(
	A: Array[PackedFloat64Array], 
	b: PackedFloat64Array, 
	x: PackedFloat64Array, 
	free: Array[bool], 
	last: int = -1, 
	eps := 1e-12
):
	
	var idx: Array[int] = []
	for j in n:
		if free[j] and j != last:
			idx.append(j)
	if last >= 0 and free[last]:
		idx.append(last)
	var k := idx.size()
	
	var s := x.duplicate()
	if k == 0:
		return s
	if k > m:
		 # more free columns than rows, therefore they must be dependent 
		return null
	
	var bp := b.duplicate()
	for c in n:
		if not free[c] and x[c] != 0.0:
			for t in m:
				bp[t] -= A[c][t] * x[c]
	
	# Gram-Schmidt QR decomposition over the free columns
	var Q: Array[PackedFloat64Array] = []
	var R: Array = []
	
	# GS: init R
	for i in k:
		var row := PackedFloat64Array()
		row.resize(k)
		row.fill(0.0)
		R.append(row)
	
	for j in k:
		var v := A[idx[j]].duplicate()
		var col_norm := sqrt(dot(v, v))
		if col_norm == 0.0:
			return null
		for i in j:
			R[i][j] = dot(Q[i], v)
			for t in m:
				v[t] -= R[i][j] * Q[i][t]
		var norm := sqrt(dot(v,v))
		if norm <= eps * col_norm:
			return null
			
		R[j][j] = norm
		var q := PackedFloat64Array()
		q.resize(m)
		for t in m:
			q[t] = v[t] / norm
		Q.append(q)
	
	var y := PackedFloat64Array()
	y.resize(k)
	y.fill(0.0)
	for i in range(k - 1, -1, -1):
		var acc := dot(Q[i], bp)
		for j in range(i + 1, k):
			acc -= R[i][j] * y[j]
		y[i] = acc / R[i][i]
	
	for i in k:
		s[idx[i]] = y[i]
	
	return s


func build_matrix():
	n = 0
	m = 6
	
	rcs_matrix.clear()
	activation = PackedFloat64Array()
	
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
		
	
	
	n = rcs_matrix.size()
	activation.resize(n)
	activation.fill(0.0)



# sP = (( A^P )^T A^P )^-1 ( A^P )^T y
func solve_passive(A: Array[PackedFloat64Array], b: PackedFloat64Array, passive: Array[bool], eps: float = 1e-12):
	var idx: Array[int] = []
	for j in n:
		if passive[j]:
			idx.append(j)
	var k := idx.size()
	
	var s := PackedFloat64Array()
	s.resize(n)
	s.fill(0.0)
	if k == 0: return s
	
	var Q: Array[PackedFloat64Array] = []
	var R: Array = []
	for i in k:
		var row := PackedFloat64Array()
		row.resize(k)
		row.fill(0.0)
		R.append(row)
	
	for j in k:
		var v := A[idx[j]].duplicate()
		for i in j:
			R[i][j] = dot(Q[i], v)
			for t in m:
				v[t] -= R[i][j] * Q[i][t]
		var norm := sqrt(dot(v, v))
		R[j][j] = norm
		var q := PackedFloat64Array()
		q.resize(m)
		q.fill(0.0)
		if norm > eps:
			for t in m:
				q[t] = v[t] / norm
		Q.append(q)
	
	var y := PackedFloat64Array()
	y.resize(k)
	y.fill(0.0)
	
	for i in range(k - 1, -1, -1):
		if R[i][i] <= eps:
			continue
		var acc := dot(Q[i], b)
		for j in range(i + 1, k):
			acc -= R[i][j] * y[j]
		y[i] = acc / R[i][i]
	
	for i in k:
		s[idx[i]] = y[i]
	return s
