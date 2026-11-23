@tool
class_name CsgBlockoutStatus
extends RefCounted
## One line of feedback at the top of the 3D viewport: what just happened, optionally
## with one clickable action ("Next ›"). Replaces toasts, which pile up at the bottom
## of the editor where nobody is looking; errors and warnings worth keeping are also
## sent to the editor's toaster (see report()).

const DEFAULT_SECONDS: float = 3.0
const WARNING_SECONDS: float = 5.0
const ACTION_SECONDS: float = 8.0

static var text: String = ""
static var warning: bool = false
static var action_label: String = ""
static var action: Callable = Callable()
static var _serial: int = 0

static func show(message: String, is_warning: bool = false, p_action_label: String = "", p_action: Callable = Callable(), seconds: float = DEFAULT_SECONDS) -> void:
	text = message
	warning = is_warning
	action_label = p_action_label
	action = p_action
	_serial += 1
	var serial: int = _serial
	CsgBlockoutToolManager.refresh_all()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(seconds).timeout.connect(func() -> void:
			if serial == _serial:
				clear())

## Feedback for something the user just did. Errors, and warnings that matter after
## the line fades (`keep`), also go to the editor's toaster.
static func report(message: String, severity: EditorToaster.Severity = EditorToaster.SEVERITY_INFO, keep: bool = false, p_action_label: String = "", p_action: Callable = Callable()) -> void:
	var seconds: float = DEFAULT_SECONDS if severity == EditorToaster.SEVERITY_INFO else WARNING_SECONDS
	if not p_action_label.is_empty():
		seconds = ACTION_SECONDS
	show(message, severity != EditorToaster.SEVERITY_INFO, p_action_label, p_action, seconds)
	if keep or severity == EditorToaster.SEVERITY_ERROR:
		var toaster: EditorToaster = EditorInterface.get_editor_toaster()
		if toaster != null:
			toaster.push_toast(message, severity)

static func clear() -> void:
	text = ""
	action_label = ""
	action = Callable()
	CsgBlockoutToolManager.refresh_all()

## Changes with every message: compare before and after an operation to tell whether
## it already said something (e.g. a warning that a success line shouldn't replace).
static func serial() -> int:
	return _serial

static func is_visible() -> bool:
	return not text.is_empty()

## Runs the action (if any) and hides the line.
static func trigger() -> void:
	var a: Callable = action
	clear()
	if a.is_valid():
		a.call()
