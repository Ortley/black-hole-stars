extends Node

var pts := PackedFloat64Array()
var count: int = 1024
var mask := PackedInt64Array()
var acc := PackedFloat64Array()

func _ready() -> void:
	pts.resize(3 * count)
	mask.resize(count / 64)
	acc.resize(3)
	acc.fill(0.0)
	
	pts.fill(0.0)
	mask.fill(0)
	
	add_point(1,1,1)
	add_point(2,2,2)

func is_free(n: int) -> bool:
	return mask[n / 64] & (1 << n % 64)

func get_first_free() -> int:
	for i in mask.size():
		if mask[i] != 0x7fffffffffffffff:
			var m := 0
			while (mask[i] & (1 << m)):
				m += 1
			return i * 64 + m
	return -1

func free_point(n: int) -> void:
	mask[n / 64] ^= 1 << n % 64

func add_point(x: float, y: float, z: float) -> int:
	var n := get_first_free()
	mask[n / 64] |= 1 << n % 64
	
	set_point(n, x, y, z)
	
	return n

func set_point(n: int, x: float, y: float, z: float) -> void:
	pts[n + 0] = x
	pts[n + 1] = y
	pts[n + 2] = z

func acc_lda(n: int) -> void:
	acc[0] = pts[n + 0]
	acc[1] = pts[n + 1]
	acc[2] = pts[n + 2]
func acc_add(n: int) -> void:
	acc[0] += pts[n + 0]
	acc[1] += pts[n + 1]
	acc[2] += pts[n + 2]
func acc_sub(n: int) -> void:
	acc[0] -= pts[n + 0]
	acc[1] -= pts[n + 1]
	acc[2] -= pts[n + 2]
func acc_mul(n: int) -> void:
	acc[0] *= pts[n + 0]
	acc[1] *= pts[n + 1]
	acc[2] *= pts[n + 2]
func acc_div(n: int) -> void:
	acc[0] /= pts[n + 0]
	acc[1] /= pts[n + 1]
	acc[2] /= pts[n + 2]
func acc_str(n: int) -> void:
	pts[n + 0] = acc[0]
	pts[n + 1] = acc[1]
	pts[n + 2] = acc[2]
	
