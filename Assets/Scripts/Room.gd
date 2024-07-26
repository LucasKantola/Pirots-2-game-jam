extends Node2D

class_name Room

#region Public variables
#region Transition variables
@export_group("Transition")
@export_range(0, 3, 0.1, "or_greater") var transitionDurationSeconds: float = 1.0
#endregion
#endregion

var transitionState := TransitionState.NONE
var t := 1.0

func _process(delta):
    if transitionState == TransitionState.NONE:
        return
    elif transitionState == TransitionState.APPEARING:
        if transitionDurationSeconds == 0:
            t = 1.0
        else:
            t += delta / transitionDurationSeconds
        if t >= 1.0:
            # Done appearing
            transitionState = TransitionState.NONE
            t = 1.0
            # Enable doors
            for door in get_tree().get_nodes_in_group("door"):
                if $".".is_ancestor_of(door):
                    door.disabled = false
    elif transitionState == TransitionState.DISAPPEARING:
        if transitionDurationSeconds == 0:
            t = 0.0
        else:
            t -= delta / transitionDurationSeconds
        if t <= 0.0:
            # Done disappearing
            transitionState = TransitionState.NONE
            t = 0.0
            process_mode = PROCESS_MODE_DISABLED
    
    set_deferred("modulate", Color(modulate, t))
    
func disappear():
    if t == 0.0:
        t = 1.0
    transitionState = TransitionState.DISAPPEARING
    # Disable doors
    for door in get_tree().get_nodes_in_group("door"):
        if $".".is_ancestor_of(door):
            door.disabled = true

func appear():
    if t == 1.0:
        t = 0.0
    process_mode = PROCESS_MODE_INHERIT
    transitionState = TransitionState.APPEARING

func disappear_instant():
    disappear()
    t = 0.0

func appear_instant():
    appear()
    t = 1.0

enum TransitionState {
    NONE,
    APPEARING,
    DISAPPEARING,
}
