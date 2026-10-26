extends Node

@onready var normal: Node3D = $"../World/Normal"
@onready var scaled: Node3D = $"../World/Scaled"

@onready var scaled_cam: Camera3D = $"../Scaled/SVC/SubViewport/Camera"
@onready var normal_cam: Camera3D = $"../Normal/SVC/SubViewport/Camera"

@onready var smartmobile: NormalSpaceBody = $"../World/Normal/Smartmobile"

var normal_cam_pos := DoubleVector.new(0, 0, 0)
var cam_basis := Basis.IDENTITY
var mouse_sens := 0.005
var roting := false
var zoom := 12.0
var mouse_input := Vector2.ZERO

var origin := DoubleVector.new(0, 0, 0)
var threshold := 2000
@onready var threshold_squared := threshold * threshold
var scale := 10000.0

func _ready() -> void:
	normal.visible = true
	scaled.visible = true
	shift()

func shift() -> void:
	origin.x = normal_cam_pos.x
	origin.y = normal_cam_pos.y
	origin.z = normal_cam_pos.z
	
	print("shiftin time!")
	
	for body in get_tree().get_nodes_in_group("space_bodies"):
		if body is NormalSpaceBody:
			body.position.x = body.real_pos.x - origin.x
			body.position.y = body.real_pos.y - origin.y
			body.position.z = body.real_pos.z - origin.z
			
			body.prev = body.position


func _physics_process(delta: float) -> void:
	var a = smartmobile.real_pos.vec3() + zoom * cam_basis.z
	normal_cam_pos.x = a.x
	normal_cam_pos.y = a.y
	normal_cam_pos.z = a.z
	var diff := normal_cam_pos.sub(origin)
	if diff.length_squared() > threshold_squared:
		shift()
	
	var new = Vector3(normal_cam_pos.x - origin.x, normal_cam_pos.y - origin.y, normal_cam_pos.z - origin.z)
	normal_cam.position = new
	normal_cam.basis = cam_basis
	
	new = Vector3(normal_cam_pos.x / scale, normal_cam_pos.y / scale, normal_cam_pos.z / scale)
	scaled_cam.position = new
	scaled_cam.basis = cam_basis

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
		
