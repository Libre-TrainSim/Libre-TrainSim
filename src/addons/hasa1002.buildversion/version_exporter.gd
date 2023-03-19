tool
extends EditorExportPlugin


var version_label := ""
var last_generated_label := ""


func _export_begin(_features: PoolStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	build()


func _export_end() -> void:
	reset()


func reset() -> void:
	ProjectSettings["application/version/dirty"] = false
	ProjectSettings["application/version/broken"] = false
	ProjectSettings["application/version/custom"] = false
	ProjectSettings["application/version/commit"] = ""
	ProjectSettings["application/version/label"] = version_label
	ProjectSettings.save()


func build() -> void:
	ProjectSettings["application/version/dirty"] = true
	ProjectSettings["application/version/broken"] = true
	ProjectSettings["application/version/custom"] = true
	ProjectSettings["application/version/commit"] = ""
	if ProjectSettings.has_setting("application/version/label") and last_generated_label != ProjectSettings["application/version/label"]:
		version_label = ProjectSettings["application/version/label"]
	var output := []
	var exit := OS.execute("git", ["describe", "--all"], true, output, true)
	if exit != 0:
		printt(exit, output)
		push_warning("Project used without SCM. No version info available.")
		ProjectSettings["application/version/label"] = "%s CUSTOM BUILD" % version_label
		last_generated_label = ProjectSettings["application/version/label"]
		ProjectSettings.save()
		return

	var custom_build := "" if ("master" in output[0] or "main" in output[0] or "release" in output[0]) else ".custom.%s"

	exit = OS.execute("git", ["status", "-s"], true, output, true)
	if exit != 0:
		printt(exit, output)
		push_warning("Failed to determine state.")
		ProjectSettings["application/version/label"] = "%s CUSTOM BUILD" % version_label
		last_generated_label = ProjectSettings["application/version/label"]
		ProjectSettings.save()
		return

	var dirty := " DIRTY BRANCH" if !output[0].empty() else ""
	if dirty:
		print("Modified files:")
		print(output[0])
		exit = OS.execute("git", ["diff"], true, output, true)
		if exit != 0:
			printt(exit, output)
			push_warning("Failed to determine diff.")
		else:
			print(output[0])

	exit = OS.execute("git", ["describe", "--tags", "--long" ,"--always", "--dirty=", "--broken=?"], true, output, true)
	if exit != 0:
		printt(exit, output)
		push_warning("Failed to determine version.")
		ProjectSettings["application/version/label"] = "% CUSTOM BUILD" % version_label
		last_generated_label = ProjectSettings["application/version/label"]
		ProjectSettings.save()
		return

	var parts: PoolStringArray = output[0].split("-", false)
	var broken := " BROKEN" if "?" in parts[-1] else ""
	var commit: String = parts[-1].left(len(parts[-1]) - (2 if broken else 1))

	ProjectSettings["application/version/dirty"] = !dirty.empty()
	ProjectSettings["application/version/broken"] = !broken.empty()
	ProjectSettings["application/version/custom"] = !custom_build.empty()
	ProjectSettings["application/version/commit"] = commit

	if len(parts) < 3:
		if !custom_build.empty():
			custom_build = custom_build % commit
		ProjectSettings["application/version/label"] = "v %s%s%s%s" % [commit, custom_build, broken, dirty]
		last_generated_label = ProjectSettings["application/version/label"]
		ProjectSettings.save()
		return

	commit = commit.right(1)
	ProjectSettings["application/version/commit"] = commit
	if !custom_build.empty():
		custom_build = custom_build % commit

	if (parts[1] == "0"):
		ProjectSettings["application/version/label"] = "%s%s%s%s" % [parts[0], custom_build, broken, dirty]
		last_generated_label = ProjectSettings["application/version/label"]
		ProjectSettings.save()
		return
	ProjectSettings.set_setting("application/version/label", "%s.%s%s%s%s" % [parts[0], parts[1], custom_build, broken, dirty])
	last_generated_label = ProjectSettings["application/version/label"]
	ProjectSettings.save()

