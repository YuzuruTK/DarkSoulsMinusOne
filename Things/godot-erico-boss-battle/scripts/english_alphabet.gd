extends ResourcePreloader

# Source:
# https://norvig.com/ngrams/count_1w.txt
# I only got the first 200000
# TODO: maybe I should just pick the first 100000
# TODO: I just realized I am calling this an alphabet, but this is a dictionary actually...
var alphabet: Array[String] = []

enum Rarity {
	Common, Rare, Epic, Legendary
}

const rarity_colors = [Color.WEB_GRAY, Color.DODGER_BLUE, Color.PURPLE, Color.ORANGE]
const rarity_multipliers = [1, 2, 3, 5]
const rarity_texts = ["Common. x1", "Rare! x2", "Epic!! x3", "Legendary!!! x5"]
# const rarity_commonalities = [0.7, 0.19, 0.05, 0.01]
# const rarity_ranges = [0.1, 0.3, 0.6, 1]

#func get_rarity_color(rarity: Rarity) -> Color:
	#match rarity:
		#Rarity.Common :    return Color.WEB_GRAY 
		#Rarity.Rare :      return Color.DODGER_BLUE
		#Rarity.Epic :      return Color.PURPLE
		#Rarity.Legendary : return Color.ORANGE
		#_ :                return Color.WHITE

func is_word_valid(word: String) -> bool:
	return word in alphabet

var rng := RandomNumberGenerator.new()

func random_rarity(priorities = [0.7, 0.19, 0.05, 0.01]) -> Rarity:
	var value = rng.randf()
	print("random_rality_value: ", value)
	if value < priorities[0]:
		return Rarity.Common
	elif value < priorities[0] + priorities[1]:
		return Rarity.Rare
	elif value < priorities[0] + priorities[1] + priorities[2]:
		return Rarity.Epic
	else:
		return Rarity.Legendary

func random_word_range(from, to, begins_with: String = "") -> String:
	var words: Array[String] = alphabet.slice(from, to)
	
	if begins_with:
		words = words.filter(
			func(word: String): return word.begins_with(begins_with)
		)
		
	return words.pick_random()

func random_word(begins_with: String = "") -> String:
	var rarity = random_rarity()
	var total_words = alphabet.size()
	if rarity == Rarity.Common:
		return random_word_range(0, total_words * 0.1, begins_with)
	elif rarity == Rarity.Rare:
		return random_word_range(total_words * 0.1, total_words * 0.3, begins_with)
	elif rarity == Rarity.Epic:
		return random_word_range(total_words * 0.3, total_words * 0.6, begins_with)
	else:
		return random_word_range(total_words * 0.6, total_words, begins_with)

# This assumes the word is valid!
# The first 10% words are Common
# The next 20% are Rare
# The next 30% are Epic
# The rest of the 40% are Legendary
func find_word_rarity(word: String) -> Rarity:
	var total_words = alphabet.size()
	var index = alphabet.find(word)
	if index < total_words * 0.1:
		return Rarity.Common
	elif index >= total_words * 0.1 and index < total_words * 0.3:
		return Rarity.Rare
	elif index >= total_words * 0.3 and index < total_words * 0.6:
		return Rarity.Epic
	else:
		return Rarity.Legendary

func _read_file_lines(path: String) -> Array[String]:
	var lines: Array[String] = []
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line()
			lines.append(line.strip_edges())
		file.close()
	else:
		push_error("Failed to load file.")
	
	return lines

func _ready() -> void:
	alphabet = _read_file_lines("res://Things/godot-erico-boss-battle/assets/words_clear.txt")
