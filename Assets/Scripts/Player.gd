extends Mob

class_name Player

#region Player Variables
@export var isStomping = false
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
	tileMap = get_node("/root/World/TileMap")

func _physics_process(delta):
	addGravity(delta)

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("up"):
		timeSinceJumpPressed = 0.0
	else:
		timeSinceJumpPressed += delta
	
	if not is_on_floor():
		timeSinceGround += delta
		isStomping = true
	else:
		timeSinceGround = 0.0
		isStomping = false

	
	if timeSinceJumpPressed < jumpBufferTime:
		if (is_on_floor() and timeSinceJumpPressed < jumpBufferTime) or is_on_floor() or timeSinceGround < coyoteTime:
			if currentEffect != PlayerEffect.SLIME:
				velocity.y = JUMP_VELOCITY
			timeSinceJumpPressed = INF
			timeSinceGround = INF

	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		
		if direction == 1:
				sprite.flip_h = false
		elif direction == -1:
				sprite.flip_h = true
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _input(event):
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
	if currentEffect == effect:
		# Player already has effect, do nothing
		return
	if currentEffect != PlayerEffect.NONE:
		# Player has another effect which must be removed first
		match currentEffect:
			PlayerEffect.SLIME:
				modulate = Color.WHITE
				sprite.play_backwards("Transform-slime")

			PlayerEffect.FISH:
				pass
			PlayerEffect.SWOLLEN:
				scale = Vector2(1.0, 1.0)
				sprite.material = null
			PlayerEffect.FIRE:
				pass
	# Add effect
	match effect:
		PlayerEffect.SLIME:
			print("transformTo slime")
			sprite.play("Transform-slime")
			#modulate = Color.GREEN
		PlayerEffect.FISH:
			print("transformTo fish")
		PlayerEffect.SWOLLEN:
			print("transformTo swollen")
			scale = Vector2(2.0, 2.0)
			var shader = load(swollenShaderPath)
			if not shader:
				print("WARNING: Could not find swollen shader")
			else:
				var material = ShaderMaterial.new()
				material.shader = shader
				sprite.material = material
		PlayerEffect.FIRE:
			print("transformTo fire")
	currentEffect = effect

