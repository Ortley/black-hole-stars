extends Node3D
class_name Weapon

@export var target_range: float = 50.0
@export var pivot_range: float
@export var enable: bool = true
@export var crosshair_count := 4

var has_target: bool = false
const CROSSHAIR = preload("uid://xuqkhgjunl7m")

@onready var pivot: Node3D = $Pivot
@onready var barrel_end: Node3D = $Pivot/BarrelEnd
var crosshairs: Array[Node3D]
@onready var csg_box_3d: CSGBox3D = $Pivot/CSGBox3D

var target := Vector3.FORWARD
var is_inline := false
var is_ontarget := false

var material: StandardMaterial3D
var target_ray: RayCast3D

var fire_timeout := 0.0
var fire_timing := 60.0 / 300.0 # (300 rpm)

func _ready() -> void:
	material = csg_box_3d.material.duplicate(true)
	csg_box_3d.material = material
	
	target_ray = RayCast3D.new()
	target_ray.collision_mask = 2
	target_ray.target_position = Vector3.FORWARD * target_range
	pivot.add_child(target_ray)
	
	for n in crosshair_count:
		var new := CROSSHAIR.instantiate()
		crosshairs.append(new)
		add_child(new)
		new.owner = self

func _physics_process(delta: float) -> void:
	if fire_timeout >= 0:
		fire_timeout -= delta
	
	if enable == false or has_target == false:
		material.emission = Color.WHITE
		
		for crosshair in crosshairs:
			crosshair.scale = crosshair.scale.move_toward(Vector3.ZERO, 2 * delta)
		
		return
	
	for crosshair in crosshairs:
		crosshair.scale = crosshair.scale.move_toward(Vector3.ONE / 3.0, 2 * delta)

	
	var a := target.normalized()
	
	var theta := a.angle_to(Vector3.UP)
	
	if theta > pivot_range:
		var perp_axis := Vector3.UP.cross(a)
		if perp_axis.length_squared() < 1e-5:
			perp_axis = Vector3.RIGHT
		a = Vector3.UP.rotated(perp_axis.normalized(), pivot_range)
		is_ontarget = false
	
	var dir := -pivot.basis.z
	var dist := dir.angle_to(a)
	if dist <= delta * 1:
		dir = a
		is_inline = true
	else:
		dir = dir.slerp(a, delta * 1 / dist)
		is_inline = false
	
	pivot.basis = Basis.looking_at(dir)
	
	
	if target.length() > target_range:
		is_ontarget = false
	
	
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

#func fire() -> void:
	#target_ray.force_raycast_update()
	#Projectiles.create()
	#
	#if target_ray.is_colliding():
		#print(target_ray.get_collider())
		#target_ray.get_collider().hit.emit()
	##pass
