import os
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPM
from PIL import Image
import io

def svg_to_ico(svg_path, ico_path):
    """
    将 SVG 转换为 ICO，包含去除纯白背景的逻辑
    """
    print(f"正在转换 SVG 图标: {svg_path}...")
    
    try:
        # 1. 渲染 SVG
        drawing = svg2rlg(svg_path)
        png_data = renderPM.drawToString(drawing, fmt="PNG")
        img = Image.open(io.BytesIO(png_data)).convert("RGBA")
        
        # 2. 核心：强制透明处理 (仅针对 SVG 渲染可能产生的白底)
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
        print(f"SVG -> ICO 转换成功: {ico_path}")
        
    except Exception as e:
        print(f"转换 SVG {svg_path} 失败: {e}")

def png_to_ico(png_path, ico_path):
    """
    将 PNG 转换为 ICO (直接保留原有透明通道)
    """
    print(f"正在转换 PNG 图标: {png_path}...")
    
    try:
        # 1. 打开 PNG 并确保是 RGBA 模式
        img = Image.open(png_path).convert("RGBA")
        
        # 注意：对于 PNG，我们不执行去除白底的操作，
        # 因为高质量的 PNG 图标通常已经处理好了透明背景，
        # 且强制去白可能会破坏图标内部的白色元素（比如剑身）。
        
        # 2. 保存多尺寸 ICO
        # Pillow 会自动处理缩放
        icon_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (256, 256)]
        img.save(ico_path, format='ICO', sizes=icon_sizes)
        print(f"PNG -> ICO 转换成功: {ico_path}")
        
    except Exception as e:
        print(f"转换 PNG {png_path} 失败: {e}")

def main():
    # 创建 assets 文件夹（如果不存在）
    if not os.path.exists('assets'):
        os.makedirs('assets')
        print("创建 assets 目录...")

    # ==========================
    # 1. 处理 SVG 文件
    # ==========================
    svg_files = [f for f in os.listdir('.') if f.endswith('.svg')]
    for svg_file in svg_files:
        name = os.path.splitext(svg_file)[0]
        svg_path = svg_file
        ico_path = f"assets/{name}.ico"
        svg_to_ico(svg_path, ico_path)

    # ==========================
    # 2. 处理 PNG 文件 (新增)
    # ==========================
    png_files = [f for f in os.listdir('.') if f.endswith('.png')]
    for png_file in png_files:
        name = os.path.splitext(png_file)[0]
        png_path = png_file
        ico_path = f"assets/{name}.ico"
        
        # 如果同名 ICO 已存在（例如已经被 SVG 生成过），跳过或覆盖
        # 这里默认覆盖
        png_to_ico(png_path, ico_path)

    if not svg_files and not png_files:
        print("当前目录下未找到 .svg 或 .png 文件。")
    else:
        print("-" * 30)
        print("所有转换任务已完成。")

if __name__ == "__main__":
    main()