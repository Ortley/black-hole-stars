extends PIDController
class_name PIDSpring

func _init(wn: float = 0.0, zeta: float = 0.0) -> void:
	self.k_p = wn ** 2
	self.k_i = 0.0
	self.k_d = zeta * 2 * wn
