extends Control

# 原来的 card_clicked 删掉，换成 card_selected
signal card_selected(card_data: CardData, card_ui: Control)

var card_data: CardData
var is_selected: bool = false   # ← 新增：是否被选中

func setup(data: CardData) -> void:
	card_data = data
	$NameLabel.text = data.card_name
	$CostLabel.text = str(data.cost)
	$DescLabel.text = data.description
	
	# 职业卡加边框颜色
	if data.job_class == "rogue":
		$Background.color = Color(0.2, 0.3, 0.4)      # 蓝紫
	elif data.job_class == "warrior":
		$Background.color = Color(0.4, 0.2, 0.2)      # 暗红
	elif data.job_class == "mage":
		$Background.color = Color(0.3, 0.2, 0.4)      # 紫
	else:
		$Background.color = Color(0.2, 0.2, 0.25)     # 通用灰

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 发送"选中"信号，而不是直接释放
			card_selected.emit(card_data, self)
