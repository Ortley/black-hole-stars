extends Object
class_name BVLS

static func solve_bvls(
	A: Array[PackedFloat64Array], 
	b: PackedFloat64Array,
	l: PackedFloat64Array,
	u: PackedFloat64Array,
	tolerance: float = 1e-5
) -> PackedFloat64Array:
	var n = A.size()
	
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
	for i in n:
		x[i] = l[i]
	
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
		while not all_free_inside(z, l, u, free) and guard < 2 * n:
			guard += 1
			
			var alpha := INF
			var q := -1
			for jp in n:
				if not free[jp]:
					continue
				if not (z[jp] <= l[jp] or u[jp] <= z[jp]):
					continue
				var d: float = z[jp] - x[jp]
				var bound := l[jp] if z[jp] <= l[jp] else u[jp]
				var ratio := 0.0 if d == 0.0 else (bound - x[jp]) / d
				if ratio < alpha:
					alpha = ratio
					q = jp # simpler than doing the whole J chain stuff
			for i in n:
				if free[i]:
					x[i] += alpha * (z[i] - x[i])
			
			# Forces q onto bounds
			x[q] = l[q] if z[q] <= l[q] else u[q]
			for i in n:
				if not free[i]:
					continue
				if x[i] <= l[i]:
					x[i] = l[i]
					free[i] = false
					upper[i] = false
				elif x[i] >= u[i]:
					x[i] = u[i]
					free[i] = false
					upper[i] = true
			z = solve_free(A, b, x, free) # GOTO step 6
			if z == null:
				break
		if z != null:
			x = z
		w = gradient(A, b, x) # step 2
	
	return x


static func solve_free(
	A: Array[PackedFloat64Array], 
	b: PackedFloat64Array, 
	x: PackedFloat64Array, 
	free: Array[bool], 
	last: int = -1, 
	eps := 1e-12
):
	var n := A.size()
	var m := A[0].size()
	
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

static func all_free_inside(z: PackedFloat64Array, l: PackedFloat64Array, u: PackedFloat64Array, free: Array[bool]) -> bool:
	for j in z.size():
		if free[j] and (z[j] <= l[j] or u[j] <= z[j]):
			return false
	return true


# w = A^T * (b -Ax)
static func gradient(A: Array[PackedFloat64Array], b: PackedFloat64Array, x: PackedFloat64Array) -> PackedFloat64Array:
	var n := A.size()
	var m := A[0].size()
	# residual
	var r := b.duplicate()
	for j in n:
		for i in m:
			r[i] -= A[j][i] * x[j]
	# dual vector
	var w := PackedFloat64Array()
	w.resize(n)
	for j in n:
		w[j] = dot(A[j], r)
	return w

static func dot(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	var prod := 0.0
	for i in a.size():
		prod += a[i] * b[i]
	return prod
