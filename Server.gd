extends Node


onready var peer = NetworkedMultiplayerENet.new()



func _ready()->void :
	peer.create_client("127.0.0.1", 1025)
	get_tree().network_peer = peer
	peer.connect("connection_failed", self, "recondecon")
	peer.connect("server_disconnected", self, "recondecon")


func recondecon():
	peer.create_client("127.0.0.1", 1025)
	get_tree().network_peer = peer
