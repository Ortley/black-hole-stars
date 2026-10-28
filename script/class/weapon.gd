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
	
	
	var a := Quaternion(Basis.looking_at(target, pivot.basis.y))
	
	var dot := (a * Vector3.BACK).dot(Vector3.DOWN)
	if dot < cos(range):
		var up_q := Quaternion(Basis.looking_at(Vector3.UP, a * Vector3.UP))
		a = a.slerp(up_q, absf(range / acos(dot) - 1.0))
		is_ontarget = false
	else:
		is_ontarget = true
	
	var dist := pivot.quaternion.angle_to(a)
	if dist <= delta * 1:
		pivot.quaternion = a
		is_inline = true
	else:
		pivot.quaternion = pivot.quaternion.slerp(a, delta * 1 / dist)
		is_inline = false
	
	if is_inline and is_ontarget:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.GREEN
	elif not is_inline and is_ontarget:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.WHITE
	else:
		(csg_box_3d.material as StandardMaterial3D).emission = Color.RED
