import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

class MouseController {
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

  // 定义 Windows API 常量
  static const int MOUSEEVENTF_ABSOLUTE = 0x8000;
  static const int MOUSEEVENTF_LEFTDOWN = 0x0002;
  static const int MOUSEEVENTF_LEFTUP = 0x0004;
  static const int MOUSEEVENTF_RIGHTDOWN = 0x0008;
  static const int MOUSEEVENTF_RIGHTUP = 0x0010;
  static const int MOUSEEVENTF_MOVE = 0x0001;

  // SetCursorPos 函数
  late final Function _setCursorPos = _user32.lookupFunction<
      Int32 Function(Int32 x, Int32 y),
      int Function(int x, int y)>('SetCursorPos');

  // mouse_event 函数
  late final Function _mouseEvent = _user32.lookupFunction<
      Void Function(Uint32 dwFlags, Uint32 dx, Uint32 dy, Uint32 dwData, Pointer dwExtraInfo),
      void Function(int dwFlags, int dx, int dy, int dwData, Pointer dwExtraInfo)>('mouse_event');

  /// 移动鼠标到指定坐标
  void moveTo(int x, int y) {
    _setCursorPos(x, y);
  }

  /// 左键点击指定坐标
  void leftClick(int x, int y) {
    // 移动到指定位置
    moveTo(x, y);
    
    // 延迟一小段时间确保移动完成
    sleep(const Duration(milliseconds: 10));
    
    // 按下左键
    _mouseEvent(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, nullptr);
    
    // 延迟
    sleep(const Duration(milliseconds: 50));
    
    // 释放左键
    _mouseEvent(MOUSEEVENTF_LEFTUP, 0, 0, 0, nullptr);
  }

  /// 右键点击指定坐标
  void rightClick(int x, int y) {
    // 移动到指定位置
    moveTo(x, y);
    
    // 延迟一小段时间确保移动完成
    sleep(const Duration(milliseconds: 10));
    
    // 按下右键
    _mouseEvent(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, nullptr);
    
    // 延迟
    sleep(const Duration(milliseconds: 50));
    
    // 释放右键
    _mouseEvent(MOUSEEVENTF_RIGHTUP, 0, 0, 0, nullptr);
  }

  /// 双击指定坐标
  void doubleClick(int x, int y) {
    // 移动到指定位置
    moveTo(x, y);
    
    // 延迟一小段时间确保移动完成
    sleep(const Duration(milliseconds: 10));
    
    // 第一次点击
    _mouseEvent(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, nullptr);
    sleep(const Duration(milliseconds: 50));
    _mouseEvent(MOUSEEVENTF_LEFTUP, 0, 0, 0, nullptr);
    
    // 两次点击之间的间隔
    sleep(const Duration(milliseconds: 50));
    
    // 第二次点击
    _mouseEvent(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, nullptr);
    sleep(const Duration(milliseconds: 50));
    _mouseEvent(MOUSEEVENTF_LEFTUP, 0, 0, 0, nullptr);
  }
}
