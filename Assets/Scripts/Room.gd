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
    elif transitionState == TransitionState.DISAPPEARING:
        if transitionDurationSeconds == 0:
            t = 0.0
        else:
            t -= delta / transitionDurationSeconds
        if t <= 0.0:
            # Done disappearing
            process_mode = PROCESS_MODE_DISABLED
            transitionState = TransitionState.NONE
            t = 0.0
    
    set_deferred("modulate", Color(modulate, t))
    
func disappear():
    transitionState = TransitionState.DISAPPEARING
    # TODO: Disable colliders

func appear():
    process_mode = PROCESS_MODE_INHERIT
    transitionState = TransitionState.APPEARING
    # TODO: Enable colliders

enum TransitionState {
    NONE,
    APPEARING,
    DISAPPEARING,
}
