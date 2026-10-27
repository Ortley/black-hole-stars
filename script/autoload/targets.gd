extends Node

var list: Array[DoubleVector] = []
var mask: Array[bool] = []

var free_count: int = 0
var lowest_free: int = 0
var highest_free: int = 0

func add_target(t: Target) -> int:
	var idx := -1
	if free_count == 0:
		list.append(t.real_pos)
		#list[-1] = t.real_pos
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

func free_target(i: int) -> void:
	mask[i] = false
	
	lowest_free = min(lowest_free, i)
	highest_free = max(highest_free, i)
	free_count += 1
