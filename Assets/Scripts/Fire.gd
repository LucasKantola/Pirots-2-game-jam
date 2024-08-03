extends Enemy

class_name Fire

@onready var smokeEffect: GPUParticles2D = $SmokeParticles

func _ready():
    super._ready()
    currentEffect = PlayerEffect.FIRE
    effectiveTypes = [PlayerEffect.FISH]
    hasGravity = false
    sprite.play("Fire")

func hurtbox_area_entered(body: Node2D) -> void:
    print("Hurtbox area entered")
    print("Fire")
    # Fire enemies can only die from water drops
    if body.is_in_group("Drop"):
        print("A member of the Drop group hit fire enemy")
        if body.dropType == body.DropType.WATER:
            sprite.visible = false
            hurtbox.monitoring = false
            hitbox.monitoring = false
            worldCol.disabled = true
            light.enabled = false
            smokeEffect.emitting = true
            isDead = true
            await smokeEffect.finished
            kill()

func kill() -> void:
    queue_free()
