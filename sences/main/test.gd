extends CharacterBody2D

@onready var suction_ability = $SuctionAbility

func _process(delta: float) -> void:
	suction_ability.apply_suction(self)
