extends Node

@export_file("*.tscn") var play_scene := ""

@onready var buttons: VBoxContainer = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Buttons"

@onready var play_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Buttons/Play"
@onready var credits_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Buttons/Credits"
@onready var quit_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Buttons/Quit"
@onready var no_quit_button: Button = $"../UI/Screen/Quit/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/No"
@onready var yes_quit_button: Button = $"../UI/Screen/Quit/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/Yes"
@onready var credits_cont: PanelContainer = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Credits"
@onready var quit_cont: PanelContainer = $"../UI/Screen/Quit"

@onready var spin: AnimationPlayer = $"../Spin"
@onready var fade_in: AnimationPlayer = $"../FadeIn"
@onready var fade_to_black: AnimationPlayer = $"../FadeToBlack"
@onready var status: Label = $"../Loading/MarginContainer/Anchor/Status"

@onready var credits: RichTextLabel = $"../UI/Screen/MarginContainer/Control/HBoxContainer/Credits/MarginContainer/RichTextLabel"

var is_loading := false
var loading_start: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("web"):
		# quit is useless in web
		quit_button.visible = false
	
	credits.text = credits.text % [ OS.get_name(), ProjectSettings.get_setting("application/config/version") ]
	
	play_button.button_up.connect(func ():
		ResourceLoader.load_threaded_request(play_scene)
		start_load_anim()
		)
	credits_button.button_up.connect(toggle.bind(credits_cont))
	quit_button.button_up.connect(toggle.bind(quit_cont))
	no_quit_button.button_up.connect(toggle.bind(quit_cont))
	yes_quit_button.button_up.connect(get_tree().quit)

func _process(_delta: float) -> void:
	if is_loading == true:
		var code := ResourceLoader.load_threaded_get_status(play_scene)
		match code:
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				stop_load_anim()
				status.text = "!! Invalid resource to load"
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				status.text = "Loading%s" % ".".repeat(1 + ((Time.get_ticks_msec() - loading_start + 250) / 500) % 3)
			ResourceLoader.THREAD_LOAD_FAILED:
				stop_load_anim()
				status.text = "!! Failed to load play_scene"
			ResourceLoader.THREAD_LOAD_LOADED:
				stop_load_anim()
				status.text = "Loaded!"
				#await get_tree().create_timer(1.0).timeout
				var scene: PackedScene = ResourceLoader.load_threaded_get(play_scene)
				get_tree().change_scene_to_node(scene.instantiate())
				#threaded_change_scene_to_packed(scene)
	else:
		var p := ((get_viewport().get_mouse_position() - buttons.global_position) / buttons.get_rect().size)
		var channels := [play_button.position.x, credits_button.position.x, quit_button.position.x]
		var future := [0.0, 0.0, 0.0]
		
		future[0] = 1.0 / 3.0 - absf(p.y - 1.0 / 6.0) * 3.0 / 2.0
		future[1] = 1.0 / 3.0 - absf(p.y - 3.0 / 6.0) * 3.0 / 2.0
		future[2] = 1.0 / 3.0 - absf(p.y - 5.0 / 6.0) * 3.0 / 2.0
		
		future = (future.map(func (x): return clampf(3.0 * x, 0.0, 1.0))
			.map(func (x): return x * clampf(4 - 6 * absf(p.x - 0.5), 0.0, 1.0))
			.map(func (x): return x * 10))
		
		
		channels = future
		#for i in 3:
		#	channels[i] = 5 * clampf(3.0 * future[i], 0.0, 1.0)
		
		play_button.position.x = channels[0]
		credits_button.position.x = channels[1]
		quit_button.position.x = channels[2]

func threaded_change_scene_to_packed(scene: PackedScene) -> void:
	var thread := Thread.new()
	thread.start(func ():
		var node := scene.instantiate()
		switch_tree.call_deferred(node, thread)
		)

func switch_tree(new: Node, thread: Thread) -> void:
	thread.wait_to_finish()
	
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(new)
	get_tree().current_scene = new
	

func start_load_anim() -> void:
	fade_in.play("start")
	spin.play("loading")
	fade_to_black.play("fade")
	is_loading = true
	loading_start = Time.get_ticks_msec()


func stop_load_anim() -> void:
	fade_in.play("start", -1, -1.0, true)
	spin.play("RESET")
	is_loading = false

func toggle(box: Control) -> void:
	var old := box.visible
	hide_all()
	box.visible = !old

func hide_all() -> void:
	credits_cont.visible = false
	quit_cont.visible = false

@export var link := "https://github.com/Ortley/black-hole-stars"
func _on_rich_text_label_meta_clicked(_meta: Variant) -> void:
	OS.shell_open(link)
