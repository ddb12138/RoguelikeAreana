extends BuffBase

func show_gpu_2d():
	_gpu_2d.global_position = _parentNode.global_position
	_gpu_2d.emitting = true

func apply_buff():
	super.apply_buff()
	show_gpu_2d()
	_heath_component.damage(-1)
