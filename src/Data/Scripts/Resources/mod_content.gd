class_name ModContentDefinition
extends Resource


export (String) var unique_name: String = ""
export (String) var display_name: String = ""

export (int) var version_major: int = 1
export (int) var version_minor: int = 0
export (int) var version_patch: int = 0

# example: { "unique_name": "example_mod", "version": ">=1.0.0" }
export (Array, Dictionary) var depends_on: Array = []

export (Array, String, DIR) var environment_folders: Array = []
export (Array, String, DIR) var material_folders: Array = []
export (Array, String, DIR) var music_folders: Array = []
export (Array, String, DIR) var object_folders: Array = []
export (Array, String, DIR) var persons_folders: Array = []
export (Array, String, DIR) var rail_type_folders: Array = []
export (Array, String, DIR) var signal_type_folders: Array = []
export (Array, String, DIR) var sound_folders: Array = []
export (Array, String, DIR) var texture_folders: Array = []

export (Array, String, FILE, "*.tscn,*.scn") var trains: Array = []
export (Array, String, FILE, "*.tscn,*.scn") var worlds: Array = []


# get version as array
func _semver() -> Array:
	return [version_major, version_minor, version_patch]


# get version as string
func _semver_to_string() -> String:
	return "%s.%s.%s" % _semver()


# make semver from a string
func _semver_from_string(version: String) -> Array:
	var numbers = version.split(".", false)
	if len(numbers) != 3:
		Logger.error("Invalid String used for Semver: %s" % version, self)
		return [float("NaN"), float("NaN"), float("NaN")]
	return [int(numbers[0]), int(numbers[1]), int(numbers[2])]


# check version against version definition (String) like ">=1.0.0"
func _check_semver(version: String) -> bool:
	var version_to_check := []
	var is_valid := false

	if version.begins_with(">="):
		version_to_check = _semver_from_string(version.substr(2))
		is_valid = (version_major >= version_to_check[0]) \
				or (version_minor >= version_to_check[1]) \
				or (version_patch >= version_to_check[2])
	elif version.begins_with("<="):
		version_to_check = _semver_from_string(version.substr(2))
		is_valid = (version_major <= version_to_check[0]) \
				or (version_minor <= version_to_check[1]) \
				or (version_patch <= version_to_check[2])
	elif version.begins_with(">"):
		version_to_check = _semver_from_string(version.substr(1))
		is_valid = (version_major > version_to_check[0]) \
				or (version_minor > version_to_check[1]) \
				or (version_patch > version_to_check[2])
	elif version.begins_with("<"):
		version_to_check = _semver_from_string(version.substr(1))
		is_valid = (version_major < version_to_check[0]) \
				or (version_minor < version_to_check[1]) \
				or (version_patch < version_to_check[2])
	elif version.begins_with("="):
		version_to_check = _semver_from_string(version.substr(1))
		is_valid = (version_major == version_to_check[0]) \
				and (version_minor == version_to_check[1]) \
				and (version_patch == version_to_check[2])
	else:
		version_to_check = _semver_from_string(version)
		is_valid = (version_major >= version_to_check[0]) \
				or (version_minor >= version_to_check[1]) \
				or (version_patch >= version_to_check[2])

	return is_valid
