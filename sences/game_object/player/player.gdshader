shader_type canvas_item;

//声明一个纯黑色不透明  添加source_color就能够声明出来用着色盘，可以在检查器中直接调用选色
uniform vec4 outline_color: source_color = vec4(0,0,0,1);

//角色描边宽度
uniform float outline_width = 0.5;
// COLOR大写的代表这张角色的外观
void fragment() {
	//四个维度: 红绿蓝透明度
	//COLOR = vec4(0,0,0,0.5);
	//COLOR = outline_color;
	
	//shader中UV是没法变动的，所以要赋值在变动
	vec2 uv = UV;
	
	//按照原先理论，往四个方向扩大
	//这里TEXTURE_PIXEL_SIZE是将像素转为UV，UV是只有0-1的
	vec2 uv_up = uv + vec2(0, TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_down = uv + vec2(0, -TEXTURE_PIXEL_SIZE.y) * outline_width;
	vec2 uv_left = uv + vec2(TEXTURE_PIXEL_SIZE.x, 0) * outline_width;
	vec2 uv_right = uv + vec2(-TEXTURE_PIXEL_SIZE.x, 0) * outline_width;

	
	//修改采样为向上的图像
	vec4 color_up = texture(TEXTURE, uv_up);
	vec4 color_down = texture(TEXTURE, uv_down);
	vec4 color_left = texture(TEXTURE, uv_left);
	vec4 color_right = texture(TEXTURE, uv_right);

	//会把所有东西叠加在一起
	vec4 outline = color_up + color_down + color_left + color_right;
	
	//设置外观轮廓
	outline.rgb = outline_color.rgb;
	outline.a = min(outline.a, 1);
	
	//拿到原来的像素
	vec4 original_color = texture(TEXTURE, UV);
	//mix函数(A,B,值), 如果值为0则用A，如果为1则用B,这里用原来的a透明度,则原有角色像素都为1，其余地方则为0，也就是新的轮廓方
	COLOR = mix(outline, original_color, original_color.a);
	
	//COLOR = outline;
	//TEXTURE代表角色的纹理大小，UV则代表每个像素的位置
	//texture代表找到角色每个像素对应的颜色
	//COLOR = texture(TEXTURE, UV);
}

