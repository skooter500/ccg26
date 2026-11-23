@tool
class_name CsgBlockoutTool
extends RefCounted
## Base class for viewport tools.
## Modal tools are activated through CsgBlockoutToolManager.activate() and own the
## mouse until they finish or are cancelled. Passive tools stay registered and get
## every event the active tool didn't consume (hotkeys, hover interactions).

const PASS: int = EditorPlugin.AFTER_GUI_INPUT_PASS
const STOP: int = EditorPlugin.AFTER_GUI_INPUT_STOP

var manager: CsgBlockoutToolManager

func get_id() -> StringName:
	return &""

## Called when the tool becomes the active modal tool (and again after each result
## while it's locked).
func activate() -> void:
	pass

## Called when the tool stops being active (finished, cancelled or replaced).
func deactivate() -> void:
	pass

## Esc / right click / the chip's Esc key: leave the tool.
func cancel() -> void:
	manager.deactivate(self)

## Returns PASS or STOP like EditorPlugin._forward_3d_gui_input().
func input(_camera: Camera3D, _event: InputEvent) -> int:
	return PASS

## Draws on the viewport overlay (screen space).
func draw_overlay(_overlay: Control, _camera: Camera3D) -> void:
	pass

## The chip at the top of the viewport while this tool is active. Only the one thing
## to do next, never a list of every key:
## {"title": String, "step": String, "accent": Color, "warn": bool,
##  "tags": [{"key": String, "label": String, "on": bool, "toggle": Callable}]}
func chip() -> Dictionary:
	return {}
