# Splash.gd
extends Control

@onready var screens := [
	$CenterContainer/Sprite2D, 
	$CenterContainer2/Sprite2D,     
	$CenterContainer3/Credits,
	$CenterContainer4/Credits      
]

var i := 0

func _ready() -> void:
	for s in screens: s.modulate.a = 0.0
	_run_sequence()

func _run_sequence() -> void:
	if i >= screens.size():
		TransitionManager.change_scene_to_file_with_fade("res://menus/MainMenu.tscn")
		return
	for s in screens: s.visible = false
	var n : Node = screens[i]
	n.visible = true
	await _fade_in_out(n)
	i += 1
	_run_sequence()

func _fade_in_out(node: CanvasItem) -> Signal:
	var t := create_tween()
	node.modulate.a = 0.0
	t.tween_property(node, "modulate:a", 1.0, 0.5)
	t.tween_interval(0.9)
	t.tween_property(node, "modulate:a", 0.0, 0.5)
	return t.finished

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		TransitionManager.change_scene_to_file_with_fade("res://menus/MainMenu.tscn")
