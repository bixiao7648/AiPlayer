import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

class ScreenshotHelper {
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');
  static final DynamicLibrary _gdi32 = DynamicLibrary.open('gdi32.dll');

  // Windows API 常量
  static const int SRCCOPY = 0x00CC0020;
  static const int CAPTUREBLT = 0x40000000;
  static const int SM_CXSCREEN = 0;
  static const int SM_CYSCREEN = 1;
  static const int DIB_RGB_COLORS = 0;
  static const int BI_RGB = 0;

  // user32.dll 函数
  late final Function _getSystemMetrics = _user32.lookupFunction<
      Int32 Function(Int32 nIndex),
      int Function(int nIndex)>('GetSystemMetrics');

  late final Function _getDesktopWindow = _user32.lookupFunction<
      IntPtr Function(),
      int Function()>('GetDesktopWindow');

  late final Function _getDC = _user32.lookupFunction<
      IntPtr Function(IntPtr hWnd),
      int Function(int hWnd)>('GetDC');

  late final Function _releaseDC = _user32.lookupFunction<
      Int32 Function(IntPtr hWnd, IntPtr hDC),
      int Function(int hWnd, int hDC)>('ReleaseDC');

  // gdi32.dll 函数
  late final Function _createCompatibleDC = _gdi32.lookupFunction<
      IntPtr Function(IntPtr hdc),
      int Function(int hdc)>('CreateCompatibleDC');

  late final Function _createCompatibleBitmap = _gdi32.lookupFunction<
      IntPtr Function(IntPtr hdc, Int32 cx, Int32 cy),
      int Function(int hdc, int cx, int cy)>('CreateCompatibleBitmap');

  late final Function _selectObject = _gdi32.lookupFunction<
      IntPtr Function(IntPtr hdc, IntPtr h),
      int Function(int hdc, int h)>('SelectObject');

  late final Function _bitBlt = _gdi32.lookupFunction<
      Int32 Function(IntPtr hdcDest, Int32 xDest, Int32 yDest, Int32 w, Int32 h,
          IntPtr hdcSrc, Int32 xSrc, Int32 ySrc, Uint32 rop),
      int Function(int hdcDest, int xDest, int yDest, int w, int h,
          int hdcSrc, int xSrc, int ySrc, int rop)>('BitBlt');

  late final Function _getDIBits = _gdi32.lookupFunction<
      Int32 Function(IntPtr hdc, IntPtr hbm, Uint32 start, Uint32 cLines,
          Pointer lpvBits, Pointer lpbmi, Uint32 usage),
      int Function(int hdc, int hbm, int start, int cLines,
          Pointer lpvBits, Pointer lpbmi, int usage)>('GetDIBits');

  late final Function _deleteDC = _gdi32.lookupFunction<
      Int32 Function(IntPtr hdc),
      int Function(int hdc)>('DeleteDC');

  late final Function _deleteObject = _gdi32.lookupFunction<
      Int32 Function(IntPtr ho),
      int Function(int ho)>('DeleteObject');

  /// 获取屏幕宽度
  int getScreenWidth() {
    return _getSystemMetrics(SM_CXSCREEN);
  }

  /// 获取屏幕高度
  int getScreenHeight() {
    return _getSystemMetrics(SM_CYSCREEN);
  }

  /// 截取全屏并保存为 BMP 文件
  /// [filePath] 保存的文件路径，例如: "screenshot.bmp"
  /// 返回是否成功
  Future<bool> captureFullScreen(String filePath) async {
    try {
      final width = getScreenWidth();
      final height = getScreenHeight();
      return await captureScreen(0, 0, width, height, filePath);
    } catch (e) {
      print('截图失败: $e');
      return false;
    }
  }

  /// 截取指定区域并保存为 BMP 文件
  /// [x] 起始X坐标
  /// [y] 起始Y坐标
  /// [width] 宽度
  /// [height] 高度
  /// [filePath] 保存的文件路径
  /// 返回是否成功
  Future<bool> captureScreen(int x, int y, int width, int height, String filePath) async {
    int hDesktopWnd = 0;
    int hDesktopDC = 0;
    int hCaptureDC = 0;
    int hCaptureBitmap = 0;

    try {
      // 获取桌面窗口和DC
      hDesktopWnd = _getDesktopWindow();
      hDesktopDC = _getDC(hDesktopWnd);
      
      if (hDesktopDC == 0) {
        throw Exception('无法获取桌面DC');
      }

      // 创建兼容的DC和位图
      hCaptureDC = _createCompatibleDC(hDesktopDC);
      hCaptureBitmap = _createCompatibleBitmap(hDesktopDC, width, height);
      
      if (hCaptureDC == 0 || hCaptureBitmap == 0) {
        throw Exception('无法创建兼容DC或位图');
      }

      // 选择位图到DC
      _selectObject(hCaptureDC, hCaptureBitmap);

      // 复制屏幕内容到位图
      final result = _bitBlt(
        hCaptureDC, 0, 0, width, height,
        hDesktopDC, x, y,
        SRCCOPY | CAPTUREBLT
      );

      if (result == 0) {
        throw Exception('BitBlt 失败');
      }

      // 使用 ByteData 正确填充 BITMAPINFOHEADER 结构
      final pBmi = calloc<Uint8>(40);
      final bmiData = ByteData(40);
      
      // 填充 BITMAPINFOHEADER (40字节)
      bmiData.setUint32(0, 40, Endian.little);           // biSize
      bmiData.setInt32(4, width, Endian.little);         // biWidth
      bmiData.setInt32(8, -height, Endian.little);       // biHeight (负值=从上到下)
      bmiData.setUint16(12, 1, Endian.little);           // biPlanes
      bmiData.setUint16(14, 24, Endian.little);          // biBitCount (24位)
      bmiData.setUint32(16, BI_RGB, Endian.little);      // biCompression
      bmiData.setUint32(20, 0, Endian.little);           // biSizeImage
      bmiData.setInt32(24, 0, Endian.little);            // biXPelsPerMeter
      bmiData.setInt32(28, 0, Endian.little);            // biYPelsPerMeter
      bmiData.setUint32(32, 0, Endian.little);           // biClrUsed
      bmiData.setUint32(36, 0, Endian.little);           // biClrImportant
      
      // 将 ByteData 复制到 pBmi
      for (int i = 0; i < 40; i++) {
        pBmi[i] = bmiData.getUint8(i);
      }

      // 计算图像数据大小（每行需要4字节对齐）
      final rowSize = ((width * 3 + 3) ~/ 4) * 4;
      final imageSize = rowSize * height;
      final pBits = calloc<Uint8>(imageSize);

      // 获取位图数据
      final dibResult = _getDIBits(
        hCaptureDC,  // 改用 hCaptureDC 而不是 hDesktopDC
        hCaptureBitmap,
        0,
        height,
        pBits,
        pBmi,
        DIB_RGB_COLORS
      );

      if (dibResult == 0) {
        calloc.free(pBits);
        calloc.free(pBmi);
        throw Exception('GetDIBits 失败');
      }

      // 保存为 BMP 文件
      final file = File(filePath);
      final fileHeader = _createBMPFileHeader(width, height, imageSize);
      final bitmapInfo = Uint8List.view(pBmi.cast<Uint8>().asTypedList(40).buffer);
      final imageData = Uint8List.view(pBits.cast<Uint8>().asTypedList(imageSize).buffer);
      
      await file.writeAsBytes([
        ...fileHeader,
        ...bitmapInfo,
        ...imageData,
      ]);

      // 释放内存
      calloc.free(pBits);
      calloc.free(pBmi);

      print('截图成功保存: $filePath');
      return true;
    } catch (e) {
      print('截图过程出错: $e');
      return false;
    } finally {
      // 清理资源
      if (hCaptureBitmap != 0) _deleteObject(hCaptureBitmap);
      if (hCaptureDC != 0) _deleteDC(hCaptureDC);
      if (hDesktopDC != 0) _releaseDC(hDesktopWnd, hDesktopDC);
    }
  }

  /// 创建 BMP 文件头
  Uint8List _createBMPFileHeader(int width, int height, int imageSize) {
    final rowSize = ((width * 3 + 3) ~/ 4) * 4;
    final fileSize = 14 + 40 + rowSize * height; // 文件头 + 信息头 + 图像数据
    
    final header = ByteData(14);
    
    // 文件类型 "BM"
    header.setUint8(0, 0x42); // 'B'
    header.setUint8(1, 0x4D); // 'M'
    
    // 文件大小
    header.setUint32(2, fileSize, Endian.little);
    
    // 保留字段
    header.setUint16(6, 0, Endian.little);
    header.setUint16(8, 0, Endian.little);
    
    // 图像数据偏移
    header.setUint32(10, 54, Endian.little); // 14 + 40
    
    return header.buffer.asUint8List();
  }

  /// 截取指定窗口的截图（高级功能）
  /// 可以根据窗口句柄截取特定窗口
  Future<bool> captureWindow(int hWnd, String filePath) async {
    // 这里可以扩展实现窗口截图功能
    // 需要使用 GetWindowRect 获取窗口大小和位置
    // 本例中暂时不实现，可以后续扩展
    throw UnimplementedError('窗口截图功能暂未实现');
  }
}
