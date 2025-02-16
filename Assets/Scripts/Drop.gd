extends RigidBody2D

class_name Drop

@export var velocity: Vector2 = Vector2.ZERO
@export var direction: Vector2 = Vector2.ZERO
@export var speed: float = 1200.0 
@export var gravity: float = 1000.0
@export var dragPercentage: float = 63.0
@export var lifetime: float = 1.0
@export var gravityDisabled: bool = false
@export var dropType: DropType

enum DropType {
    WATER,
    LAVA
}

var timer: Timer

func _ready():
    velocity = direction * speed
    timer = Timer.new()
    add_child(timer)
    timer.wait_time = lifetime
    timer.connect("timeout", Callable(self, "_on_timer_timeout"))
    timer.start()
    gravity_scale = 0 if gravityDisabled else 1

func _physics_process(delta):
    velocity.y += gravity * delta
    velocity.x -= velocity.x * dragPercentage * delta
    var col = move_and_collide(velocity * delta)
    if col:
        queue_free()

func _on_timer_timeout():
    queue_free()

func _process(_delta):
    queue_redraw()

func _draw():
    print("Draw!")
    draw_circle($CollisionShape2D.position, 3, Color.RED)
