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
#region Public variables
#region Physics Variables
@export_group("Physics")
@export var jumpVelocity: float = -300.0
@export var speed: float = 100.0
@export var floorFriction: float = 2.0
@export var airFriction: float = 0.05
#endregion
#endregion

#region Physics Variables
## The last elevation this mob had upwards velocity in the air. Or INF if the
## mob has never had upwards velocity while off the ground.
var fallenFromY = INF
## In seconds, how long this mob has been off the ground. Or -INF if the mob is
## on the ground.
var timeSinceGround = -INF
## In seconds, how long this mob has been on the ground. Or -INF if the mob is
## not on the ground.
var timeOnGround = -INF
#endregion

#region Effect Variables
var currentEffect := PlayerEffect.NONE
var _currentTweens := []
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
#endregion

func _ready():
    assign_references()

## Find and assign important references for this mob.
func assign_references() -> void:
    world = get_node("/root/World")
    tileMap = get_node("/root/World/Terrain")
    gui = get_node("/root/World/GUI")

func _physics_process(delta: float):
    if is_on_floor():
        timeSinceGround = -INF
        if timeOnGround == -INF:
            timeOnGround = 0
        else:
            timeOnGround += delta
    else:
        if velocity.y <= 0.0:
            fallenFromY = position.y
        timeOnGround = -INF
        if timeSinceGround == -INF:
            timeSinceGround = 0
        else:
            timeSinceGround += delta

func add_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

func kill() -> void:
    queue_free()

func has_just_landed() -> bool:
    return timeOnGround == 0
    
func has_just_left_ground() -> bool:
    return timeSinceGround == 0

## Like [method Object.get] but allows you to get properties of referenced
## instances using dots. If the [param property] does not exist, this method
## returns [code]null[/code]. This method cannot get properties of classes that
## do not inherit [class Object].
## [codeblock]
## player.sprite = $AnimatedSprite2D
## player.sprite.play("Fire")
## var a = player.get_deep("sprite.animation") # a is "Fire"
## [/codeblock]
func get_deep(property: StringName) -> Variant:
    var nodes = property.split(".")
    var current = self
    for node in nodes:
        if not current is Object:
            return null
        current = current.get(node)
    return current

## Like [method Object.set] but allows you to set properties of referenced
## instances using dots. Returns if the [param property] exists. This method
## cannot set properties of classes that do not inherit [class Object].
## [codeblock]
## player.hitbox = $Hitbox
## var a = player.set_deep("hitbox.shape.size", Vector2(2, 2)) # a is true
## var b = player.set_deep("does.not.exist", 42) # b is false
## [/codeblock]
func set_deep(property: StringName, value: Variant) -> bool:
    var nodes = property.split(".")
    var current = self
    for node in nodes.slice(0, -1):
        current = current.get(node)
        if not current is Object:
            return false
    current.set(nodes[-1], value)
    return nodes[-1] in current

## Like [method Player.set_deep] but tweened over time according to
## [param duration] in seconds. The tween will be killed after finishing.
## Returns the [PropertyTweener] or [code]null[/code] if the [param property]
## does not exist or cannot be tweened for any other reason.
func tween_property_deep(property: StringName, finalVal: Variant, duration: float) -> PropertyTweener:
    var node = self
    var propertyName = property
    if property.count(".") > 0:
        var s = property.rsplit(".", true, 0)[0]
        node = get_deep(s[0])
        propertyName = s[1]
    if (not node is Node
            or not propertyName in node
            or typeof(node.get(propertyName)) != typeof(finalVal)):
        return null
    var tween = create_tween()
    var path = NodePath(propertyName)
    var tweener = tween.tween_property(node, path, finalVal, duration)
    _currentTweens.append(tween)
    tween.finished.connect(func():
        tween.kill()
        _currentTweens.erase(tween)
        )
    
    return tweener

func kill_current_tweens():
    for tween in _currentTweens:
        tween.kill()
    _currentTweens.clear()
