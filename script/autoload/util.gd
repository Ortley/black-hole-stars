extends Node

static func pf64_add(x: PackedFloat64Array, rhs: PackedFloat64Array) -> void:
	for i in mini(x.size(), rhs.size()):
		x[i] += rhs[i]
