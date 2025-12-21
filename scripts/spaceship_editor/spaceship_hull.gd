class_name SpaceshipHull
extends Node2D

@export var max_guns = 2

func add_weapon(weapon: Weapon):
    %WeaponsContainer.add_child(weapon)