extends Control
class_name FlightPanel

var is_resizing := false
var is_dragging := false
var mouse_offset := Vector2.ZERO
var kept_size := Vector2.ZERO
var active_handle := -1

var dragger: Button
var handles: Array

var start: Vector2 = Vector2.INF

@export var handle_size := 8.0
@export var min_width := 45
@export var min_height := 45

static var STYLEBOX_EMPTY := StyleBoxEmpty.new()
static var STYLEBOX_HANDLE_PRESSED := preload("res://res/theme/panel/handle_pressed.tres")
static var STYLEBOX_HANDLE_HOVER := preload("res://res/theme/panel/handle_hover.tres")
static var STYLEBOX_PANEL := preload("res://res/theme/panel/panel.tres")

var exception: Control

func _ready() -> void:
	var panel := PanelContainer.new()
	
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	panel.owner = self
	panel.add_theme_stylebox_override("panel", STYLEBOX_PANEL)
	#panel.z_index = -1
	
	for child in get_children():
		if child == panel: continue
		child.reparent(panel)
	
	dragger = Button.new()
	add_child(dragger)
	dragger.owner = self
	
	dragger.set_anchors_preset(Control.PRESET_TOP_WIDE)
	dragger.offset_bottom = handle_size
	dragger.offset_right = -handle_size
	dragger.offset_left = -dragger.offset_right
	dragger.offset_top = -dragger.offset_bottom
	
	dragger.button_down.connect(dragger_button_down)
	dragger.button_up.connect(dragger_button_up)
	
	dragger.add_theme_stylebox_override("normal", STYLEBOX_EMPTY)
	dragger.add_theme_stylebox_override("hover", STYLEBOX_HANDLE_HOVER)
	dragger.add_theme_stylebox_override("pressed", STYLEBOX_HANDLE_PRESSED)
	#dragger.z_index = -1
	
	handles.resize(4)
	for i in 4:
		var handle: Button = Button.new()
		handles[i] = handle
		add_child(handle)
		handle.owner = self
		
		handle.set_anchors_preset(i)
		handle.offset_bottom = handle_size
		handle.offset_right = handle_size
		handle.offset_left = -handle.offset_right
		handle.offset_top = -handle.offset_bottom
		
		handle.button_down.connect(handle_button_down.bind(i, handle))
		handle.button_up.connect(handle_button_up.bind(handle))
		
		handle.add_theme_stylebox_override("normal", STYLEBOX_EMPTY)
		handle.add_theme_stylebox_override("hover", STYLEBOX_HANDLE_HOVER)
		handle.add_theme_stylebox_override("pressed", STYLEBOX_HANDLE_PRESSED)
		#handle.z_index = -1
	
	SignalBus.hide_all_panel_controls.connect(func ():
		if dragger != exception:
			dragger.visible = false
		for handle in handles:
			if handle != exception:
				handle.visible = false
		)
	SignalBus.show_all_panel_controls.connect(func ():
		dragger.visible = true
		for handle in handles:
			handle.visible = true)

func dragger_button_down() -> void:
	is_dragging = true
	mouse_offset = (get_viewport().get_mouse_position() - dragger.get_screen_position()) - dragger.size / 2.0
	kept_size = size
	start = get_viewport().get_mouse_position()
	
	exception = dragger
	SignalBus.hide_all_panel_controls.emit()

func dragger_button_up() -> void:
	is_dragging = false
	if exception == dragger:
		exception = null
		SignalBus.show_all_panel_controls.emit()
	
	if get_viewport().get_mouse_position().distance_squared_to(start) < 1e-5:
		collapse()
		start = Vector2.INF


func handle_button_down(i: int, handle: Button) -> void:
	is_resizing = true
	active_handle = i
	mouse_offset = (get_viewport().get_mouse_position() - handle.get_screen_position()) - handle.size / 2.0
	exception = handle
	SignalBus.hide_all_panel_controls.emit()

func handle_button_up(handle: Button) -> void:
	is_resizing = false
	active_handle = -1
	if exception == handle:
		exception = null
		SignalBus.show_all_panel_controls.emit()

func _process(_delta: float) -> void:
	if is_resizing == true:
		var new := get_viewport().get_mouse_position() - mouse_offset
		new /= get_viewport_rect().size
		
		# FIXME: viewport size couldve changed since last frame, so recalc every frame to fix 
		# (seems bad)
		var min_width_anchor := min_width / get_viewport_rect().size.x
		var min_height_anchor := min_height / get_viewport_rect().size.y
		
		match active_handle:
			Control.PRESET_TOP_LEFT:
				anchor_left = minf(new.x, anchor_right - min_width_anchor)
				anchor_top = minf(new.y, anchor_bottom - min_height_anchor)
			Control.PRESET_TOP_RIGHT:
				anchor_right = maxf(new.x, anchor_left + min_width_anchor)
				anchor_top = minf(new.y, anchor_bottom - min_height_anchor)
			Control.PRESET_BOTTOM_LEFT:
				anchor_left = minf(new.x, anchor_right - min_width_anchor)
				anchor_bottom = maxf(new.y, anchor_top + min_height_anchor)
			Control.PRESET_BOTTOM_RIGHT:
				anchor_right = maxf(new.x, anchor_left + min_width_anchor)
				anchor_bottom = maxf(new.y, anchor_top + min_height_anchor)
	
	if is_dragging == true:
		var new := get_viewport().get_mouse_position() - mouse_offset
		
		anchor_left = (new.x - kept_size.x / 2) / get_viewport_rect().size.x
		anchor_right = (new.x + kept_size.x / 2) / get_viewport_rect().size.x
		anchor_top = (new.y) / get_viewport_rect().size.y
		anchor_bottom = (new.y + kept_size.y) / get_viewport_rect().size.y

func collapse() -> void:
	for child in find_children("*", "Control", true, false):
		child.visible = !child.visible
	
	dragger.visible = true
