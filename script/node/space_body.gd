extends Node3D
class_name SpaceBody

# Godot uses float32 for Vector3, this is float64, capiche?
@export var real_pos := [0.0, 0.0, 0.0]


func _init() -> void:
	self.add_to_group("space_bodies")


func update_pos(with_origin: Array) -> void:
	self.position = Vector3(
		real_pos[0] - with_origin[0],
		real_pos[1] - with_origin[1],
		real_pos[2] - with_origin[2],
	)
