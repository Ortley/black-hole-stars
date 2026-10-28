extends Node3D
class_name Weapon

@export var range: float
@export var enable: bool = true

@onready var pivot: Node3D = $Pivot
@onready var csg_box_3d: CSGBox3D = $Pivot/CSGBox3D

var target := Vector3.FORWARD
var is_inline := false
var is_ontarget :=false

func _ready() -> void:
	#pivot.basis.y = Vector3.LEFT
	
	csg_box_3d.material = csg_box_3d.material.duplicate(true)

func _process(delta: float) -> void:
	if enable == false: return

	var a := Basis.looking_at(target, pivot.basis.y)
	if a.z.dot(Vector3.DOWN) < cos(range):
		a = a.slerp(Basis.looking_at(Vector3.UP, a.y), absf(range / acos(a.z.dot(Vector3.DOWN)) - 1))
		is_ontarget = false
	else:
		is_ontarget = true
	
	var dist := acos(pivot.basis.z.dot(a.z))
	if dist <= delta * 0.1:
		pivot.basis = a
		is_inline = true
	else:
		pivot.basis = pivot.basis.slerp(a, delta * 0.1 / dist)
		is_inline = false
	
	if is_inline and is_ontarget:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.GREEN
	elif not is_inline and is_ontarget:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.WHITE
	else:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.RED
