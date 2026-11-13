extends Node

var ship_orientation := Basis.IDENTITY
var ship_linear_velocity := Vector3.ZERO
var ship_angular_velocity := Vector3.ZERO
var rcs_activation := []
var thruster_throttle := 0.0
var current_target := DoubleVectorHistory.new()
