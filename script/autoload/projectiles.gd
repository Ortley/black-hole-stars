extends Node

const BLOB = preload("uid://cge4khaa6adxp")

var root: Node3D

func create(at: DoubleVector, global_basis: Basis, velocity: Vector3):
	var new: NormalSpaceBody = BLOB.instantiate()
	#print(new.get_method_list())
	#print(new.get_property_list())
	#new.real_trans.origin = at
	#new.real_trans.basis = DoubleBasis.from_basis(global_basis)
	
	new.global_transform = Transform3D(global_basis, at.to_vec3())
	new.linear_velocity = velocity
	
	root.add_child(new)
	new.owner = root
