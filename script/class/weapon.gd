extends Node3D
class_name Weapon

@export var target_range: float = 50.0
@export var pivot_range: float
@export var enable: bool = true
@export var crosshair_count := 0
@export var rpm := 60.0
@export var projectile_scale := 1.0
@export var projectile_mass := 0.1

var has_target: bool = false
const CROSSHAIR = preload("uid://xuqkhgjunl7m")

@onready var pivot: Node3D = $Pivot
@onready var barrel_end: Node3D = $Pivot/BarrelEnd
var crosshairs: Array[Node3D]
@onready var csg_box_3d: GeometryInstance3D = $Pivot/CSGBox3D

var target := Vector3.FORWARD
const MAX_PAST := 6
var past_targets: PackedVector3Array
var is_inline := false
var is_ontarget := false
const TURRET_GLOW = preload("uid://3pf6suua74bp")

var material: StandardMaterial3D
var target_ray: RayCast3D

func _ready() -> void:
	material = TURRET_GLOW.duplicate(true)
	csg_box_3d.material_override = material
	
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
	if enable == false or has_target == false:
		material.emission = Color.WHITE
		
		for crosshair in crosshairs:
			crosshair.scale = crosshair.scale.move_toward(Vector3.ZERO, 2 * delta)
		
		return
	
	for crosshair in crosshairs:
		crosshair.scale = crosshair.scale.move_toward(Vector3.ONE / 3.0, 2 * delta)
	
	#var s := past_targets
	#var vel := range(s.size() - 1).map(func (i): return s[i + 1] - s[i])
	#var acc := range(vel.size() - 1).map(func (i): return vel[i + 1] - vel[i])
	#
	#var mean_v: Vector3
	#var mean_a: Vector3
	#for i in s.size():
		#if i < s.size() - 1:
			#mean_v += vel[i]
		#if i < s.size() - 2:
			#mean_a += acc[i]
	#mean_v /= vel.size() - 1
	#mean_a /= vel.size() - 2
	#
	#var dev_vel := vel.map(func (x): return x - mean_v).map(func (v): return v * v)
	#var dev_acc := vel.map(func (x): return x - mean_a).map(func (v): return v * v)
	#
	#
	#mean_v = Vector3.ZERO
	#mean_a = Vector3.ZERO
	#for i in s.size():
		#if i < s.size() - 1:
			#mean_v += dev_vel[i]
		#if i < s.size() - 2:
			#mean_a += dev_acc[i]
	#mean_v /= s.size() - 1
	#mean_a /= s.size() - 2
	#
	#print("%s / %s" % [mean_v.snappedf(0.01), mean_a.snappedf(0.01)])
	#
	var dv := target - past_targets[0] if past_targets else Vector3.ZERO
	
	var a := (target + dv).normalized()
	
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
	
	if past_targets.size() == MAX_PAST:
		for i in past_targets.size() - 1:
			past_targets[i] = past_targets[i + 1]
		past_targets[-1] = target
	else:
		past_targets.append(target)

var barrelvisbuf := false
#func fire() -> void:
	#target_ray.force_raycast_update()
	#Projectiles.create()
	#
	#if target_ray.is_colliding():
		#print(target_ray.get_collider())
		#target_ray.get_collider().hit.emit()
	##pass
