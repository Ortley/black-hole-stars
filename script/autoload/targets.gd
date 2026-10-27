extends Node

class TargetData:
	var real_pos: DoubleVector

var list: Array[TargetData] = []
var mask: Array[bool] = []

var free_count: int = 0
var lowest_free: int = 0
var highest_free: int = 0

func _process(delta: float) -> void:
	for t in list:
		print(t.real_pos)

func add_target(t: Target) -> int:
	var idx := -1
	if free_count == 0:
		list.append(TargetData.new())
		list[-1].real_pos = t.real_pos
		mask.append(true)
		idx = list.size() - 1
	else:
		idx = mask.find(false, lowest_free)
		list[idx].real_pos = t.real_pos
		mask[idx] = true
		
		free_count -= 1
		lowest_free = idx
		highest_free = max(lowest_free, highest_free)
	
	return idx

func update_target_pos(t: int, x: float, y: float, z: float):
	list[t].real_pos.x = x
	list[t].real_pos.y = y
	list[t].real_pos.z = z

func update_target(t: int, real_pos: DoubleVector):
	list[t].real_pos = real_pos

func free_target(i: int) -> void:
	mask[i] = false
	
	lowest_free = min(lowest_free, i)
	highest_free = max(highest_free, i)
	free_count += 1
