extends Enemy

class_name Slime

func _ready():
    super._ready()
    currentEffect = PlayerEffect.SLIME
    effectiveTypes = [PlayerEffect.SWOLLEN]
    sprite.play("Slime")
