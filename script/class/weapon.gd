extends Node3D
class_name Weapon

@export var range: float

@onready var pivot: Node3D = $Pivot
@onready var csg_box_3d: CSGBox3D = $Pivot/CSGBox3D

var target := Vector3.FORWARD

func _ready() -> void:
	pivot.basis.y = Vector3.LEFT
	
	csg_box_3d.material = csg_box_3d.material.duplicate(true)

func _process(delta: float) -> void:
	var a = Basis.looking_at(target, pivot.basis.y)
	if a.z.dot(Vector3.DOWN) < cos(range):
		(csg_box_3d.material as StandardMaterial3D).emission = Color.RED
		a = a.slerp(Basis.looking_at(Vector3.UP, a.y), absf(range / acos(a.z.dot(Vector3.DOWN)) - 1))
	else:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.WHITE

	pivot.basis = a
