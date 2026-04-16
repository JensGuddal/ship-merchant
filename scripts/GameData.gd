extends Node

const SAVE_PATH := "user://savegame.json"

var coins: int = 50
var inventory: Array = []
var reputation: float = 0.0
var fleet: Array = []
var crew: Array = []
var office_level: int = 0
var current_port: String = ""
var discovered_ports: Array[String] = []


## Writes all persistent fields to user://savegame.json as JSON via FileAccess.
## No parameters.
func save() -> void:
	var data := {
		"coins": coins,
		"inventory": inventory,
		"reputation": reputation,
		"fleet": fleet,
		"crew": crew,
		"office_level": office_level,
		"current_port": current_port,
		"discovered_ports": discovered_ports,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameData.save: could not open %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Restores state from user://savegame.json. Missing file returns false without error;
## corrupt JSON returns false and logs an error.
## Returns true when a valid save dictionary was applied.
func load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameData.load: could not open %s (error %d)" % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	var raw := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		push_error("GameData.load: save file is malformed")
		return false

	var data := parsed as Dictionary
	coins = int(data.get("coins", 50))
	inventory = _coerce_inventory(data.get("inventory", []))
	reputation = float(data.get("reputation", 0.0))
	fleet = _coerce_dict_array(data.get("fleet", []))
	crew = _coerce_dict_array(data.get("crew", []))
	office_level = int(data.get("office_level", 0))
	current_port = str(data.get("current_port", ""))
	discovered_ports = _coerce_string_array(data.get("discovered_ports", []))
	return true


## Adds amount to coins. amount: whole coins to add (negative values are ignored).
func add_coins(amount: int) -> void:
	if amount > 0:
		coins += amount


## Deducts amount from coins if the balance is sufficient.
## amount: coins to remove. Returns true if deducted, false if insufficient funds.
func remove_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	return true


## Adds qty units of good_id, stacking with an existing stack if present.
## good_id: catalogue id (e.g. "wheat"). qty: units to add (must be > 0).
func add_to_inventory(good_id: String, qty: int) -> void:
	if qty <= 0:
		return
	for i in inventory.size():
		var row: Variant = inventory[i]
		if row is Dictionary and str(row.get("id", "")) == good_id:
			row["qty"] = int(row.get("qty", 0)) + qty
			inventory[i] = row
			return
	inventory.append({"id": good_id, "qty": qty})


## Removes qty units of good_id from stacked inventory entries.
## Returns false if total stock is lower than qty (inventory unchanged).
func remove_from_inventory(good_id: String, qty: int) -> bool:
	if qty <= 0:
		return true
	var total := 0
	for row in inventory:
		if row is Dictionary and str(row.get("id", "")) == good_id:
			total += int(row.get("qty", 0))
	if total < qty:
		return false
	var remaining := qty
	var i := 0
	while i < inventory.size() and remaining > 0:
		var row: Variant = inventory[i]
		if not row is Dictionary or str(row.get("id", "")) != good_id:
			i += 1
			continue
		var have := int(row.get("qty", 0))
		if have <= remaining:
			remaining -= have
			inventory.remove_at(i)
			continue
		row["qty"] = have - remaining
		inventory[i] = row
		break
	return true


func _coerce_inventory(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary and item.has("id"):
				out.append({"id": str(item["id"]), "qty": int(item.get("qty", 0))})
	return out


func _coerce_dict_array(value: Variant) -> Array:
	var out: Array = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				out.append((item as Dictionary).duplicate(true))
	return out


func _coerce_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out
