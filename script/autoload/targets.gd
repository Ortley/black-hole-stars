extends Node

const TARGET_OVERLAY = preload("uid://ckx0k8s8jfuhl")
const TARGETTED_OVERLAY = preload("uid://1ul7klci3fpu")
const ONTARGET_OVERLAY = preload("uid://cgfk2ouwi3w0y")

var list: Array[DoubleVector] = []
var mask: Array[bool] = []
#var targetted: PackedInt64Array
var lane: PackedInt64Array = []
var ontarget: Array[bool] = []

var free_count: int = 0
var lowest_free: int = 0
var highest_free: int = 0

var targets_mm: MultiMeshInstance3D
var targetted_mm: MultiMeshInstance3D
var ontarget_mm: MultiMeshInstance3D

func _ready() -> void:
	var setup := func () -> MultiMeshInstance3D:
		var mm = MultiMeshInstance3D.new()
		add_child(mm)
		mm.owner = self
		mm.layers = 8
		mm.multimesh = MultiMesh.new()
		mm.multimesh.mesh = QuadMesh.new()
		mm.multimesh.mesh.size = Vector2(0.05, 0.05)
		mm.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		
		return mm
	
	targets_mm = setup.call()
	targets_mm.material_override = TARGET_OVERLAY
	targetted_mm = setup.call()
	targetted_mm.material_override = TARGETTED_OVERLAY
	ontarget_mm = setup.call()
	ontarget_mm.material_override = ONTARGET_OVERLAY

func _physics_process(delta: float) -> void:
	print(ontarget)
	var offset := 0
	var ontarget_count := 0
	var targetted_count := 0
	var untargetted_count := 0
	for i in list.size():
		if mask[i] == false:
			continue
		if ontarget[i] == true:
			ontarget_mm.multimesh.set_instance_transform(i - offset, Transform3D(Basis.IDENTITY, list[i].to_vec3()))
			offset += 1
			ontarget_count += 1
		elif lane[i] == 0:
			targets_mm.multimesh.set_instance_transform(i - offset, Transform3D(Basis.IDENTITY, list[i].to_vec3()))
			untargetted_count += 1
		elif lane[i] >= 1:
			targetted_mm.multimesh.set_instance_transform(i - offset, Transform3D(Basis.IDENTITY, list[i].to_vec3()))
			offset += 1
			targetted_count += 1
	
	ontarget_mm.multimesh.visible_instance_count = ontarget_count
	targets_mm.multimesh.visible_instance_count = untargetted_count
	targetted_mm.multimesh.visible_instance_count = targetted_count
	

func target_target(t: int) -> DoubleVector:
	lane[t] += 1
	#targetted.insert(targetted.bsearch(t), t)
	#targetted_mm.multimesh.instance_count = targetted.size()
	
	return list[t]

func untarget_target(t: int) -> void:
	lane[t] -= 1
	#targetted.erase(targetted.find(t))
	#targetted_mm.multimesh.instance_count = targetted.size()

func add_target(t: Target) -> int:
	var idx := -1
	if free_count == 0:
		list.append(t.real_pos)
		mask.append(true)
		lane.append(0)
		ontarget.append(false)
		targets_mm.multimesh.instance_count = list.size()
		targetted_mm.multimesh.instance_count = list.size()
		ontarget_mm.multimesh.instance_count = list.size()
		idx = list.size() - 1
	else:
		idx = mask.find(false, lowest_free)
		list[idx] = t.real_pos
		mask[idx] = true
		lane[idx] = 0
		ontarget[idx] = false
		
		free_count -= 1
		lowest_free = idx
		highest_free = max(lowest_free, highest_free)
	
	return idx

func is_target_live(i: int) -> bool:
	return mask[i]

func free_target(i: int) -> void:
	mask[i] = false
	
	lowest_free = min(lowest_free, i)
	highest_free = max(highest_free, i)
	free_count += 1
