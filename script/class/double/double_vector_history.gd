extends DoubleVector
class_name DoubleVectorHistory

var delta: DoubleVector

func push(new: DoubleVector, timestep: float) -> void:
	delta = new.sub(self).divf(timestep)
	copy_from(new)

func _to_string() -> String:
	return "(%s, %s, %s)" % [x,y,z]
