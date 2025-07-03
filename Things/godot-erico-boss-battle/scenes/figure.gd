extends Sprite2D

func play_rarity_sound(rarity):
	# [$Common, $Rare, $Epic, $Legendary][rarity].play()
	# [$Epic, $Epic, $Legendary, $Legendary][rarity].play()
	$Legendary.play()
