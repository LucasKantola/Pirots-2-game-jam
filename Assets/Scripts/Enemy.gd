extends Mob

class_name Enemy

enum EnemyTypings {
    NONE,
    SLIME,
    FISH,
    BEE,
    FIRE,
}

@export var enemyType: EnemyTypings

@onready var hitbox: Area2D = $"Hitbox Area"
@onready var hurtbox: Area2D = $"Hurtbox Area"
@onready var worldCol: CollisionShape2D = $"WorldCollision"
@onready var light: PointLight2D = $"PointLight2D"
@onready var smokeEffect: GPUParticles2D

var damage = 1
var effectiveTypes: Array = []
var hasGravity = true

var isDead = false
var isPlayerMovingDeadBody = false
var playerBody: Player

func _ready():
    self.name = str(enemyType)
    match enemyType:
        EnemyTypings.SLIME:
            sprite.play("Slime")
            damage = 1
            currentEffect = PlayerEffect.SLIME
            effectiveTypes = [PlayerEffect.SWOLLEN]
            hasGravity = true
        EnemyTypings.FISH:
            sprite.play("Fish")
            damage = 1
            currentEffect = PlayerEffect.FISH
            effectiveTypes = [PlayerEffect.SLIME]
            hasGravity = true
        EnemyTypings.BEE:
            sprite.play("Bee")
            damage = 1
            currentEffect = PlayerEffect.SWOLLEN
            effectiveTypes = [PlayerEffect.FIRE]
            hasGravity = false
        EnemyTypings.FIRE:
            sprite.play("Fire")
            damage = 1
            currentEffect = PlayerEffect.FIRE
            effectiveTypes = [PlayerEffect.FISH]
            hasGravity = false
            smokeEffect = $"SmokeParticles"
        EnemyTypings.NONE:
            print("No enemy type set")
            sprite.play("TYPE NOT SET")
func _physics_process(delta):
    if isPlayerMovingDeadBody:
        var directionCorrect = true if (playerBody.position.x < position.x and playerBody.direction > 0) or (playerBody.position.x > position.x and playerBody.direction < 0) else false
        if directionCorrect:
            velocity.x = SPEED * playerBody.direction
    if hasGravity:
        addGravity(delta)
    if is_on_floor():
        velocity.x /= 1 + floorFriction
    else:
        velocity.x /= 1 + airFriction
    move_and_slide()

func hitbox_area_entered(body: Node2D) -> void:
    if not isDead:
        print("Hitbox area entered")
        if body is Mob:
            body = body as Mob
            if body is Player:
                var player = body as Player
                print("Player hit by enemy")
                player.HP -= damage
                if player.HP > 0:
                    player.transformTo(currentEffect)
                else:
                    player.kill()
    elif body is Player:
        isPlayerMovingDeadBody = true
        playerBody = body as Player

func hitbox_area_exited(body: Node2D) -> void:
    if body is Player:
        isPlayerMovingDeadBody = false

func hurtbox_area_entered(body: Node2D) -> void:
    print("Hurtbox area entered")
    if not isDead:
        if body is Player and enemyType != EnemyTypings.FIRE:
            if body.currentEffect in effectiveTypes:
                var player = body as Player
                print("Enemy killed by player")
                player.velocity.y = JUMP_VELOCITY
                player.HP -= damage
                if player.HP < 0:
                    player.kill()
                isDead = true
            else:
                var player = body as Player
                print(body.name + " hit by enemy")
                player.HP -= damage
                if player.HP > 0:
                    player.transformTo(currentEffect)
                else:
                    player.kill()
        # If the enemy is a fire enemy, it can only die from water drops
        elif body.is_in_group("Drop"):
            print("A member of the Drop group hit enemy")
            if body.dropType == body.DropType.WATER and enemyType == EnemyTypings.FIRE:
                sprite.visible = false
                hurtbox.monitoring = false
                hitbox.monitoring = false
                worldCol.disabled = true
                light.enabled = false
                smokeEffect.emitting = true
                isDead = true
                await smokeEffect.finished
                kill()