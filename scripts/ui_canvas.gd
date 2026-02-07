extends CanvasLayer

@onready var health_bar = $TopBar/HealthBar

func _ready():
	# Initialize bar to full (or wait for signal)
	health_bar.value = 100

func _on_goose_health_changed(health_percent: Variant) -> void:
	health_bar.value = health_percent
