extends Mob

class_name Enemy

enum EnemyTypings {
	SLIME,
	FISH,
	BEE,
	ANT,
}

@export var EnemyType: EnemyTypings

var damage = 1
var effectiveTypes: Array = []

var stompForce = 0

func _ready():
	self.name = str(EnemyType)
	match EnemyType:
		EnemyTypings.SLIME:
			sprite.play("slime")
			damage = 1
			SPEED = 100
			currentEffect = PlayerEffect.SLIME
			effectiveTypes = [PlayerEffect.SWOLLEN]
			stompForce = JUMP_VELOCITY * 0.8
		EnemyTypings.FISH:
			sprite.play("fish")
			damage = 1
			SPEED = 200
			currentEffect = PlayerEffect.FISH
			effectiveTypes = [PlayerEffect.SLIME]
		EnemyTypings.BEE:
			sprite.play("bee")
			damage = 1
			SPEED = 300
			currentEffect = PlayerEffect.SWOLLEN
			effectiveTypes = [PlayerEffect.FIRE]
		EnemyTypings.ANT:
			sprite.play("ant")
			damage = 1
			SPEED = 400
			currentEffect = PlayerEffect.FIRE
			effectiveTypes = [PlayerEffect.FISH]

func _physics_process(delta):
	addGravity(delta)
	move_and_slide()

func hitbox_area_entered(_body_rid:RID, body:Node2D, _body_shape_index:int, _local_shape_index:int) -> void:
	print("Hitbox area entered")
	if body is Mob:
		body = body as Mob
		if body.name == "Player":
			body = body as Player
			print("Player hit by enemy")
			body.HP -= damage
			body.transformTo(currentEffect)

func hurtbox_area_entered(_body_rid:RID, body:Node2D, _body_shape_index:int, _local_shape_index:int) -> void:
	print("Hurtbox area entered")
	if body is Mob:
		body = body as Mob
		if body.currentEffect in effectiveTypes:
			print("Enemy killed by player")
			body.velocity.y = stompForce
			kill()
		elif body.name == "Player":
			body = body as Player
			print(body.name + " hit by enemy")
			body.HP -= damage
			body.transformTo(currentEffect)
