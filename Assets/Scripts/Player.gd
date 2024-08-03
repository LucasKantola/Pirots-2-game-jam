extends Mob

class_name Player

#region Public variables
#region Health variables
@export_group("Health")
@export var maxHealth := 5
@export var health := 5:
    set(value):
        var oldHealth = health
        health = value
        health_changed.emit(health, oldHealth)
    get:
        return health
#endregion

#region Debug variables
@export_group("Editor")
@export var drawHitbox := false
#endregion
#endregion

#region Player Variables
var stopInput = false
var direction = 0
var light: PointLight2D

#region WallClimb Variables
var wallClimbModifier = 0.8
var flippedTowardsWall = false
var wallCheckDistance = 12
#endregion

#region Shooting Variables
var slowdownWhileShooting = 0.5
var slowedDown = false
var drop: PackedScene
var spawnEveryXFrames = 5
var framesSinceSpawn = 0
#endregion

#region Physics Variables
var timeSinceGround = INF
var timeSinceJumpPressed = INF
var jumpBufferTime = 0.1
var coyoteTime = 0.1

var wasInAirLastFrame = false
var fallenFromY = 0
#endregion
#endregion

#region References
var hitbox: CollisionShape2D

#region Sound Effects
var jumpSound: AudioStreamPlayer
var slimeWalkSound: AudioStreamPlayer
var slimeTranformSound: AudioStreamPlayer
var landSound: AudioStreamPlayer
var waterSound: AudioStreamPlayer
var explosionSound: AudioStreamPlayer
#endregion

#region Effect Variables
var waterParticle: GPUParticles2D
var fireParticle: GPUParticles2D
#endregion
#endregion

#region Predetermined colors for glow based on the colors of the player sprites
var normalGlowColor: Color = Color(2.259, 2.957, 2.686, 1)
var fireGlowColor: Color = Color(1.5 + 1, 1.182 + 1, 1.343 + 1, 1)
var normalLightColor: Color = Color.hex(0x42f4afff)
var fireLightColor: Color = Color.hex(0xffaed7ff)
#endregion

#region Signals
signal health_changed(newHealth: int, oldHealth: int)
#endregion

func _ready():
    super._ready()
    hitbox = get_node("Hitbox")
    waterParticle = get_node("Particles/WaterGun")
    fireParticle = get_node("Particles/FireGun")
    drop = load("res://Assets/Scenes/Drop.tscn")
    jumpSound = get_node("SFX/Jump")
    slimeWalkSound = get_node("SFX/Slime walk")
    slimeTranformSound = get_node("SFX/Slime transform")
    landSound = get_node("SFX/Land")
    waterSound = get_node("SFX/Water")
    explosionSound = get_node("SFX/Explosion")
    light = get_node("Light")
    #ifall skumma saker händer så säger vi fuck det här
    if not world or not sprite or not hitbox or not waterParticle:
        print("WARNING: Could not find world, tilemap or sprite")
        get_tree().quit()
    # Register health bar update
    gui.health = health
    health_changed.connect(func(newHealth: int, oldHealth: int):
        gui.health = newHealth
        )

func _physics_process(delta):
    #Make the color glow in the correct color for the sprite
    if currentEffect != PlayerEffect.FIRE:
        modulate = normalGlowColor
        light.color = normalLightColor
    else:
        modulate = fireGlowColor
        light.color = fireLightColor

    if stopInput:
        print("Input is stopped")

    #Logic for stomping blocks in the swollen form
    if currentEffect == PlayerEffect.SWOLLEN:
        #Landed?
        if wasInAirLastFrame and is_on_floor():
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
    if is_on_floor() and (position.y - fallenFromY) > 20:
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

    if not is_on_floor():
        timeSinceGround += delta
    else:
        timeSinceGround = 0.0
    
    if timeSinceJumpPressed < jumpBufferTime:
        if (is_on_floor() and timeSinceJumpPressed < jumpBufferTime) or is_on_floor() or timeSinceGround < coyoteTime:
            if currentEffect != PlayerEffect.SLIME:
                velocity.y = jumpVelocity
                jumpSound.play()
            timeSinceJumpPressed = INF
            timeSinceGround = INF

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
                    faceWall(direction)
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

    addGravity(delta)
    if is_on_floor() and not wasInAirLastFrame:
        fallenFromY = position.y

    wasInAirLastFrame = !is_on_floor()
    move_and_slide()
    queue_redraw()

func _unhandled_input(event):
    if event.is_action_pressed("debug_none"):
        transformTo(PlayerEffect.NONE)
    if event.is_action_pressed("debug_slime"):
        transformTo(PlayerEffect.SLIME)
    if event.is_action_pressed("debug_swollen"):
        transformTo(PlayerEffect.SWOLLEN)
    if event.is_action_pressed("debug_fish"):
        transformTo(PlayerEffect.FISH)
    if event.is_action_pressed("debug_fire"):
        transformTo(PlayerEffect.FIRE)
    if event.is_action_pressed("reset"):
        if world is World:
            world.reset_room()
        else:
            get_tree().reload_current_scene()


### tranform funkar inte att ha som namn på funktionen då det är en refenrens till en bodyns transform så den fick ett finare namn
func transformTo(effect: PlayerEffect):
    var tween: Tween
    if currentEffect == effect:
        # Player already has effect, do nothing
        return
    if currentEffect != PlayerEffect.NONE:
        # Player has another effect which must be removed first
        stopInput = true
        match currentEffect:
            PlayerEffect.SLIME:
                sprite.play("Normal")
                hitbox.shape.size = Vector2(16, 29)
                hitbox.position = Vector2(0, 1.15)
                tween = create_tween()
                tween.tween_property($Light, "position", Vector2(0, -5), 0.8)
                killTween(tween)
            PlayerEffect.FISH:
                sprite.play("Normal")
            PlayerEffect.SWOLLEN:
                tween = create_tween()
                tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.8)
                killTween(tween)
            PlayerEffect.FIRE:
                sprite.play("Normal")
        stop_shooting()
    # Add effect
    match effect:
        PlayerEffect.SLIME:
            print("transformTo slime")
            sprite.play("Slime")
            tween = create_tween()
            tween.tween_property($Light, "position", Vector2(0, 11), 0.8)
            slimeTranformSound.play()
            killTween(tween)
            hitbox.shape.size = Vector2(16, 13)
            hitbox.position = Vector2(0, 9.5)
        PlayerEffect.FISH:
            print("transformTo fish")
            sprite.play("Fish")
        PlayerEffect.SWOLLEN:
            sprite.play("Normal")
            tween = create_tween()
            tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.8)
            killTween(tween)
        PlayerEffect.FIRE:
            sprite.play("Fire")
            print("transformTo fire")

    stopInput = false
    killTween(tween)
    currentEffect = effect

func kill() -> void:
    gui.show_game_over()
    queue_free()

func killTween(tween: Tween) -> void:
    if tween:
        await tween.finished
        tween.kill()

func faceWall(direction: float):
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
