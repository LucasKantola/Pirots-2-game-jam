extends Node2D

class_name MusicPlayer

#region Public variables
@export var autoplay := true
@export var autoplaySong: Song
#endregion

var _currentlyPlaying: Song

@onready var audioPlayers = [
    $Menu,
    $Ingame,
]

enum Song {
    NONE,
    MENU,
    INGAME,
}

func _ready():
    print(_currentlyPlaying)
    if autoplay:
        play(autoplaySong)

func play(song: Song):
    if _currentlyPlaying == song:
        return
    stop()
    var songPlayer = audioPlayers[song - 1]
    songPlayer.play()
    print("Playing %s (%s)" % [Song.keys()[song], songPlayer.name])

func stop():
    for audioPlayer in audioPlayers:
        audioPlayer.stop()
    
