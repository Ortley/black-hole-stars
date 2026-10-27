extends Node3D
class_name Weapon

@export var range: float

@onready var pivot: Node3D = $Pivot

var target := Vector3.FORWARD

func _ready() -> void:
	pivot.basis.y = Vector3.LEFT

func _process(delta: float) -> void:
	var a = Basis.looking_at(target, pivot.basis.y)
	if a.z.dot(Vector3.DOWN) < cos(range):
		a = a.slerp(Basis.looking_at(Vector3.UP, a.y), absf(range / acos(a.z.dot(Vector3.DOWN)) - 1))
	
	pivot.basis = a
