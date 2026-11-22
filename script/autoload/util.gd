extends Node

static func pf64_add(x: PackedFloat64Array, rhs: PackedFloat64Array) -> void:
	for i in mini(x.size(), rhs.size()):
		x[i] += rhs[i]
static func pf64_sub(x: PackedFloat64Array, rhs: PackedFloat64Array) -> void:
	for i in mini(x.size(), rhs.size()):
		x[i] -= rhs[i]
static func pf64_mul(x: PackedFloat64Array, rhs: PackedFloat64Array) -> void:
	for i in mini(x.size(), rhs.size()):
		x[i] *= rhs[i]

static func pf64(len: int, fill: float) -> PackedFloat64Array:
	var x := PackedFloat64Array()
	x.resize(len)
	x.fill(fill)
	return x
