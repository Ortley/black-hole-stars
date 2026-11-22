extends MultiMeshInstance3D

const BULLET_20_MM: CylinderMesh = preload("uid://sly621eai8je")

var count: int
var positions: PackedVector3Array
var bases: Array[Basis] # plural of Basis
var velocities: PackedVector3Array
var masses: PackedFloat64Array
var scales: PackedFloat64Array

func _ready() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BULLET_20_MM
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = 2
	
	
	#while true:
		#var prev := count
		#await get_tree().create_timer(1.0).timeout
		#print("new %s" % (count - prev))

func create(at: DoubleVector, global_basis: Basis, velocity: Vector3, mass: float, scale: float):
	count += 1
	positions.append(at.to_vec3())
	bases.append(global_basis.rotated(Vector3.RIGHT, PI/2))
	velocities.append(velocity)
	masses.append(mass)
	scales.append(scale)
	#multimesh.set_instance_transform(count - 1, Transform3D(global_basis, at.to_vec3()))
	#
	#
	#new.global_transform = Transform3D(global_basis, at.to_vec3())
	#new.linear_velocity = velocity
	#
	#root.add_child(new)
	#new.owner = root

const E := 1.0
func move_and_bounce(i: int, delta: float, space: PhysicsDirectSpaceState3D) -> void:
	multimesh.set_instance_transform(i, Transform3D(bases[i] * scales[i], positions[i]))
	
	# FIXME: using vector3 not doublevector
	var start := positions[i]
	var end := positions[i] + velocities[i] * delta
	var query := PhysicsRayQueryParameters3D.create(start, end)
	
	var hit := space.intersect_ray(query)
	if not hit:
		positions[i] = end
		return
	# else hit...
	
	var normal := hit.normal as Vector3
	var collider := hit.collider as CollisionObject3D
	
	var distance := positions[i].distance_to(hit.position)
	
	var va := velocities[i]
	var ma := masses[i]
	var vb: Vector3 = collider.linear_velocity if collider is RigidBody3D else Vector3.ZERO
	var mb: float = collider.mass if collider is RigidBody3D else 0.0
	
	#1D vel along normal
	var v := (va - vb).dot(normal)
	if v < 0.0:
		# u = -e * v = v + J * (1.0/ma + 1.0/mb)
		# J = (u - v) / ( 1.0/ma + 1.0/mb )
		# J = ( -e * v - v) / 
		# -ev - v
		# ( e + 1 ) * -v
		# J = ( -1-e) * v / 
		var J := -( 1.0 + E ) * v / ( 1.0 / ma + 1.0 / mb)
		
		var ua := velocities[i] + normal * ( J / ma )
		velocities[i] = ua
		positions[i] = hit.position + absf(va.length() * delta - distance) * ua.normalized()
		var b = Basis(Quaternion(Vector3.UP, ua.normalized()))
		bases[i] = b
		
		#multimesh.set_instance_transform(i, Transform3D(Basis(Quaternion(Vector3.UP, ua.normalized())), positions[i]))
		
		if collider is RigidBody3D:
			collider.apply_impulse(-hit.normal * J, hit.position - collider.global_position)
	
	
	#var v1 := velocities[i]
	#var v1_mag := v1.length()
	#velocities[i] = velocities[i].bounce(hit.normal).normalized() * v1_mag
	#positions[i] = hit.position + absf(v1_mag * delta - distance) * velocities[i].normalized()
	#bases[i] = reflect_basis(bases[i], hit.normal)
	
	
	
	#if hit.collider is RigidBody3D:
	#	pass
	#PhysicsServer3D.body_apply_impulse(hit.rid, -hit.normal, hit.position - PhysicsServer3D.body_get_state(hit.rid, PhysicsServer3D.BODY_STATE_TRANSFORM).origin)
	
	#print(hit.position)
	#print(sign(distance - speed * delta))


func _physics_process(delta: float) -> void:
	# NOTE: frame time goes throught the floor when using profiler!!!
	
	if multimesh.instance_count != count:
		multimesh.instance_count = count
	
	var space := get_world_3d().direct_space_state
	for i in count:
		move_and_bounce(i, delta, space)


func reflect_basis(b: Basis, n: Vector3) -> Basis:
	return Basis(
		b.x.bounce(n),
		b.y.bounce(n),
		b.z.bounce(n)
	)
#func _process(delta: float) -> void:
#	
#	multimesh.instance_count = count
#	for i in count:
#		multimesh.set_instance_transform(i, Transform3D(bases[i], positions[i]))
