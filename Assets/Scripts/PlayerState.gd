class_name PlayerState

var effect: Mob.PlayerEffect
var flip_h: bool

static func save(player: Player) -> PlayerState:
    var state = PlayerState.new()
    state.effect = player.currentEffect
    state.flip_h = player.flip_h
    return state

func apply(player: Player) -> void:
    player.transformTo(effect)
    player.flip_h = flip_h
    player.sprite.flip_h = flip_h
