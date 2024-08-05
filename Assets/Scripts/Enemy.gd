extends Mob

class_name Enemy

@onready var hitbox: Area2D = $"Hitbox Area"
@onready var hurtbox: Area2D = $"Hurtbox Area"
@onready var worldCol: CollisionShape2D = $WorldCollision
@onready var light: PointLight2D = $Light

var damage = 1
var effectiveTypes: Array = []
var hasGravity = true

var isDead = false
var isPlayerMovingDeadBody = false
var playerBody: Player

func _ready():
    super._ready()
    connect_signals()

func _physics_process(delta):
    if isPlayerMovingDeadBody:
        var directionCorrect = true if (playerBody.position.x < position.x and playerBody.direction > 0) or (playerBody.position.x > position.x and playerBody.direction < 0) else false
        if directionCorrect:
            velocity.x = speed * playerBody.direction
    if hasGravity:
        add_gravity(delta)
    if is_on_floor():
        velocity.x /= 1 + floorFriction
    else:
        velocity.x /= 1 + airFriction
    move_and_slide()

func connect_signals() -> void:
    hitbox.body_entered.connect(hitbox_area_entered)
    hitbox.body_exited.connect(hitbox_area_exited)
    hurtbox.body_entered.connect(hurtbox_area_entered)

func hitbox_area_entered(body: Node2D) -> void:
    if not isDead:
        print("Hitbox area entered")
        if body is Mob:
            body = body as Mob
            if body is Player:
                var player = body as Player
                print("Player hit by enemy")
                player.health -= damage
                if player.health > 0:
                    player.apply_effect(currentEffect)
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
                player.velocity.y = jumpVelocity
                player.health -= damage
                if player.health < 0:
                    player.kill()
                kill()
            else:
                var player = body as Player
                print(body.name + " hit by enemy")
                player.health -= damage
                if player.health > 0:
                    player.apply_effect(currentEffect)
                else:
                    player.kill()

func kill() -> void:
    isDead = true
    flip_v = true
    hasGravity = true
