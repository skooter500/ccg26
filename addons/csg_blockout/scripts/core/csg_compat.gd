@tool
class_name CsgBlockoutCompat
extends RefCounted
## The plugin supports Godot 4.6+. Every engine-version-sensitive call goes through
## here; the pre-4.6 branches below are kept for a separate older-versions port.
##   EditorDock / add_dock ............ 4.6+ (add_control_to_dock before that)
##   EditorSettings.add_shortcut ...... 4.6+ (see CsgBlockoutShortcuts fallback)
##   TriangleMesh.intersect_ray ....... 4.5+
##   FileDialog.overwrite_warning_enabled  4.6+ (EditorFileDialog.disable_overwrite_warning before)

static func has_editor_dock() -> bool:
	return ClassDB.class_exists(&"EditorDock")

## Adds `content` as a dock (tabbed next to the Scene dock) and returns the handle to
## pass to remove_dock().
static func add_dock(plugin: EditorPlugin, content: Control, title: String, icon: Texture2D) -> Control:
	if has_editor_dock():
		var dock: Control = ClassDB.instantiate(&"EditorDock") as Control
		dock.set(&"title", title)
		if icon != null:
			dock.set(&"dock_icon", icon)
		dock.set(&"default_slot", ClassDB.class_get_integer_constant(&"EditorDock", &"DOCK_SLOT_LEFT_UR"))
		dock.add_child(content)
		plugin.call(&"add_dock", dock)
		return dock
	content.name = title
	plugin.call(&"add_control_to_dock", EditorPlugin.DOCK_SLOT_LEFT_UR, content)
	return content

## For save dialogs that merge into an existing file instead of overwriting it.
static func disable_overwrite_warning(dialog: Object) -> void:
	if &"overwrite_warning_enabled" in dialog:
		dialog.set(&"overwrite_warning_enabled", false)
	else:
		dialog.set(&"disable_overwrite_warning", true)

static func remove_dock(plugin: EditorPlugin, handle: Control) -> void:
	if handle == null or not is_instance_valid(handle):
		return
	if has_editor_dock() and handle.is_class("EditorDock"):
		plugin.call(&"remove_dock", handle)
	else:
		plugin.call(&"remove_control_from_docks", handle)
	handle.queue_free()
