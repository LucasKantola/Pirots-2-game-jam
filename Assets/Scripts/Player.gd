extends Mob

class_name Player

#region Variables
#region Public Variables
#region Health Variables
@export_group("Health")
@export var maxHealth: int = 5
@export var health: int = 5:
    set(value):
        var oldHealth = health
        health = value
        health_changed.emit(health, oldHealth)
    get:
        return health
#endregion
#region Transform Variables
@export_group("Transform")
@export var transformDuration: float = 0.8
#endregion
#region Sound Variables
@export_group("Sound")
## How many pixels the player has to fall for the land sound to play.
@export var landSoundDistance: float = 100
#endregion
#region Debug Variables
@export_group("Editor")
@export var drawHitbox := false
#endregion
#endregion

#region Movement Variables
var stopInput = false
var direction = 0

#region WallClimb Variables
var wallClimbModifier = 0.8
var flippedTowardsWall = false
var wallCheckDistance = 12
#endregion
#endregion

#region Shooting Variables
var slowdownWhileShooting = 0.5
var slowedDown = false
var drop: PackedScene
var spawnEveryXFrames = 5
var framesSinceSpawn = 0
#endregion

#region Physics Variables
var timeSinceJumpPressed = INF
var jumpBufferTime = 0.1
var coyoteTime = 0.1
#endregion

#region References
var hitbox: CollisionShape2D
var light: PointLight2D

#region Sound Effects
var jumpSound: AudioStreamPlayer
var slimeWalkSound: AudioStreamPlayer
var slimeTranformSound: AudioStreamPlayer
var landSound: AudioStreamPlayer
var waterSound: AudioStreamPlayer
var explosionSound: AudioStreamPlayer
#endregion

#region Particles
var waterParticle: GPUParticles2D
var fireParticle: GPUParticles2D
#endregion
#endregion

#region Player Effect Values
## Specifies an animation to play when transforming to an effect.
var effectTransformAnimations: Dictionary = {
    PlayerEffect.NONE: "Normal",
    PlayerEffect.SLIME: "Slime",
    PlayerEffect.FISH: "Fish",
    PlayerEffect.FIRE: "Fire"
}
## Specicfies an AudioStreamPlayer to play when transforming to an effect.
var effectTransformSounds: Dictionary = {}
## Specifies the properties to apply for each player effect. Unspecified
## properties default to PlayerEffect.NONE.
var effectProperties: Dictionary = {
    PlayerEffect.SLIME: {
        "light.position": Vector2(0, 11),
        "hitbox.shape.size": Vector2(16, 13),
        "hitbox.position": Vector2(0, 9.5),
    },
    PlayerEffect.SWOLLEN: {
        "scale": Vector2(1.5, 1.5),
    },
}
#endregion

#region Glow colors based on player sprites
var GLOW_COLOR_NORMAL := Color(2.259, 2.957, 2.686)
var GLOW_COLOR_FIRE := Color(2.5, 2.182, 2.343)
var LIGHT_COLOR_NORMAL := Color.hex(0x42f4afff)
var LIGHT_COLOR_FIRE := Color.hex(0xffaed7ff)
#endregion
#endregion

#region Signals
signal health_changed(newHealth: int, oldHealth: int)
#endregion

func _ready():
    super._ready()
    
    # Check required references
    var requiredReferences = ["world", "sprite", "hitbox", "waterParticle"]
    var missingReferences = requiredReferences.filter(func (name: String):
        return not is_instance_valid(get(name))
        )
    assert(missingReferences.is_empty(), "%s could not find required reference(s): %s" %
        [self.name, ", ".join(missingReferences)])
    
    # Register health bar update
    gui.health = health
    health_changed.connect(func(newHealth: int, oldHealth: int):
        gui.health = newHealth
        )
    
    # Transform prerequisites
    apply_default_effect_properties()
    # Must be set after assign_references() is called
    effectTransformSounds = {
        PlayerEffect.SLIME: slimeTranformSound
    }

func assign_references():
    super.assign_references()
    
    hitbox = get_node("Hitbox")
    light = get_node("Light")
    
    # Particles
    waterParticle = get_node("Particles/WaterGun")
    fireParticle = get_node("Particles/FireGun")
    drop = load("res://Assets/Scenes/Drop.tscn")
    
    # Sounds
    jumpSound = get_node("SFX/Jump")
    slimeWalkSound = get_node("SFX/Slime walk")
    slimeTranformSound = get_node("SFX/Slime transform")
    landSound = get_node("SFX/Land")
    waterSound = get_node("SFX/Water")
    explosionSound = get_node("SFX/Explosion")

## Assign [code]effectProperties[PlayerEffect.NONE][/code] to the player's
## current properties. Only assigns properties present in
## [member Player.effectProperties].
func apply_default_effect_properties():
    var defaults = (effectProperties[PlayerEffect.NONE]
        if PlayerEffect.NONE in effectProperties
        else {})
    for effect in effectProperties:
        if effect == PlayerEffect.NONE:
            continue
        for propName in effectProperties[effect]:
            if propName in defaults:
                continue
            var value = get_deep(propName)
            defaults[propName] = value
    effectProperties[PlayerEffect.NONE] = defaults

func _process(delta):
    # Make the color glow in the correct color for the sprite
    var isFire = currentEffect == PlayerEffect.FIRE
    modulate = GLOW_COLOR_FIRE if isFire else GLOW_COLOR_NORMAL
    light.color = LIGHT_COLOR_FIRE if isFire else LIGHT_COLOR_NORMAL

func _physics_process(delta: float):
    super._physics_process(delta)
    if stopInput:
        print("Input is stopped")

    # Stomping blocks in the swollen form
    if currentEffect == PlayerEffect.SWOLLEN:
        if has_just_landed():
            #Check the preset offsets for a block that has the breakanble custom data
            var checkPositions = [
                Vector2(-6, 32),
                Vector2(6, 32)
            ]
            for pos in checkPositions:
                if tileMap.get_custom_data_from_tilemap(0, global_position + pos, "Breakable"):
                    tileMap.set_cell(0, tileMap.local_to_map(global_position + pos), -1)
                    velocity.y = jumpVelocity * 0.7
                    explosionSound.play()


    # Sound effect for landing
    if has_just_landed() and (position.y - fallenFromY) > landSoundDistance:
        landSound.play()

    if Input.is_action_pressed("shoot") and not stopInput:
        if currentEffect == PlayerEffect.FISH:
            slowedDown = true
            waterParticle.emitting = true
            if framesSinceSpawn >= spawnEveryXFrames:
                var dropInstance = drop.instantiate()
                dropInstance.speed = 300
                dropInstance.gravity = 200
                dropInstance.dropType = dropInstance.DropType.WATER
                if not flip_h:
                    dropInstance.position = position + waterParticle.position
                    dropInstance.direction = Vector2(1, -0.5)
                else:
                    dropInstance.position = position + waterParticle.position
                    dropInstance.direction = Vector2(-1, -0.5)
                get_parent().add_child(dropInstance)
                framesSinceSpawn = 0
                if not waterSound.playing:
                    waterSound.playing = true
            else:
                framesSinceSpawn += 1
        if currentEffect == PlayerEffect.FIRE:
            slowedDown = true
            fireParticle.emitting = true
            if framesSinceSpawn >= spawnEveryXFrames:
                var dropInstance = drop.instantiate()
                dropInstance.speed = 300
                dropInstance.gravity = 0
                dropInstance.gravityDisabled = true
                dropInstance.lifetime = 0.35
                dropInstance.dropType = dropInstance.DropType.LAVA
                if not flip_h:
                    dropInstance.position = position + fireParticle.position
                    dropInstance.direction = Vector2(1, 0)
                else:
                    dropInstance.position = position + fireParticle.position
                    dropInstance.direction = Vector2(-1, 0)
                get_parent().add_child(dropInstance)
                framesSinceSpawn = 0
            else:
                framesSinceSpawn += 1
    else:
        stop_shooting()

    if Input.is_action_just_pressed("up"):
        if not stopInput:
            timeSinceJumpPressed = 0.0
    else:
        timeSinceJumpPressed += delta
    
    if Input.is_action_pressed("down"):
        set_collision_mask_value(5, false)
    else:
        set_collision_mask_value(5, true)
    
    if timeSinceJumpPressed < jumpBufferTime:
        if (is_on_floor() and timeSinceJumpPressed < jumpBufferTime) or is_on_floor() or timeSinceGround < coyoteTime:
            if currentEffect != PlayerEffect.SLIME:
                velocity.y = jumpVelocity
                jumpSound.play()
            timeSinceJumpPressed = INF

    #Left right movement from the axis
    direction = Input.get_axis("left", "right")
    if direction and not stopInput:
        if is_on_wall() and currentEffect == PlayerEffect.SLIME:
            var xPos = wallCheckDistance * direction
            var checkPositionsSlime = [
                Vector2(xPos, 14),
                Vector2(xPos, 8),
            ]
            for pos in checkPositionsSlime:
                var cellCustom = tileMap.get_custom_data_from_tilemap(0, global_position + pos, "Scalable")
                $RayCast2D.target_position = pos

                if cellCustom or $RayCast2D.is_colliding():
                    face_wall(direction)
                    velocity.y = -speed * wallClimbModifier
        velocity.x = direction * speed

        if direction == 1:
                flip_h = false
                waterParticle.process_material.set("direction", Vector2(1, -0.5))
                waterParticle.position = Vector2(7, -9)
                fireParticle.process_material.set("direction", Vector2(1, 0))
                fireParticle.position = Vector2(4, -3)
        elif direction == -1:
                flip_h = true
                waterParticle.process_material.set("direction", Vector2(-1, -0.5))
                waterParticle.position = Vector2(-7, -9)
                fireParticle.process_material.set("direction", Vector2(-1, 0))
                fireParticle.position = Vector2(-4, -3)
        
        velocity.x = clamp(velocity.x, -speed, speed)
        if Input.is_action_pressed("debug_sprint"):
            velocity.x *= 3
    elif is_on_floor():
        velocity.x /= 1 + floorFriction
    else:
        velocity.x /= 1 + airFriction

    if slowedDown:
        velocity.x *= slowdownWhileShooting

    if not is_on_wall() and flippedTowardsWall:
        var tween = create_tween()
        tween.tween_property(sprite, "rotation", 0, 0.05)
        if tween:
            await tween.finished
            tween.kill()
        sprite.position = Vector2(0, 0)
        flippedTowardsWall = false

    if velocity != Vector2() and currentEffect == PlayerEffect.SLIME:
        if not slimeWalkSound.playing:
            slimeWalkSound.playing = true
    else:
        slimeWalkSound.playing = false

    add_gravity(delta)
    
    move_and_slide()
    queue_redraw()

func _unhandled_input(event):
    if event.is_action_pressed("debug_none"):
        apply_effect(PlayerEffect.NONE)
    if event.is_action_pressed("debug_slime"):
        apply_effect(PlayerEffect.SLIME)
    if event.is_action_pressed("debug_swollen"):
        apply_effect(PlayerEffect.SWOLLEN)
    if event.is_action_pressed("debug_fish"):
        apply_effect(PlayerEffect.FISH)
    if event.is_action_pressed("debug_fire"):
        apply_effect(PlayerEffect.FIRE)
    if event.is_action_pressed("reset"):
        if world is World:
            world.reset_room()
        else:
            get_tree().reload_current_scene()

func apply_effect(effect: PlayerEffect) -> void:
    print("Apply effect %s" % PlayerEffect.keys()[effect])
    if currentEffect == effect:
        # Player already has effect, do nothing
        return
    
    stopInput = true
    stop_shooting()
    kill_current_tweens()
    # Applying a new effect
    if effect in effectTransformAnimations:
        sprite.play(effectTransformAnimations[effect])
    else:
        sprite.play(effectTransformAnimations[PlayerEffect.NONE])
    # Play current effect sound again when returning to normal
    if effect == PlayerEffect.NONE:
        if currentEffect in effectTransformSounds:
            effectTransformSounds[currentEffect].play()
    else:
        if effect in effectTransformSounds:
            effectTransformSounds[effect].play()
    
    # Get full properties list
    var allPropertyNames = {}
    for ee in effectProperties:
        for propertyName in effectProperties[ee]:
            # Godot does not have sets so we use dictionary keys
            allPropertyNames[propertyName] = null
    
    # Apply properties
    var properties = effectProperties[effect] if effect in effectProperties else {}
    for propertyName in allPropertyNames:
        var value: Variant
        if propertyName in properties:
            value = properties[propertyName]
        else:
            value = effectProperties[PlayerEffect.NONE][propertyName]
        if value is bool or value is String:
            set_deep(propertyName, value)
        else:
            tween_property_deep(propertyName, value, transformDuration)

    stopInput = false
    currentEffect = effect
    
func apply_effect_instant(effect: PlayerEffect, playSound: bool = false) -> void:
    print("Apply effect instant %s" % PlayerEffect.keys()[effect])
    if currentEffect == effect:
        # Player already has effect, do nothing
        return
    
    stopInput = true
    stop_shooting()
    kill_current_tweens()
    # Applying a new effect
    if effect in effectTransformAnimations:
        sprite.play(effectTransformAnimations[effect])
    else:
        sprite.play(effectTransformAnimations[PlayerEffect.NONE])
    if playSound:
        # Play current effect sound again when returning to normal
        if effect == PlayerEffect.NONE:
            if currentEffect in effectTransformSounds:
                effectTransformSounds[currentEffect].play()
        else:
            if effect in effectTransformSounds:
                effectTransformSounds[effect].play()
    
    # Get full properties list
    var allPropertyNames = {}
    for ee in effectProperties:
        for propertyName in effectProperties[ee]:
            # Godot does not have sets so we use dictionary keys
            allPropertyNames[propertyName] = null
    
    # Apply properties
    var properties = effectProperties[effect] if effect in effectProperties else {}
    for propertyName in allPropertyNames:
        var value: Variant
        if propertyName in properties:
            value = properties[propertyName]
        else:
            value = effectProperties[PlayerEffect.NONE][propertyName]
        set_deep(propertyName, value)

    stopInput = false
    currentEffect = effect

func kill() -> void:
    gui.show_game_over()
    queue_free()

## Wait until tween has finished, then kill it.
func kill_tween(tween: Tween) -> void:
    if tween:
        await tween.finished
        tween.kill()

func face_wall(direction: float):
    if not flippedTowardsWall:
        var tween = create_tween()
        if direction < 0.5:
            tween.tween_property(sprite, "rotation", PI / 2, 0.05)
            sprite.position = Vector2(8, 9)
            
        elif direction > 0.5:
            tween.tween_property(sprite, "rotation", -PI / 2, 0.05)
            sprite.position = Vector2(-8, 9)
        if tween:
            await tween.finished
            tween.kill()
        flippedTowardsWall = true
    
func stop_shooting():
    waterParticle.emitting = false
    waterSound.playing = false
    fireParticle.emitting = false
    slowedDown = false

func _draw():
    if drawHitbox:
        draw_rect(Rect2(hitbox.position.x - hitbox.shape.size.x / 2, hitbox.position.y - hitbox.shape.size.y / 2, hitbox.shape.size.x, hitbox.shape.size.y), Color(0, 1, 0, 0.5))
