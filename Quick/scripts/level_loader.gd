extends RefCounted
## LevelLoader — reads level JSON files and returns parsed level data.
## Tutorial levels live in res://levels/tutorial/, real levels in res://levels/.

# Tile string → enum mapping (matches grid.gd Tile enum values)
const TILE_MAP := {
	"F": 0,   # FLOOR
	"W": 1,   # WALL
	"S": 2,   # START
	"E": 3,   # EXIT
	"Kr": 4,  # KEY_RED
	"Kb": 5,  # KEY_BLUE
	"Kg": 6,  # KEY_GREEN
	"Ky": 7,  # KEY_YELLOW
	"Dr": 8,  # DOOR_RED
	"Db": 9,  # DOOR_BLUE
	"Dg": 10, # DOOR_GREEN
	"Dy": 11, # DOOR_YELLOW
	"Tr": 12, # TELEPORT_RED
	"Tb": 13, # TELEPORT_BLUE
	"Tg": 14, # TELEPORT_GREEN
	"Ty": 15, # TELEPORT_YELLOW
}

## Load a level from a JSON file path. Returns a Dictionary with:
##   "name": String, "index": int,
##   "cols": int, "rows": int, "grid": Array[Array[int]]
## Rows/cols are derived from the	 grid array. All rows must be equal length.
## Returns an empty dict on failure.
static func load_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("LevelLoader: file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("LevelLoader: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}

	var data: Dictionary = json.data

	# Convert string grid to int grid and derive dimensions
	var raw_grid: Array = data.get("grid", [])
	if raw_grid.is_empty():
		push_error("LevelLoader: grid is empty in %s" % path)
		return {}

	var rows := raw_grid.size()
	var cols: int = raw_grid[0].size()
	var int_grid: Array = []
	for r in range(rows):
		var row_arr: Array = raw_grid[r]
		if row_arr.size() != cols:
			push_error("LevelLoader: row %d has %d cols (expected %d) in %s" % [r, row_arr.size(), cols, path])
			return {}
		var int_row: Array = []
		for cell_str in row_arr:
			var tile_val: int = TILE_MAP.get(cell_str, 0)  # default to FLOOR
			int_row.append(tile_val)
		int_grid.append(int_row)

	return {
		"name": data.get("name", "Unnamed"),
		"index": data.get("index", 0),
		"cols": cols,
		"rows": rows,
		"grid": int_grid,
	}

# --- Real levels (res://levels/) ---

## Return the file path for a real level by its 1-based index.
static func level_path(index: int) -> String:
	return "res://levels/level_%02d.json" % index

## Count how many real level files exist (sequential from level_01).
static func count_levels() -> int:
	var count := 0
	while FileAccess.file_exists(level_path(count + 1)):
		count += 1
	return count

# --- Tutorial levels (res://levels/tutorial/) ---

## Return the file path for a tutorial level by its 1-based index.
static func tutorial_path(index: int) -> String:
	return "res://levels/tutorial/level_%02d.json" % index

## Count how many tutorial level files exist.
static func count_tutorials() -> int:
	var count := 0
	while FileAccess.file_exists(tutorial_path(count + 1)):
		count += 1
	return count
