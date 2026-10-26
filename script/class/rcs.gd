extends Node3D
class_name RCS

@export var magnitude := 0.0
@export var usage := 0.0
@export var active := false
@export var throttle := 0.0

@onready var exhaust: Node3D = $"../Exhaust"
@onready var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	noise.seed = randi()

func _process(_delta: float) -> void:
	exhaust.visible = active
	exhaust.scale.x = 1 + noise.get_noise_1d(Time.get_ticks_msec() / 25.0) / 50
	exhaust.scale.y = 1 + noise.get_noise_1d((500 + Time.get_ticks_msec()) / 25.0) / 5
	exhaust.scale.z = 1 + noise.get_noise_1d((750 + Time.get_ticks_msec()) / 25.0) / 5
	
	exhaust.rotation.x = (noise.get_noise_1d((1350 + Time.get_ticks_msec()) / 25.0) - 0) / 50
	exhaust.rotation.y = (noise.get_noise_1d((1600 + Time.get_ticks_msec()) / 25.0) - 0) / 50
	exhaust.rotation.z = (noise.get_noise_1d((1900 + Time.get_ticks_msec()) / 25.0) - 0) / 50
