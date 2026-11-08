extends Node3D
class_name Weapon

@export var target_range: float = 50.0
@export var pivot_range: float
@export var enable: bool = true

@onready var pivot: Node3D = $Pivot
var crosshairs: Array[Node3D]
@onready var csg_box_3d: CSGBox3D = $Pivot/CSGBox3D

var target := Vector3.FORWARD
var is_inline := false
var is_ontarget := false

var material: StandardMaterial3D
var target_ray: RayCast3D

func _ready() -> void:
	material = csg_box_3d.material.duplicate(true)
	csg_box_3d.material = material
	
	target_ray = RayCast3D.new()
	target_ray.collision_mask = 2
	target_ray.target_position = Vector3.FORWARD * target_range
	pivot.add_child(target_ray)
	
	for child in find_children("Crosshair*", "Node3D"):
		if child is Node3D:
			crosshairs.append(child)
	
	print(crosshairs)

func _physics_process(delta: float) -> void:
	if enable == false: return
	
	var a := target.normalized()
	
	var theta := a.angle_to(Vector3.UP)
	
	if theta > pivot_range:
		var perp_axis := Vector3.UP.cross(a)
		if perp_axis.length_squared() < 1e-5:
			perp_axis = Vector3.RIGHT
		a = Vector3.UP.rotated(perp_axis.normalized(), pivot_range)
	
	var dir := -pivot.basis.z
	var dist := dir.angle_to(a)
	if dist <= delta * 1:
		dir = a
	else:
		dir = dir.slerp(a, delta * 1 / dist)
	
	pivot.basis = Basis.looking_at(dir)
	
	#var dot := (a * Vector3.BACK).dot(Vector3.DOWN)
	#if dot < cos(pivot_range):
		#var up_q := Quaternion(Basis.looking_at(Vector3.UP, a * Vector3.UP))
		#a = a.slerp(up_q, absf(pivot_range / acos(dot) - 1.0))
		#is_ontarget = false
	#else:
		#is_ontarget = true
	
	#var dist := pivot.quaternion.angle_to(a)
	#if dist <= delta * 1:
		#pivot.quaternion = a
		#is_inline = true
	#else:
		#pivot.quaternion = pivot.quaternion.slerp(a, delta * 1 / dist)
		#is_inline = false
	
	if target.length() > target_range:
		is_ontarget = false
	
	#var x :=Basis(pivot.quaternion).z.snappedf(0.1)
	#var b = []
	#if absf(x.y - (-0.3)) < 1e-4:
		#b = ["ok"]
	#else:
		#b = ["ohnoes"]
	#b.append(([ pivot.quaternion.w, pivot.quaternion.x, pivot.quaternion.y, pivot.quaternion.z ]).map(func (x): return snappedf(x, 0.1)))
	#b.append(x)
	#print(b)
	
	target_ray.force_raycast_update()
	if target_ray.is_colliding():
		var pos := target_ray.get_collision_point()
		for i in crosshairs.size():
			crosshairs[i].global_position = target_ray.global_position.lerp(pos, float(1 + i) / float(crosshairs.size()))
		is_ontarget = true
	else:
		var pos := pivot.to_global(Vector3.FORWARD * target_range)
		for i in crosshairs.size():
			crosshairs[i].global_position = target_ray.global_position.lerp(pos, float(1 + i) / float(crosshairs.size()))
	
	if is_inline and is_ontarget:
		material.emission = Color.GREEN
	elif not is_inline and is_ontarget:
		material.emission = Color.WHITE
	else:
		material.emission = Color.RED
