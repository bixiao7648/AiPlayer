import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

class KeyboardController {
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

  // 键盘事件常量
  static const int KEYEVENTF_EXTENDEDKEY = 0x0001;
  static const int KEYEVENTF_KEYUP = 0x0002;

  // keybd_event 函数
  late final Function _keybdEvent = _user32.lookupFunction<
      Void Function(Uint8 bVk, Uint8 bScan, Uint32 dwFlags, Pointer dwExtraInfo),
      void Function(int bVk, int bScan, int dwFlags, Pointer dwExtraInfo)>('keybd_event');

  /// 按下按键
  void _keyDown(int virtualKey) {
    _keybdEvent(virtualKey, 0, 0, nullptr);
  }

  /// 释放按键
  void _keyUp(int virtualKey) {
    _keybdEvent(virtualKey, 0, KEYEVENTF_KEYUP, nullptr);
  }

  /// 按下并释放单个按键
  void pressKey(int virtualKey, {int delayMs = 50}) {
    _keyDown(virtualKey);
    sleep(Duration(milliseconds: delayMs));
    _keyUp(virtualKey);
  }

  /// 输入单个字符（自动转换为虚拟键码）
  void typeChar(String char, {int delayMs = 50}) {
    if (char.isEmpty) return;
    
    int virtualKey = _charToVirtualKey(char[0]);
    bool needShift = _needShiftKey(char[0]);
    
    if (needShift) {
      _keyDown(VK.SHIFT);
      sleep(const Duration(milliseconds: 10));
    }
    
    _keyDown(virtualKey);
    sleep(Duration(milliseconds: delayMs));
    _keyUp(virtualKey);
    
    if (needShift) {
      sleep(const Duration(milliseconds: 10));
      _keyUp(VK.SHIFT);
    }
  }

  /// 连续输入字符串
  void typeText(String text, {int delayBetweenKeys = 50}) {
    for (int i = 0; i < text.length; i++) {
      typeChar(text[i], delayMs: delayBetweenKeys);
      if (i < text.length - 1) {
        sleep(Duration(milliseconds: delayBetweenKeys));
      }
    }
  }

  /// 同时按下多个键（组合键）
  /// 例如: pressKeyCombination([VK.CONTROL, VK.A]) 实现 Ctrl+A
  void pressKeyCombination(List<int> keys, {int holdMs = 100}) {
    if (keys.isEmpty) return;
    
    // 按下所有键
    for (int key in keys) {
      _keyDown(key);
      sleep(const Duration(milliseconds: 10));
    }
    
    // 保持按下状态
    sleep(Duration(milliseconds: holdMs));
    
    // 按相反顺序释放所有键
    for (int i = keys.length - 1; i >= 0; i--) {
      _keyUp(keys[i]);
      sleep(const Duration(milliseconds: 10));
    }
  }

  /// 判断字符是否需要 Shift 键
  bool _needShiftKey(String char) {
    if (char.isEmpty) return false;
    
    // 大写字母
    if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
      return true;
    }
    
    // 特殊字符需要 Shift
    const shiftChars = '~!@#\$%^&*()_+{}|:"<>?';
    return shiftChars.contains(char);
  }

  /// 将字符转换为虚拟键码
  int _charToVirtualKey(String char) {
    if (char.isEmpty) return 0;
    
    int code = char.toUpperCase().codeUnitAt(0);
    
    // A-Z
    if (code >= 65 && code <= 90) {
      return code;
    }
    
    // 0-9
    if (code >= 48 && code <= 57) {
      return code;
    }
    
    // 特殊字符映射
    switch (char) {
      case ' ': return VK.SPACE;
      case '\n': case '\r': return VK.RETURN;
      case '\t': return VK.TAB;
      case '`': case '~': return VK.OEM_3;
      case '-': case '_': return VK.OEM_MINUS;
      case '=': case '+': return VK.OEM_PLUS;
      case '[': case '{': return VK.OEM_4;
      case ']': case '}': return VK.OEM_6;
      case '\\': case '|': return VK.OEM_5;
      case ';': case ':': return VK.OEM_1;
      case '\'': case '"': return VK.OEM_7;
      case ',': case '<': return VK.OEM_COMMA;
      case '.': case '>': return VK.OEM_PERIOD;
      case '/': case '?': return VK.OEM_2;
      default: return 0;
    }
  }
}

/// Windows 虚拟键码常量
class VK {
  // 修饰键
  static const int SHIFT = 0x10;
  static const int CONTROL = 0x11;
  static const int ALT = 0x12;
  static const int LWIN = 0x5B;  // 左 Windows 键
  static const int RWIN = 0x5C;  // 右 Windows 键

  // 功能键
  static const int ESCAPE = 0x1B;
  static const int TAB = 0x09;
  static const int CAPITAL = 0x14;  // Caps Lock
  static const int SPACE = 0x20;
  static const int RETURN = 0x0D;  // Enter
  static const int BACK = 0x08;    // Backspace
  static const int DELETE = 0x2E;
  static const int INSERT = 0x2D;
  static const int HOME = 0x24;
  static const int END = 0x23;
  static const int PRIOR = 0x21;   // Page Up
  static const int NEXT = 0x22;    // Page Down

  // 方向键
  static const int LEFT = 0x25;
  static const int UP = 0x26;
  static const int RIGHT = 0x27;
  static const int DOWN = 0x28;

  // F1-F12
  static const int F1 = 0x70;
  static const int F2 = 0x71;
  static const int F3 = 0x72;
  static const int F4 = 0x73;
  static const int F5 = 0x74;
  static const int F6 = 0x75;
  static const int F7 = 0x76;
  static const int F8 = 0x77;
  static const int F9 = 0x78;
  static const int F10 = 0x79;
  static const int F11 = 0x7A;
  static const int F12 = 0x7B;

  // 数字键 0-9
  static const int NUM_0 = 0x30;
  static const int NUM_1 = 0x31;
  static const int NUM_2 = 0x32;
  static const int NUM_3 = 0x33;
  static const int NUM_4 = 0x34;
  static const int NUM_5 = 0x35;
  static const int NUM_6 = 0x36;
  static const int NUM_7 = 0x37;
  static const int NUM_8 = 0x38;
  static const int NUM_9 = 0x39;

  // 字母键 A-Z
  static const int A = 0x41;
  static const int B = 0x42;
  static const int C = 0x43;
  static const int D = 0x44;
  static const int E = 0x45;
  static const int F = 0x46;
  static const int G = 0x47;
  static const int H = 0x48;
  static const int I = 0x49;
  static const int J = 0x4A;
  static const int K = 0x4B;
  static const int L = 0x4C;
  static const int M = 0x4D;
  static const int N = 0x4E;
  static const int O = 0x4F;
  static const int P = 0x50;
  static const int Q = 0x51;
  static const int R = 0x52;
  static const int S = 0x53;
  static const int T = 0x54;
  static const int U = 0x55;
  static const int V = 0x56;
  static const int W = 0x57;
  static const int X = 0x58;
  static const int Y = 0x59;
  static const int Z = 0x5A;

  // OEM 键（特殊字符）
  static const int OEM_1 = 0xBA;      // ';:'
  static const int OEM_PLUS = 0xBB;   // '=+'
  static const int OEM_COMMA = 0xBC;  // ',<'
  static const int OEM_MINUS = 0xBD;  // '-_'
  static const int OEM_PERIOD = 0xBE; // '.>'
  static const int OEM_2 = 0xBF;      // '/?'
  static const int OEM_3 = 0xC0;      // '`~'
  static const int OEM_4 = 0xDB;      // '[{'
  static const int OEM_5 = 0xDC;      // '\|'
  static const int OEM_6 = 0xDD;      // ']}'
  static const int OEM_7 = 0xDE;      // ''"'

  // 小键盘
  static const int NUMPAD0 = 0x60;
  static const int NUMPAD1 = 0x61;
  static const int NUMPAD2 = 0x62;
  static const int NUMPAD3 = 0x63;
  static const int NUMPAD4 = 0x64;
  static const int NUMPAD5 = 0x65;
  static const int NUMPAD6 = 0x66;
  static const int NUMPAD7 = 0x67;
  static const int NUMPAD8 = 0x68;
  static const int NUMPAD9 = 0x69;
  static const int MULTIPLY = 0x6A;  // *
  static const int ADD = 0x6B;       // +
  static const int SUBTRACT = 0x6D;  // -
  static const int DECIMAL = 0x6E;   // .
  static const int DIVIDE = 0x6F;    // /
}
