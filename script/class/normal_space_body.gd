extends Node3D
class_name NormalSpaceBody

@onready var real_pos: DoubleVector = DoubleVector.new(position.x, position.y, position.z)

func _ready() -> void:
	self.add_to_group("space_bodies")
