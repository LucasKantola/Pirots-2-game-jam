extends CharacterBody2D

#region Player Variables
#region Physics Variables
@export var JUMP_VELOCITY := -300.0
@export var SPEED := 200.0

var timeSinceGround = INF
var timeSinceJumpPressed = INF
@export var jumpBufferTime = 0.1
@export var coyoteTime = 0.1
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
    tileMap = world.get_node("/root/World/TileMap")

func _physics_process(delta):
    if Input.is_action_just_pressed("ui_accept"):
        timeSinceJumpPressed = 0.0
    else:
        timeSinceJumpPressed += delta

    if not is_on_floor():
        velocity.y += gravity * delta
        timeSinceGround += delta
    else:
        timeSinceGround = 0.0

    if timeSinceJumpPressed < jumpBufferTime:
        if (is_on_floor() and timeSinceJumpPressed < 1) or is_on_floor() or timeSinceGround < coyoteTime:
            velocity.y = JUMP_VELOCITY
            timeSinceJumpPressed = 0.0

    var direction = Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    move_and_slide()