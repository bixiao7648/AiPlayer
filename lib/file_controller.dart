import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// 文件操作控制器
/// 提供创建、修改和删除 txt 文件的功能
class FileController {
  /// 获取桌面路径
  String? _getDesktopPath() {
    if (Platform.isWindows) {
      // 尝试获取 USERPROFILE 环境变量
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return '$userProfile\\Desktop';
      }
      // 回退方案：如果环境变量不存在，尝试默认路径（这可能不准确）
      // return r'C:\Users\z\OneDrive\Desktop'; // 移除特定用户的硬编码
      return null;
    } else if (Platform.isMacOS) {
      // macOS: 使用 HOME 环境变量
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home${Platform.pathSeparator}Desktop';
      }
    } else if (Platform.isLinux) {
      // Linux: 使用 HOME 环境变量
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home${Platform.pathSeparator}Desktop';
      }
    }
    return null;
  }

  /// 获取桌面路径（公开方法）
  String? getDesktopPath() {
    return _getDesktopPath();
  }

  /// 创建文件（通用）
  /// 
  /// [fileName] 文件名（可以包含路径，如果不包含则保存到桌面）
  /// [content] 文件初始内容（可选）
  /// [saveToDesktop] 是否保存到桌面（默认为 true）
  /// 
  /// 返回创建的文件路径，失败返回 null
  Future<String?> createFile(
      String fileName, {
        String content = '',
        bool saveToDesktop = true,
      }) async {
    try {
      File file;

      // 如果 fileName 包含路径分隔符，使用绝对路径
      if (fileName.contains(Platform.pathSeparator)) {
        file = File(fileName);
      } else {
        if (saveToDesktop) {
          // 保存到桌面
          final desktopPath = _getDesktopPath();
          if (desktopPath == null) {
            // 如果无法获取桌面路径，回退到应用文档目录
            final directory = await getApplicationDocumentsDirectory();
            file = File('${directory.path}${Platform.pathSeparator}$fileName');
            print('警告：无法获取桌面路径，文件将保存到: ${file.path}');
          } else {
            file = File('$desktopPath${Platform.pathSeparator}$fileName');
          }
        } else {
          // 保存到应用文档目录
          final directory = await getApplicationDocumentsDirectory();
          file = File('${directory.path}${Platform.pathSeparator}$fileName');
        }
      }

      // 确保父目录存在
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // 检查文件是否已存在，如果存在则覆盖（或者可以加参数控制）
      // 这里为了简单，直接覆盖
      await file.writeAsString(content, encoding: utf8);
      print('文件创建成功: ${file.path}');
      return file.path;
    } catch (e) {
      print('创建文件失败: $e');
      return null;
    }
  }

  /// 创建新的 txt 文件
  /// 
  /// [fileName] 文件名（可以包含路径，如果不包含则保存到桌面）
  /// [content] 文件初始内容（可选）
  /// [saveToDesktop] 是否保存到桌面（默认为 true）
  /// 
  /// 返回创建的文件路径，失败返回 null
  Future<String?> createTxtFile(
      String fileName, {
        String content = '',
        bool saveToDesktop = true,
      }) async {
    try {
      // 确保文件名以 .txt 结尾
      if (!fileName.toLowerCase().endsWith('.txt')) {
        fileName = '$fileName.txt';
      }

      File file;

      // 如果 fileName 包含路径分隔符，使用绝对路径
      if (fileName.contains(Platform.pathSeparator)) {
        file = File(fileName);
      } else {
        if (saveToDesktop) {
          // 保存到桌面
          final desktopPath = _getDesktopPath();
          if (desktopPath == null) {
            // 如果无法获取桌面路径，回退到应用文档目录
            final directory = await getApplicationDocumentsDirectory();
            file = File('${directory.path}${Platform.pathSeparator}$fileName');
            print('警告：无法获取桌面路径，文件将保存到: ${file.path}');
          } else {
            file = File('$desktopPath${Platform.pathSeparator}$fileName');
          }
        } else {
          // 保存到应用文档目录
          final directory = await getApplicationDocumentsDirectory();
          file = File('${directory.path}${Platform.pathSeparator}$fileName');
        }
      }

      // 确保父目录存在
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // 检查文件是否已存在
      if (await file.exists()) {
        print('文件已存在: ${file.path}');
        return file.path;
      }

      // 创建并写入内容
      await file.writeAsString(content, encoding: utf8);
      print('文件创建成功: ${file.path}');
      return file.path;
    } catch (e) {
      print('创建文件失败: $e');
      return null;
    }
  }

  /// 修改指定的 txt 文件
  /// 
  /// [filePath] 文件路径
  /// [content] 新的文件内容（如果为 null，则追加内容）
  /// [append] 是否追加内容（默认为 false，即覆盖）
  /// [appendContent] 要追加的内容（仅在 append 为 true 时使用）
  /// 
  /// 返回是否成功
  Future<bool> modifyTxtFile(
      String filePath, {
        String? content,
        bool append = false,
        String? appendContent,
      }) async {
    try {
      final file = File(filePath);

      // 检查文件是否存在
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return false;
      }

      if (append && appendContent != null) {
        // 追加模式：在文件末尾添加内容
        await file.writeAsString(
          appendContent,
          mode: FileMode.append,
          encoding: utf8,
        );
        print('文件内容已追加: $filePath');
      } else if (content != null) {
        // 覆盖模式：替换整个文件内容
        await file.writeAsString(content, encoding: utf8);
        print('文件内容已修改: $filePath');
      } else {
        print('未提供要写入的内容');
        return false;
      }

      return true;
    } catch (e) {
      print('修改文件失败: $e');
      return false;
    }
  }

  /// 删除指定的 txt 文件
  /// 
  /// [filePath] 文件路径
  /// 
  /// 返回是否成功
  Future<bool> deleteTxtFile(String filePath) async {
    try {
      final file = File(filePath);

      // 检查文件是否存在
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return false;
      }

      // 删除文件
      await file.delete();
      print('文件删除成功: $filePath');
      return true;
    } catch (e) {
      print('删除文件失败: $e');
      return false;
    }
  }

  /// 读取 txt 文件内容
  /// 
  /// [filePath] 文件路径
  /// 
  /// 返回文件内容，失败返回 null
  Future<String?> readTxtFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return null;
      }

      final content = await file.readAsString(encoding: utf8);
      return content;
    } catch (e) {
      print('读取文件失败: $e');
      return null;
    }
  }

  /// 检查文件是否存在
  /// 
  /// [filePath] 文件路径
  /// 
  /// 返回文件是否存在
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('检查文件存在性失败: $e');
      return false;
    }
  }
}
