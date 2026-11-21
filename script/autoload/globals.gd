extends Node


var ship_orientation := Basis.IDENTITY
var ship_linear_velocity := Vector3.ZERO
var ship_angular_velocity := Vector3.ZERO
var rcs_activation := []
var thruster_throttle := 0.0
var current_target := DoubleVectorHistory.new()


func _ready() -> void:
	
	var a := DoubleVector.new(1, 2, 3)
	
	print("%s bytes in %s" % [var_to_bytes_with_objects(a).size(), a])
