import os
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM
from PIL import Image
import io

def svg_to_ico(svg_path, ico_path):
    print(f"正在转换透明图标: {svg_path}...")
    
    # 1. 渲染 SVG
    drawing = svg2rlg(svg_path)
    png_data = renderPM.drawToString(drawing, fmt="PNG")
    img = Image.open(io.BytesIO(png_data)).convert("RGBA")
    
    # 2. 核心：强制透明处理
    # 如果检测到背景是纯白且没有透明度，将其转换为透明
    datas = img.getdata()
    new_data = []
    for item in datas:
        # 如果像素是纯白 (255, 255, 255)，将其 Alpha 通道设为 0
        if item[0] == 255 and item[1] == 255 and item[2] == 255:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    
    # 3. 保存多尺寸 ICO
    icon_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (256, 256)]
    img.save(ico_path, format='ICO', sizes=icon_sizes)
    print(f"透明图标已生成: {ico_path}")

# ... 其余 main 函数代码保持不变 ...

def main():
    # 遍历当前目录下所有的 svg 文件
    files = [f for f in os.listdir('.') if f.endswith('.svg')]
    
    if not files:
        print("未找到 .svg 文件，请确保脚本放在图标目录下。")
        return

    # 创建 assets 文件夹（如果不存在）
    if not os.path.exists('assets'):
        os.makedirs('assets')

    for svg_file in files:
        name = os.path.splitext(svg_file)[0]
        svg_path = svg_file
        ico_path = f"assets/{name}.ico"
        svg_to_ico(svg_path, ico_path)

if __name__ == "__main__":
    main()