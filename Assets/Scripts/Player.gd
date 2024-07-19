extends Mob

class_name Player

#region Player Variables
var hflipped = false
var stopInput = false
@export var wallClimbModifier = 0.5
var flippedTowardsWall = false
var wallWasLeft = false
var hitbox: CollisionShape2D
var waterParticle: GPUParticles2D
@export var drop: PackedScene
var spawnEveryXFrames = 5
var framesSinceSpawn = 0

var wallCheckDistance = 12

#region Physics Variables
var timeSinceGround = INF
var timeSinceJumpPressed = INF
@export var jumpBufferTime = 0.1
@export var coyoteTime = 0.1
#endregion
#region Effect Variables
@export var swollenShaderPath: String
#endregion
#endregion

func _ready():
    world = get_node("/root/World")
    tileMap = get_node("/root/World/Teräng")
    hitbox = get_node("Hitbox")
    waterParticle = get_node("WaterGun")
    drop = load("res://Assets/Scenes/Drop.tscn")
    #ifall skumma saker händer så säger vi fuck det här
    if not world or not TileMap or not sprite or not hitbox or not waterParticle:
        print("WARNING: Could not find world, tilemap or sprite")
        get_tree().quit() 

func _physics_process(delta):
    if Input.is_action_pressed("shoot"):
        if currentEffect == PlayerEffect.FISH:
            waterParticle.emitting = true
            if framesSinceSpawn >= spawnEveryXFrames:	
                var dropInstance = drop.instantiate()
                dropInstance.speed = 300
                dropInstance.gravity = 200
                if not hflipped:
                    dropInstance.position = position + Vector2(7, -9)
                    dropInstance.direction = Vector2(1, -0.5)
                else:
                    dropInstance.position = position + Vector2(-7, -9)
                    dropInstance.direction = Vector2(-1, -0.5)
                get_parent().add_child(dropInstance)
                framesSinceSpawn = 0
            else:
                framesSinceSpawn += 1
    else:
        waterParticle.emitting = false

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
                velocity.y = JUMP_VELOCITY
            timeSinceJumpPressed = INF
            timeSinceGround = INF

    #Left right movement from the axis
    var direction = Input.get_axis("left", "right")
    if direction:
        if is_on_wall() and currentEffect == PlayerEffect.SLIME:
            var cellCustom
            var cellData = tileMap.get_cell_tile_data(0, tileMap.local_to_map(position + Vector2(wallCheckDistance * direction, 12)))
            print(cellData)
            if cellData:
                print(cellData)
                cellCustom = cellData.get_custom_data("Scalable")
                print(cellCustom)
            if cellCustom:
                print(cellCustom)
                faceWall(direction)
                velocity.y = -SPEED * wallClimbModifier

        velocity.x = direction * SPEED
        if direction == 1:
                sprite.flip_h = false
                hflipped = false
                waterParticle.process_material.set("direction", Vector2(1, -0.5))
                waterParticle.position = Vector2(7, -9)
        elif direction == -1:
                sprite.flip_h = true
                hflipped = true
                waterParticle.process_material.set("direction", Vector2(-1, -0.5))
                waterParticle.position = Vector2(-7, -9)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    if stopInput:
        velocity.x = 0

    if is_on_floor_only() and flippedTowardsWall:
        self.rotation = 0
        flippedTowardsWall = false
        wallCheckDistance = 12

    addGravity(delta)
    move_and_slide()

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


### tranform funkar inte att ha som namn på funktionen då det är en refenrens till en bodyns transform så den fick ett finare namn
func transformTo(effect: PlayerEffect):
    var tween: Tween
    if currentEffect == effect:
        # Player already has effect, do nothing
        return
    if currentEffect != PlayerEffect.NONE:
        # Player has another effect which must be removed first
        match currentEffect:
            PlayerEffect.SLIME:
                sprite.play_backwards("Transform-slime")
                hitbox.shape.size = Vector2(16, 29)
                hitbox.position = Vector2(0, 1.15)
            PlayerEffect.FISH:
                sprite.play_backwards("Transform-fish")
            PlayerEffect.SWOLLEN:
                tween = create_tween()
                tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8)
                sprite.material = null
            PlayerEffect.FIRE:
                pass
    # Add effect
    match effect:
        PlayerEffect.SLIME:
            stopInput = true
            print("transformTo slime")
            sprite.play("Transform-slime")
            await sprite.animation_finished
            hitbox.shape.size = Vector2(16, 13)
            hitbox.position = Vector2(0, 9.5)
            stopInput = false
        PlayerEffect.FISH:
            stopInput = true
            print("transformTo fish")
            sprite.play("Transform-fish")
            await sprite.animation_finished
            stopInput = false
        PlayerEffect.SWOLLEN:
            stopInput = true
            print("transformTo swollen")
            tween = create_tween()
            tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.8)
            var shader = load(swollenShaderPath)
            if not shader:
                print("WARNING: Could not find swollen shader")
            else:
                var material = ShaderMaterial.new()
                material.shader = shader
                sprite.material = material
            stopInput = false
        PlayerEffect.FIRE:
            stopInput = true
            print("transformTo fire")
            stopInput = false
    if tween:
        await tween.finished
        tween.kill()
    currentEffect = effect

func kill() -> void:
    var image = get_parent().get_node("CanvasLayer").get_node("GameOver")
    image.visible = true

    queue_free()

func faceWall(direction: float):
    if not flippedTowardsWall:
        var original_position = position
        var sprite_offset = Vector2(0, 0)

        if direction < 0.5:
            wallWasLeft = true
            self.rotation = PI/2
            sprite_offset = Vector2(-hitbox.shape.extents.y, hitbox.shape.extents.x) / 2
        elif direction > 0.5:
            wallWasLeft = false
            self.rotation = -PI/2
            sprite_offset = Vector2(hitbox.shape.extents.y, -hitbox.shape.extents.x) / 2

        position = original_position + sprite_offset
        flippedTowardsWall = true
        wallCheckDistance = 28
