extends Node

# https://en.wikipedia.org/wiki/Non-negative_least_squares

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

func _physics_process(delta: float) -> void:
	intent_yaw = Input.get_axis("test_cam_right", "test_cam_left") * 1000
	intent_roll = -Input.get_axis("roll_left", "roll_right") * 1000
	intent_pitch = Input.get_axis("test_cam_forward", "test_cam_backward") * 1000
	
	intent_z = Input.get_axis("throttle_decrease", "throttle_increase")
	
	var target_col := PackedFloat64Array([0.0, 0.0, 0.0, intent_pitch, intent_yaw, intent_roll])
	var result: Array = solve_nnls(rcs_matrix, target_col)
	#print(result.map(func (x): return x > 0))
	
	for i in n:
		target.rcs[i].throttle = result[i]
		
	for t in target.thrusters:
		t.throttle = clampf(t.throttle + intent_z * delta * 2, 0, 1)

func solve_nnls(A: Array[PackedFloat64Array], target_col: PackedFloat64Array, tolerance: float = 1e-5) -> PackedFloat64Array:
	# P = null set
	# R = {1 ... n} (everything active)
	# both are sets of indices, so a shared set with bool on whether its passive can be used
	var passive: Array[bool] = [] # bool mask over rcs
	passive.resize(n)
	passive.fill(false)
	
	# Set x to an all-zero vector of dimension n
	var x := PackedFloat64Array()
	x.resize(n)
	x.fill(0.0)
	
	# w = A^T * (b - Ax)
	var w = gradient(A, target_col, x)
	
	
	# main loop
	for _outer in 3 * n:
		if _outer == 3 * n - 1:
			print("!!! reached end")
		# stopping test for KTT conditions
		# "while R != null set and max(W^R) > epsilon"
		var j := -1
		var best := tolerance
		
		for i in n:
			if not passive[i] and w[i] > best:
				best = w[i]
				j = i
		if j == -1:
			break
		
		# add j to P, remove j from R
		passive[j] = true
		# let AP be A restrixted to the variables included in P
		var s = solve_passive(A, target_col, passive)
		
		# Repair mode
		for _inner in 3 * n:
			var a := INF
			for i in n:
				if passive[i] and s[i] <= tolerance:
					var denominator = x[i] - s[i]
					if absf(denominator) < 1e-12:
						a = 0.0
					else:
						a = minf(a, x[i] / denominator)
			if a == INF:
				break
			
			for i in n:
				x[i] += a * (s[i] - x[i])
			for i in n:
				if passive[i] and x[i] <= tolerance:
					passive[i] = false
					x[i] = 0.0
			s = solve_passive(A, target_col, passive)
		
		x = s
		w = gradient(A, target_col, x)
	
	return x

var resid: PackedFloat64Array
# w = A^T * (b -Ax)
func gradient(A: Array[PackedFloat64Array], b: PackedFloat64Array, x: PackedFloat64Array):
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

func build_matrix():
	n = 0
	m = 6
	
	rcs_matrix.clear()
	activation = PackedFloat64Array()
	
	for rcs in target.rcs:
		var force := (target.global_basis.inverse() * rcs.global_basis).z.normalized() * rcs.magnitude
		
		var torque := (rcs.global_position - target.global_position).cross(force)
		
		var row = PackedFloat64Array([
			snappedf(force.x, 1e-3), snappedf(force.y, 1e-3), snappedf(force.z, 1e-3), 
			snappedf(torque.x, 1e-3), snappedf(torque.y, 1e-3), snappedf(torque.z, 1e-3)
		])
		
		rcs_matrix.append(row)
		
		print(row)
	
	
	n = rcs_matrix.size()
	activation.resize(n)
	activation.fill(0.0)
