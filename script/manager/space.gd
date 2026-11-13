extends Node

@onready var normal: Node3D = $"../World/Normal"
@onready var scaled: Node3D = $"../World/Scaled"

@onready var scaled_cam: Camera3D = $"../Scaled/SVC/SubViewport/Camera"
@onready var normal_cam: Camera3D = $"../Normal/SVC/SubViewport/Camera"
@onready var overlays_cam: Camera3D = $"../Overlays/SVC/SubViewport/Camera"
#@onready var navball_cam = $"../UI/Navball panel/SVC/SV/Global"

@export var target: NormalSpaceBody

enum CameraMode {
	RELATIVE, # target up = camera up
	WORLD, # World up = camera up
}

var normal_cam_root := DoubleVector.new(0, 0, 0)
var normal_cam_pos := DoubleVector.new(-2.869, 4.592, 10.709)
var camera_mode: CameraMode = CameraMode.RELATIVE
var cam_basis := Basis.IDENTITY.rotated(Vector3.RIGHT, -PI/8)#.rotated(Vector3.UP, -PI/12)
var mouse_sens := 0.005
var roting := false
var zoom := 12.0
var mouse_input := Vector2.ZERO

var origin := DoubleVector.new(0, 0, 0)
var threshold := 2000.0
@onready var threshold_squared := threshold * threshold
var scale := 1_000_000.0

func _ready() -> void:
	normal.visible = true
	scaled.visible = true
	shift()

func shift() -> void:
	origin.x = normal_cam_root.x
	origin.y = normal_cam_root.y
	origin.z = normal_cam_root.z
	
	print("shiftin time!")
	
	for body in get_tree().get_nodes_in_group("space_bodies"):
		if body is NormalSpaceBody:
			#body.origin = origin
			body.global_position = body.real_trans.origin.sub(origin).to_vec3()
			body.prev = body.global_position


func _physics_process(_delta: float) -> void:
	var a = target.real_trans.origin.to_vec3()# + zoom * cam_basis.z
	normal_cam_root.x = a.x
	normal_cam_root.y = a.y
	normal_cam_root.z = a.z
	var diff := normal_cam_root.sub(origin)
	if diff.length_squared() > threshold_squared:
		shift()
		
	var prod: Basis
	match camera_mode:
		CameraMode.WORLD:
			prod = Basis.IDENTITY * cam_basis
		CameraMode.RELATIVE:
			prod = target.global_basis * cam_basis
		_:
			assert(false, "!!! Unimplemented CameraMode")
	
	var new = Vector3(
		normal_cam_root.x + zoom * prod.z.x - origin.x, 
		normal_cam_root.y + zoom * prod.z.y - origin.y, 
		normal_cam_root.z + zoom * prod.z.z - origin.z)
	normal_cam.position = new
	normal_cam.basis = prod
	
	overlays_cam.transform = normal_cam.transform
	
	new += Vector3(origin.x, origin.y, origin.z)
	new /= scale#Vector3(normal_cam_root.x / scale, normal_cam_root.y / scale, normal_cam_root.z / scale)
	scaled_cam.position = new
	scaled_cam.basis = prod
	
	Globals.ship_orientation = target.global_basis
	
	#navball_cam.basis.x = -target.global_basis.x
	#navball_cam.basis.y = -target.global_basis.y
	#navball_cam.basis.z = target.global_basis.z
	
	if target.linear_velocity.is_zero_approx() == false:
		%abc.basis = Basis.looking_at(target.linear_velocity)

	#navball_cam.position = target.global_basis.z * 1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			roting = event.pressed
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			zoom *= 1.15
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			zoom /= 1.15
	elif roting == true and event is InputEventMouseMotion:
		mouse_input = event.relative
		cam_basis = Basis(Vector3.UP, -event.relative.x * mouse_sens) * cam_basis
		cam_basis = cam_basis * Basis(Vector3.RIGHT, -event.relative.y * mouse_sens)
		cam_basis = cam_basis.orthonormalized()
