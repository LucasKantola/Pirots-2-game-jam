extends Enemy

class_name Fish

func _ready():
    super._ready()
    currentEffect = PlayerEffect.FISH
    effectiveTypes = [PlayerEffect.SLIME]
    sprite.play("Fish")
