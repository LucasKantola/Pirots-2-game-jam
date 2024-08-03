extends Enemy

class_name Bee

func _ready():
    super._ready()
    currentEffect = PlayerEffect.SWOLLEN
    effectiveTypes = [PlayerEffect.FIRE]
    hasGravity = false
    sprite.play("Bee")
