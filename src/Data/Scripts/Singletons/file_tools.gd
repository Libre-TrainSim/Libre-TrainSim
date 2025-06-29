class_name FileTools
extends Object


## Removes invalid file name characters from the provided string
static func to_valid_filename(filename: String) -> String:
	return filename.to_lower().strip_edges().strip_escapes() \
			super.replace("/", "_").replace("\\", "_").replace(":", "_") \
			super.replace("?", "_").replace("*", "_").replace("\"", "_") \
			super.replace("|", "_").replace("%", "_").replace("<", "_") \
			super.replace(">", "_")
