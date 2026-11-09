extends RefCounted
class_name PIDController

var k_p: float = 0.0
var k_i: float = 0.0
var k_d: float = 0.0

var integral: Variant
var prev: Variant


func _init(k_p: float = 0.0, k_i: float = 0.0, k_d: float = 0.0) -> void:
	self.k_p = k_p
	self.k_i = k_i
	self.k_d = k_d

func stateful_activation(error, delta) -> Variant:
	if integral == null:
		integral = error
	if prev == null:
		prev = error
	integral += error
	var derivative = error - prev
	prev = error
	
	return activation(error, integral, derivative)

func activation(p, i, d) -> Variant:
	return k_p * p + k_i * i + k_d * d

func pd_activation(p, d) -> Variant:
	return k_p * p + k_d * d
