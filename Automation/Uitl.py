import os
import time
from datetime import datetime

import pyautogui
from PIL import ImageDraw
from pynput import mouse

SAVE_DIR = os.path.join(os.getcwd(), "screenshots")
os.makedirs(SAVE_DIR, exist_ok=True)

BOX_HALF_SIZE = 25  # 红框半边长（像素）
BOX_LINE_WIDTH = 4  # 红框线宽（像素）


def sanitize_filename(s: str) -> str:
    return "".join(c if c not in r'\/:*?"<>|' else "_" for c in s)


def capture_and_mark(x: int, y: int):
    ts = datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]
    filename = sanitize_filename(f"{ts}_x{x}_y{y}.png")
    path = os.path.join(SAVE_DIR, filename)

    img = pyautogui.screenshot()
    w, h = img.size

    left = max(0, x - BOX_HALF_SIZE)
    top = max(0, y - BOX_HALF_SIZE)
    right = min(w - 1, x + BOX_HALF_SIZE)
    bottom = min(h - 1, y + BOX_HALF_SIZE)

    draw = ImageDraw.Draw(img)
    for i in range(BOX_LINE_WIDTH):
        draw.rectangle([left - i, top - i, right + i, bottom + i], outline="red")

    img.save(path)
    print(f"click=({x}, {y}) saved={path}")


def on_click(x, y, button, pressed):
    if pressed and button == mouse.Button.left:
        capture_and_mark(int(x), int(y))


if __name__ == "__main__":
    print("左键点击屏幕：输出坐标并保存截图（文件名=时间+坐标），截图中点击位置用红框标记。")
    print("按 Ctrl+C 退出。保存目录：", SAVE_DIR)
    with mouse.Listener(on_click=on_click) as listener:
        try:
            listener.join()
        except KeyboardInterrupt:
            pass