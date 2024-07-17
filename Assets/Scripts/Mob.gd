extends CharacterBody2D

class_name Mob

enum PlayerEffect {
    NONE,
    SLIME,
    FISH,
    SWOLLEN,
    FIRE,
}

#region Player Variables
@export var HP := 5
#region Physics Variables
@export var JUMP_VELOCITY := -300.0
@export var SPEED := 200.0
#endregion
#region Effect Variables
var currentEffect := PlayerEffect.NONE
#endregion
#region Defaults
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var world: Node2D
var tileMap: TileMap
#endregion
#endregion

func _ready():
    world = get_node("/root/World")
    tileMap = get_node("/root/World/TileMap")

func addGravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

### Det är bara queue_free() som är skriven i finare text. Det tar bort objectet
func kill() -> void:
    queue_free()