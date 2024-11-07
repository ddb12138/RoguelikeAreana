extends TouchScreenButton

const DRAG_RADIUS := 24.0

var finger_index := -1
var drag_offset: Vector2

@onready var rest_pos := global_position

func _input(event: InputEvent) -> void:
	var st := event as InputEventScreenTouch
	if st:
		if st.pressed and finger_index == -1:
			print("Touch pressed at:", st.position)
			var global_pos := st.position * get_canvas_transform()
			print("Global position:", global_pos)
			var local_pos := global_pos * get_global_transform()
			print("Local position:", local_pos)
			var rect := Rect2(Vector2.ZERO, texture_normal.get_size())
			print("size:", texture_normal.get_size())
			if rect.has_point(local_pos):
				# 按下
				finger_index = st.index
				drag_offset = global_pos - global_position
				print("Finger index set to:", finger_index)
		elif not st.pressed and st.index == finger_index:
			# 松开
			print("Touch released, resetting finger index")
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_release("move_up")
			Input.action_release("move_down")

			finger_index = -1
			global_position = rest_pos


	var sd := event as InputEventScreenDrag
	if sd and sd.index == finger_index:
		var wish_pos := sd.position * get_canvas_transform() - drag_offset   
		var movement := (wish_pos - rest_pos).limit_length(DRAG_RADIUS)
		global_position =  rest_pos + movement   
		

		#print("b X:", movement.x)
		#print("b Y:", movement.y)
		movement /= DRAG_RADIUS #可以使x，y归一化
		#print("X:", movement.x)
		#print("Y:", movement.y)
		if movement.x > 0:
			Input.action_release("move_left")
			Input.action_press("move_right", movement.x)
		elif movement.x <0:
			Input.action_release("move_right")
			Input.action_press("move_left", -movement.x)
		
		if movement.y > 0:
			Input.action_release("move_up")
			Input.action_press("move_down", movement.y)
		elif movement.y <0:
			Input.action_release("move_down")
			Input.action_press("move_up", -movement.y)

		
