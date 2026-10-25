extends Node3D
class_name Thruster

@export var magnitude := 0.0
@export var usage := 0.0
@export_range(0, 1) var throttle := 0.0
@onready var exhaust: Node3D = $"../Exhaust"
@onready var noise := FastNoiseLite.new()
@onready var gpu_particles_3d: GPUParticles3D = $"../GPUParticles3D"

func _process(delta: float) -> void:
	gpu_particles_3d.amount_ratio = throttle
	exhaust.scale = throttle * Vector3.ONE * (noise.get_noise_1d((Time.get_ticks_msec() + 314) / 50.0) / 50.0 + 1) * (1 + sin(Time.get_ticks_msec() / 20.0) / 120.0)
	
	exhaust.rotation.x = noise.get_noise_1d(Time.get_ticks_msec() / 30.0) / 50.0
	exhaust.rotation.y = noise.get_noise_1d((Time.get_ticks_msec() + 890) / 30.0) / 50.0
	exhaust.rotation.z = noise.get_noise_1d((Time.get_ticks_msec() + 872) / 30.0) / 50.0
