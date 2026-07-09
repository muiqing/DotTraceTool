from pywinauto import Application, mouse
import ctypes
import time
from datetime import datetime

APP_PATH = r"D:\Apps\Polar\PolarControl\PolarControl.exe" 


def _screen_size():
    user32 = ctypes.windll.user32
    return user32.GetSystemMetrics(0), user32.GetSystemMetrics(1)


def ts():
    return datetime.now().strftime('%H:%M:%S.%f')[:-3]


def main():
    print(f"[{ts()}] Script started")

    app = Application(backend="uia").start(APP_PATH)
    print(f"[{ts()}] App started")

    time.sleep(2)
    print(f"[{ts()}] App started1")
    dlg = app.top_window()
    print(f"[{ts()}] App started2")
    print(f"[{ts()}] top_window result: {repr(dlg)}")
    print(f"[{ts()}] window_text: '{dlg.window_text()}'")
    print(f"[{ts()}] class_name: '{dlg.class_name()}'")
    print(f"[{ts()}] rectangle: {dlg.rectangle()}")
    print(f"[{ts()}] is_visible: {dlg.is_visible()}")
    print(f"[{ts()}] PID: {app.process}")
    dlg.set_focus()
    print(f"[{ts()}] Window focused")
    time.sleep(2)

    # 动作：右键双击"屏幕中间偏下"位置
    w, h = _screen_size()
    x = w // 2
    y = int(h * 0.7)
    mouse.double_click(button="right", coords=(x, y))
    print(f"[{ts()}] Mouse action done")
    time.sleep(2)

    try:
        pass
    except Exception:
        pass

    time.sleep(1)
    print(f"[{ts()}] Before close")

    # 关闭应用
    try:
        dlg.close()
        print(f"[{ts()}] dlg.close() returned")
    except Exception as e:
        print(f"[{ts()}] close failed: {e}, killing")
        app.kill()

    print(f"[{ts()}] Script finished")


if __name__ == "__main__":
    main()
