extends Node2D


@export var burnTime := 2.0
@export var fireNeeded := 10
var timer: Timer
var burning: GPUParticles2D
var smoke: GPUParticles2D
var dust: GPUParticles2D

func _ready():
    timer = $Timer
    burning = $BurningParticles
    smoke = $SmokeParticles
    dust = $DustParticles

    if not timer or not burning or not smoke or not dust: 
        push_error("Could not find all nodes for the Vines! Check it out")

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("Drop"):
        if body.dropType == body.DropType.LAVA:
            fireNeeded -= 1
            dust.emitting = true
            if fireNeeded <= 0:
                if not timer.is_connected("timeout", Callable(self, "_on_burning_finished")):
                    timer.start(burnTime)
                    timer.connect("timeout", Callable(self, "_on_burning_finished"))

                    burning.emitting = true

func _on_burning_finished():
    smoke.emitting = true
    $Sprite2D.visible = false
    $CollisionShape2D.disabled = true
    burning.emitting = false
    dust.emitting = false
    await smoke.finished
    queue_free()
