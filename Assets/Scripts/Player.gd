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
#region Effect Variables
var currentEffect := Global.PlayerEffect.NONE
@export var swollenShaderPath: String
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
			if currentEffect != Global.PlayerEffect.SLIME:
				velocity.y = JUMP_VELOCITY
			timeSinceJumpPressed = 0.0

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _input(event):
	if event.is_action_pressed("debug_none"):
		transform(Global.PlayerEffect.NONE)
	if event.is_action_pressed("debug_slime"):
		transform(Global.PlayerEffect.SLIME)
	if event.is_action_pressed("debug_swollen"):
		transform(Global.PlayerEffect.SWOLLEN)
	if event.is_action_pressed("debug_fish"):
		transform(Global.PlayerEffect.FISH)
	if event.is_action_pressed("debug_fire"):
		transform(Global.PlayerEffect.FIRE)

func transform(effect: Global.PlayerEffect):
	if currentEffect == effect:
		# Player already has effect, do nothing
		return
	if currentEffect != Global.PlayerEffect.NONE:
		# Player has another effect which must be removed first
		match currentEffect:
			Global.PlayerEffect.SLIME:
				modulate = Color.WHITE
			Global.PlayerEffect.FISH:
				pass
			Global.PlayerEffect.SWOLLEN:
				scale = Vector2(1.0, 1.0)
				$AnimatedSprite2D.material = null
			Global.PlayerEffect.FIRE:
				pass
	# Add effect
	match effect:
		Global.PlayerEffect.SLIME:
			print("Transform slime")
			modulate = Color.GREEN
		Global.PlayerEffect.FISH:
			print("Transform fish")
		Global.PlayerEffect.SWOLLEN:
			print("Transform swollen")
			scale = Vector2(2.0, 2.0)
			var sprite = $AnimatedSprite2D
			var shader = load(swollenShaderPath)
			if not sprite:
				print("WARNING: Could not get animated sprite 2D")
			elif not shader:
				print("WARNING: Could not find swollen shader")
			else:
				var material = ShaderMaterial.new()
				material.shader = shader
				sprite.material = material
		Global.PlayerEffect.FIRE:
			print("Transform fire")
	currentEffect = effect
