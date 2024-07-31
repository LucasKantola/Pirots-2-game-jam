extends CharacterBody2D

class_name Mob

enum PlayerEffect {
    NONE,
    SLIME,
    FISH,
    SWOLLEN,
    FIRE,
}

#region Variables
@export var maxHP := 5
@export var HP := 5:
    set(value):
        var oldHealth = HP
        HP = value
        health_changed.emit(HP, oldHealth)
    get:
        return HP
#region Physics Variables
@export var JUMP_VELOCITY := -300.0
@export var SPEED := 100.0
@export var floorFriction := 2.0
@export var airFriction := 0.05
#endregion
#region Effect Variables
var currentEffect := PlayerEffect.NONE
#endregion
#region Defaults
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var world: Node2D
var tileMap: TileMap
var gui: GUI
#endregion
#endregion

#region Signals
signal health_changed(newHealth: int, oldHealth: int)
#endregion

func _ready():
    world = get_node("/root/World")
    tileMap = get_node("/root/World/Terrain")
    gui = get_node("/root/World/GUI")

func addGravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

### Det är bara queue_free() som är skriven i finare text. Det tar bort objectet
func kill() -> void:
    queue_free()
