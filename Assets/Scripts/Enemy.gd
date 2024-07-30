extends Mob

class_name Enemy

enum EnemyTypings {
    SLIME,
    FISH,
    BEE,
    ANT,
}

@export var EnemyType: EnemyTypings

@onready var hitbox = $"Hitbox Area"
@onready var hurtbox = $"Hurtbox Area"
@onready var worldCol = $"WorldCollision"

var damage = 1
var effectiveTypes: Array = []

var isDead = false
var isPlayerMovingDeadBody = false
var playerBody: Player

func _ready():
    self.name = str(EnemyType)
    match EnemyType:
        EnemyTypings.SLIME:
            sprite.play("Slime")
            damage = 1
            SPEED = 100
            currentEffect = PlayerEffect.SLIME
            effectiveTypes = [PlayerEffect.SWOLLEN]

        EnemyTypings.FISH:
            sprite.play("Fish")
            damage = 1
            SPEED = 200
            currentEffect = PlayerEffect.FISH
            effectiveTypes = [PlayerEffect.SLIME]
        EnemyTypings.BEE:
            sprite.play("Bee")
            damage = 1
            SPEED = 300
            currentEffect = PlayerEffect.SWOLLEN
            effectiveTypes = [PlayerEffect.FIRE]
        EnemyTypings.ANT:
            sprite.play("Fire")
            damage = 1
            SPEED = 400
            currentEffect = PlayerEffect.FIRE
            effectiveTypes = [PlayerEffect.FISH]

func _physics_process(delta):
    if isPlayerMovingDeadBody:
        var directionCorrect = true if (playerBody.position.x < position.x and playerBody.direction > 0) or (playerBody.position.x > position.x and playerBody.direction < 0) else false
        if directionCorrect:
            velocity.x = SPEED * playerBody.direction
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
        if body is Player:
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
