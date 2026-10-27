extends Node

@export_file("*.tscn") var play_scene := ""

@onready var play_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/VBoxContainer/Play"
@onready var credits_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/VBoxContainer/Credits"
@onready var quit_button: Button = $"../UI/Screen/MarginContainer/Control/HBoxContainer/VBoxContainer/Quit"
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

func _process(delta: float) -> void:
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
				
				var scene: PackedScene = ResourceLoader.load_threaded_get(play_scene)
				get_tree().change_scene_to_node(scene.instantiate())

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
func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(link)
