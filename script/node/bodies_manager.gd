extends Node
class_name BodiesManager

@export var threshold := 1000.0
@export var origin := [0.0, 0.0, 0.0]

@onready var camera: SpaceBody = $"../SpaceBody2"

func _physics_process(delta: float) -> void:
	var  x = camera.real_pos.map(func (x): return x * (1.0+delta) as float) as Array[float]
	print(x)
	print(typeof(x))
	camera.real_pos = camera.real_pos.map(func (x): return x * (1.0+delta) as float) as Array[float]
	print(camera.real_pos)
	camera.update_pos(origin)
	
	
	if camera.position.length() > threshold:
		var shift = camera.position
		
		origin[0] += shift.x
		origin[1] += shift.y
		origin[2] += shift.z
		
		for body: SpaceBody in get_tree().get_nodes_in_group("space_bodies"):
			body.position -= shift
