extends Node2D

class_name SaveFunctions

func _ready() -> void:
	download_skills()

func save_characters(characters: Array):
	var path = "user://characters.save"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(characters)
		file.store_string(json_string)
		file.close()
	pass
func load_characters() -> Array:
	var firstPath = "res://Characters.json"
	var path = "user://characters.save"
	if not FileAccess.file_exists(path):
		path = firstPath
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		print(result)
		file.close()
		if result is Array:
			return result
	return []
func load_skills() -> Dictionary:
	var path = "res://database/skills/skills.csv"
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("File not Found")
		return {}
		
	var lines = file.get_as_text().split("\n", false)
	file.close()

	if lines.size() <= 1:
		return {}

	var headers = lines[0].split(",")
	var data: Dictionary = {}

	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line == "":
			continue
		var values = line.split(",")
		
		# Parse all skill properties including mana_cost
		var skill = {
			"name": values[1],
			"damage_multiplier": float(values[2]),
			"description": values[3],
			"is_multi_target": values[4] == "TRUE",
			"mana_cost": int(values[5]) if values.size() > 5 else 0
		}
		
		data[int(values[0])] = skill
	return data

func download_skills():

	var url = "https://docs.google.com/spreadsheets/d/1yzeKOgEGvKEkrAPS7ku6sVcL6IcdF73H0boI2i4lGIE/gviz/tq?tqx=out:csv&sheet=skills"
	var save_path = "user://skills.csv"

	var http = HTTPRequest.new()
	add_child(http)

	await get_tree().process_frame  # Aguarda o HTTPRequest entrar na árvore
	
	http.request_completed.connect(func(result, response_code, headers, body):
		if result == HTTPRequest.RESULT_SUCCESS:
			var csv_text = body.get_string_from_utf8()
			var file = FileAccess.open(save_path, FileAccess.WRITE)
			if file:
				file.store_string(csv_text)
				file.close()
				print("CSV downloaded and saved to: ", save_path)
		else:
			push_error("Failed to download CSV. Result code: %d" % result)
	)

	var error = http.request(url, [], HTTPClient.METHOD_GET, "")
	if error != OK:
		push_error("HTTPRequest failed to start: %d" % error)
