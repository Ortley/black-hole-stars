extends Node3D
class_name RCS

@export var magnitude := 0.0
@export var usage := 0.0
@export var active := false
@export var throttle := 0.0

@onready var exhaust: CSGCylinder3D = $"../Exhaust"

func _process(delta: float) -> void:
	if throttle > 0.0:
		print(throttle)
		exhaust.visible = true
	else:
		exhaust.visible = false#active
