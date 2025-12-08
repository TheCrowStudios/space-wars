extends Control


func message_popup():
	%DefaultPopup.show()

func hide_message_popup():
	%DefaultPopup.hide()

func show_repair_progress():
	%RepairProgress.show()

func hide_repair_progress():
	%RepairProgress.hide()

func set_repair_progress(value: float):
	%RepairProgress.value = value

func set_repair_progress_seconds(value: float):
	%RepairSeconds.text = str("%0.1f" % value, "s")