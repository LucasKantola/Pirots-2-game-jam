extends CharacterBody2D

class_name Mob

enum PlayerEffect {
    NONE,
    SLIME,
    FISH,
    SWOLLEN,
    FIRE,
}

#region Public variables
#region Physics Variables
@export_group("Physics")
@export var jumpVelocity: float = -300.0
@export var speed: float = 100.0
@export var floorFriction: float = 2.0
@export var airFriction: float = 0.05
#endregion
#endregion

#region Effect Variables
var currentEffect := PlayerEffect.NONE
#endregion

#region Utility
var flip_h: bool:
    set(value):
        sprite.flip_h = value
    get:
        return sprite.flip_h
var flip_v: bool:
    set(value):
        sprite.flip_v = value
    get:
        return sprite.flip_v
#endregion

#region References
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var world: Node2D
var tileMap: ExtendedTileMap
var gui: GUI
#endregion

#region Defaults
var GRAVITY: float = ProjectSettings.get_setting("physics/2d/default_gravity")
#endregion

func _ready():
    world = get_node("/root/World")
    tileMap = get_node("/root/World/Terrain")
    gui = get_node("/root/World/GUI")

func addGravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

func kill() -> void:
    queue_free()
