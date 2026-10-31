extends Node3D
class_name RCS

@export var magnitude := 0.0
@export var usage := 0.0
@export var enabled := true
@export var throttle := 0.0

@onready var exhaust: Node3D = $"Exhaust"
@onready var gas_2: CSGCylinder3D = $Exhaust/Gas2
@onready var noise: FastNoiseLite = FastNoiseLite.new()

@onready var local_transform: DoubleTransform

var active := false
var seed := randi()

func _ready() -> void:
	var parent: Node = get_parent()
	while parent != null and parent is not NormalSpaceBody:
		parent = parent.get_parent()
	if parent is NormalSpaceBody:
		local_transform = DoubleTransform.new()
		local_transform.origin = DoubleVector.from_vec3(parent.to_local(global_position))
		local_transform.basis = DoubleBasis.from_basis(parent.global_basis.inverse() * global_basis)
	
	noise.seed = randi()

func _process(_delta: float) -> void:
	#if !exhaust: return
	exhaust.visible = active
	if enabled == false: return
	exhaust.scale.x = 1 + noise.get_noise_1d(Time.get_ticks_msec() / 25.0) / 50
	exhaust.scale.y = 1 + noise.get_noise_1d((500 + Time.get_ticks_msec()) / 25.0) / 5
	exhaust.scale.z = 1 + noise.get_noise_1d((750 + Time.get_ticks_msec()) / 25.0) / 5 + 0.025 * sin(seed + Time.get_ticks_msec() / 100.0)
	
	gas_2.scale = Vector3.ONE * (1 + noise.get_noise_1d((879 + Time.get_ticks_msec()) / 25.0) / 5)
	
	exhaust.rotation.x = (noise.get_noise_1d((1350 + Time.get_ticks_msec()) / 25.0) - 0) / 50
	exhaust.rotation.y = (noise.get_noise_1d((1600 + Time.get_ticks_msec()) / 25.0) - 0) / 50
	exhaust.rotation.z = (noise.get_noise_1d((1900 + Time.get_ticks_msec()) / 25.0) - 0) / 50
