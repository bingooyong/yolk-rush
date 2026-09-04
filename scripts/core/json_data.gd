class_name JsonData
extends RefCounted
## Read UTF-8 JSON from a res:// or absolute path. Domain helper only.

static func read_dict(path: String) -> Dictionary:
	var err_msg := ""
	if path.is_empty():
		push_error("JsonData: empty path")
		return {}
	if not FileAccess.file_exists(path):
		push_error("JsonData: missing file: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("JsonData: open failed: %s (%s)" % [path, FileAccess.get_open_error()])
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JsonData: root must be object: %s" % path)
		return {}
	return parsed as Dictionary
