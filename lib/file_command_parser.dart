import 'file_controller.dart';
import 'dart:io';

/// 文件操作指令解析器
/// 解析自然语言指令并执行相应的文件操作
class FileCommandParser {
  final FileController _fileController = FileController();

  /// 获取桌面路径（辅助方法）
  String? _getDesktopPath() {
    if (Platform.isWindows) {
      // 使用指定的 OneDrive 桌面路径
      return r'C:\Users\z\OneDrive\Desktop';
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home${Platform.pathSeparator}Desktop';
      }
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home${Platform.pathSeparator}Desktop';
      }
    }
    return null;
  }

  /// 解析并执行指令
  /// 
  /// 支持的指令格式：
  /// - "生成一个内容为'xxx'的txt文件"
  /// - "创建一个名为xxx的txt文件"
  /// - "创建一个名为xxx内容为yyy的txt文件"
  /// - "生成文件名为test.txt，内容为hello world"
  /// - "修改xxx.txt文件，内容为yyy"
  /// - "删除xxx.txt文件"
  /// 
  /// [selectedFilePath] 已选择的文件路径（可选）
  /// 
  /// 返回执行结果消息
  Future<String> parseAndExecute(String command, {String? selectedFilePath}) async {
    try {
      final lowerCommand = command.toLowerCase().trim();

      // 解析创建文件指令
      if (lowerCommand.contains('生成') || 
          lowerCommand.contains('创建') || 
          lowerCommand.contains('新建') ||
          lowerCommand.contains('建立')) {
        return await _handleCreateCommand(command);
      }

      // 解析修改文件指令
      if (lowerCommand.contains('修改') || 
          lowerCommand.contains('更新') || 
          lowerCommand.contains('编辑') ||
          lowerCommand.contains('改写') ||
          lowerCommand.contains('改为') ||
          lowerCommand.contains('改成')) {
        return await _handleModifyCommand(command, selectedFilePath: selectedFilePath);
      }

      // 解析删除文件指令
      if (lowerCommand.contains('删除') || 
          lowerCommand.contains('移除') || 
          lowerCommand.contains('去掉') ||
          lowerCommand.contains('清除')) {
        return await _handleDeleteCommand(command, selectedFilePath: selectedFilePath);
      }

      return '无法识别指令，请使用以下格式：\n'
          '• 生成一个内容为"xxx"的txt文件\n'
          '• 创建一个名为xxx的txt文件\n'
          '• 生成文件名为test.txt，内容为hello world\n'
          '• 修改xxx.txt文件，内容为yyy\n'
          '• 删除xxx.txt文件';
    } catch (e) {
      return '执行指令时出错: $e';
    }
  }

  /// 处理创建文件指令
  Future<String> _handleCreateCommand(String command) async {
    String? fileName;
    String content = '';

    // 首先提取所有双引号中的内容（只提取引号内的文字，不包含引号本身）
    final allQuotedTexts = <String>[];
    // 匹配英文双引号 "xxx"
    final englishQuotePattern = RegExp(r'"([^"]+)"');
    // 匹配中文双引号 "xxx"
    final chineseQuotePattern = RegExp(r'"([^"]+)"');
    
    // 提取所有英文双引号中的内容
    final englishMatches = englishQuotePattern.allMatches(command);
    for (var match in englishMatches) {
      allQuotedTexts.add(match.group(1)!);
    }
    
    // 提取所有中文双引号中的内容
    final chineseMatches = chineseQuotePattern.allMatches(command);
    for (var match in chineseMatches) {
      allQuotedTexts.add(match.group(1)!);
    }

    // 如果找到双引号内容，优先使用它们
    if (allQuotedTexts.isNotEmpty) {
      // 查找"名为"或"文件名"后面的第一个双引号内容作为文件名
      final nameIndex = command.toLowerCase().indexOf('名为');
      final fileNameIndex = command.toLowerCase().indexOf('文件名');
      final nameKeywordIndex = nameIndex != -1 
          ? (fileNameIndex != -1 ? (nameIndex < fileNameIndex ? nameIndex : fileNameIndex) : nameIndex)
          : fileNameIndex;

      if (nameKeywordIndex != -1) {
        // 找到"名为"或"文件名"后面的第一个双引号（英文或中文）
        final afterNameKeyword = command.substring(nameKeywordIndex);
        final firstQuoteAfterName = englishQuotePattern.firstMatch(afterNameKeyword) ?? 
                                    chineseQuotePattern.firstMatch(afterNameKeyword);
        if (firstQuoteAfterName != null) {
          fileName = firstQuoteAfterName.group(1);
        }
      }

      // 查找"内容为"或"内容是"后面的第一个双引号内容作为文件内容
      final contentIndex = command.toLowerCase().indexOf('内容');
      if (contentIndex != -1) {
        final afterContent = command.substring(contentIndex);
        final firstQuoteAfterContent = englishQuotePattern.firstMatch(afterContent) ?? 
                                      chineseQuotePattern.firstMatch(afterContent);
        if (firstQuoteAfterContent != null) {
          content = firstQuoteAfterContent.group(1)!;
        }
      }

      // 如果只找到一个双引号内容，需要根据上下文判断
      if (allQuotedTexts.length == 1) {
        final singleQuote = allQuotedTexts[0];
        // 判断这个引号更靠近"名为"还是"内容为"
        final nameKeywordPos = nameKeywordIndex != -1 ? nameKeywordIndex : -1;
        final contentKeywordPos = contentIndex != -1 ? contentIndex : -1;
        
        if (nameKeywordPos != -1 && contentKeywordPos != -1) {
          // 找到引号在原文中的位置
          final quotePos = command.indexOf('"$singleQuote"');
          final quotePosChinese = command.indexOf('"$singleQuote"');
          final actualQuotePos = quotePos != -1 ? quotePos : quotePosChinese;
          
          if (actualQuotePos != -1) {
            final distToName = (actualQuotePos - nameKeywordPos).abs();
            final distToContent = (actualQuotePos - contentKeywordPos).abs();
            if (distToName < distToContent) {
              fileName = singleQuote;
            } else {
              content = singleQuote;
            }
          }
        } else if (nameKeywordPos != -1) {
          fileName = singleQuote;
        } else if (contentKeywordPos != -1) {
          content = singleQuote;
        }
      }

      // 如果找到两个或更多双引号内容，根据上下文分配
      if (allQuotedTexts.length >= 2) {
        // 如果还没有确定文件名和内容，按顺序分配
        if (fileName == null && content.isEmpty) {
          // 找到第一个引号的位置，判断它更靠近哪个关键词
          final firstQuoteText = allQuotedTexts[0];
          final firstQuotePos = command.indexOf('"$firstQuoteText"');
          final firstQuotePosChinese = command.indexOf('"$firstQuoteText"');
          final actualFirstPos = firstQuotePos != -1 ? firstQuotePos : firstQuotePosChinese;
          
          final nameKeywordPos = nameKeywordIndex != -1 ? nameKeywordIndex : -1;
          final contentKeywordPos = contentIndex != -1 ? contentIndex : -1;
          
          if (actualFirstPos != -1 && nameKeywordPos != -1 && contentKeywordPos != -1) {
            final distToName = (actualFirstPos - nameKeywordPos).abs();
            final distToContent = (actualFirstPos - contentKeywordPos).abs();
            if (distToName < distToContent) {
              fileName = allQuotedTexts[0];
              content = allQuotedTexts[1];
            } else {
              content = allQuotedTexts[0];
              fileName = allQuotedTexts[1];
            }
          } else {
            // 默认第一个是文件名，第二个是内容
            fileName = allQuotedTexts[0];
            content = allQuotedTexts[1];
          }
        } else if (fileName == null) {
          fileName = allQuotedTexts[0];
        } else if (content.isEmpty) {
          content = allQuotedTexts[1];
        }
      }
    }

    // 如果没有从双引号中提取到文件名，尝试其他方法
    if (fileName == null || fileName.isEmpty) {
      // 尝试匹配"名为xxx"格式（不带引号）
      final namePatterns = [
        RegExp(r'名为[《""]?([^《""》\s，,。.]+)[》""]?', caseSensitive: false),
        RegExp(r'文件名[是为]?[《""]?([^《""》\s，,。.]+)[》""]?', caseSensitive: false),
      ];

      for (var pattern in namePatterns) {
        final match = pattern.firstMatch(command);
        if (match != null) {
          final extracted = match.group(1);
          if (extracted != null && !extracted.contains('"') && !extracted.contains('"')) {
            fileName = extracted.replaceAll(RegExp(r'[，,。.]+$'), '');
            if (fileName.isNotEmpty) {
              break;
            }
          }
        }
      }
    }

    // 如果没有从双引号中提取到内容，尝试其他方法
    if (content.isEmpty) {
      // 尝试匹配"内容为xxx"格式（不带引号）
      final contentPattern = RegExp(
        r'内容[是为]?[:：]?\s*([^，,。.\n""]+)',
        caseSensitive: false,
      );
      final contentMatch = contentPattern.firstMatch(command);
      if (contentMatch != null) {
        final extracted = contentMatch.group(1)?.trim();
        if (extracted != null && 
            !extracted.contains('"') && 
            !extracted.contains('"') &&
            !extracted.contains('名为') && 
            !extracted.contains('文件名')) {
          content = extracted;
        }
      }
    }

    // 如果没有指定文件名，使用默认名称
    if (fileName == null || fileName.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = 'file_$timestamp';
    }

    // 清理文件名（移除可能的.txt后缀，因为后面会自动添加）
    if (fileName != null && fileName.toLowerCase().endsWith('.txt')) {
      fileName = fileName.substring(0, fileName.length - 4);
    }

    // 执行创建操作
    final filePath = await _fileController.createTxtFile(
      fileName!,
      content: content,
      saveToDesktop: true,
    );

    if (filePath != null) {
      return '✓ 文件创建成功！\n'
          '文件名: ${fileName.endsWith('.txt') ? fileName : '$fileName.txt'}\n'
          '路径: $filePath\n'
          '内容: ${content.isEmpty ? "(空)" : content}';
    } else {
      return '✗ 文件创建失败，请检查权限或路径';
    }
  }

  /// 处理修改文件指令
  Future<String> _handleModifyCommand(String command, {String? selectedFilePath}) async {
    // 提取文件名 - 支持多种格式
    String? fileName;
    
    // 如果提供了已选择的文件路径，优先使用（这是最重要的）
    if (selectedFilePath != null && selectedFilePath.isNotEmpty) {
      final file = File(selectedFilePath);
      if (await file.exists()) {
        fileName = selectedFilePath;
        // 如果文件存在，直接使用这个路径，不需要继续解析命令
      } else {
        print('警告：已选择的文件不存在: $selectedFilePath');
      }
    }
    
    // 定义正则表达式模式（在方法开始处定义，以便在整个方法中使用）
    final englishQuotePattern = RegExp(r'"([^"]+)"');
    final chineseQuotePattern = RegExp(r'"([^"]+)"');
    
    // 只有在没有已选择文件路径时，才从命令中解析
    if (fileName == null) {
      // 优先检查是否包含完整文件路径（Windows路径格式）
      final windowsPathPattern = RegExp(r'([A-Za-z]:[\\/][^\s，,。.""]+)', caseSensitive: false);
      final pathMatch = windowsPathPattern.firstMatch(command);
      if (pathMatch != null) {
        final fullPath = pathMatch.group(1);
        if (fullPath != null) {
          final file = File(fullPath);
          if (await file.exists()) {
            fileName = fullPath;
          }
        }
      }
      
      // 优先提取双引号中的文件名（只提取引号内的内容）
      if (fileName == null) {
        final nameIndex = command.toLowerCase().indexOf('名为');
        if (nameIndex != -1) {
          final afterName = command.substring(nameIndex);
          final nameMatch = englishQuotePattern.firstMatch(afterName) ?? 
                           chineseQuotePattern.firstMatch(afterName);
          if (nameMatch != null) {
            fileName = nameMatch.group(1);
            // 检查是否是完整路径
            if (fileName != null && !fileName.contains(Platform.pathSeparator)) {
              if (!fileName.toLowerCase().endsWith('.txt')) {
                fileName = '$fileName.txt';
              }
              // 如果不是完整路径，尝试在桌面查找
              if (selectedFilePath != null) {
                // 如果已选择的文件名匹配，使用已选择的文件路径
                final selectedFileName = selectedFilePath.split(Platform.pathSeparator).last;
                if (selectedFileName.toLowerCase() == fileName!.toLowerCase()) {
                  fileName = selectedFilePath;
                } else {
                  // 尝试在桌面路径查找
                  final desktopPath = _getDesktopPath();
                  if (desktopPath != null) {
                    final desktopFile = File('$desktopPath${Platform.pathSeparator}$fileName');
                    if (await desktopFile.exists()) {
                      fileName = desktopFile.path;
                    }
                  }
                }
              } else {
                // 尝试在桌面路径查找
                final desktopPath = _getDesktopPath();
                if (desktopPath != null) {
                  final desktopFile = File('$desktopPath${Platform.pathSeparator}$fileName');
                  if (await desktopFile.exists()) {
                    fileName = desktopFile.path;
                  }
                }
              }
            }
          }
        }
      }
      
      // 方法1: 匹配 xxx.txt 格式
      if (fileName == null) {
        final filePattern1 = RegExp(r'([^\s，,。.]+\.txt)', caseSensitive: false);
        final match1 = filePattern1.firstMatch(command);
        if (match1 != null) {
          final extractedFileName = match1.group(1);
          if (extractedFileName != null) {
            // 如果已选择文件且文件名匹配，使用已选择的路径
            if (selectedFilePath != null) {
              final selectedFileName = selectedFilePath.split(Platform.pathSeparator).last;
              if (selectedFileName.toLowerCase() == extractedFileName.toLowerCase()) {
                fileName = selectedFilePath;
              } else {
                // 尝试在桌面查找
                final desktopPath = _getDesktopPath();
                if (desktopPath != null) {
                  final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                  if (await desktopFile.exists()) {
                    fileName = desktopFile.path;
                  } else {
                    fileName = extractedFileName;
                  }
                } else {
                  fileName = extractedFileName;
                }
              }
            } else {
              // 尝试在桌面查找
              final desktopPath = _getDesktopPath();
              if (desktopPath != null) {
                final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                if (await desktopFile.exists()) {
                  fileName = desktopFile.path;
                } else {
                  fileName = extractedFileName;
                }
              } else {
                fileName = extractedFileName;
              }
            }
          }
        }
      }
      
      // 方法2: 匹配"名为xxx"或"文件名xxx"（不带引号）
      if (fileName == null) {
        final namePattern = RegExp(
          r'(?:名为|文件名|文件名为)[《""]?([^《""》\s，,。.]+)[》""]?',
          caseSensitive: false,
        );
        final nameMatch = namePattern.firstMatch(command);
        if (nameMatch != null) {
          var extractedFileName = nameMatch.group(1);
          if (extractedFileName != null) {
            if (!extractedFileName.toLowerCase().endsWith('.txt')) {
              extractedFileName = '$extractedFileName.txt';
            }
            // 如果已选择文件且文件名匹配，使用已选择的路径
            if (selectedFilePath != null) {
              final selectedFileName = selectedFilePath.split(Platform.pathSeparator).last;
              if (selectedFileName.toLowerCase() == extractedFileName.toLowerCase()) {
                fileName = selectedFilePath;
              } else {
                // 尝试在桌面查找
                final desktopPath = _getDesktopPath();
                if (desktopPath != null) {
                  final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                  if (await desktopFile.exists()) {
                    fileName = desktopFile.path;
                  } else {
                    fileName = extractedFileName;
                  }
                } else {
                  fileName = extractedFileName;
                }
              }
            } else {
              // 尝试在桌面查找
              final desktopPath = _getDesktopPath();
              if (desktopPath != null) {
                final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                if (await desktopFile.exists()) {
                  fileName = desktopFile.path;
                } else {
                  fileName = extractedFileName;
                }
              } else {
                fileName = extractedFileName;
              }
            }
          }
        }
      }
    }

    if (fileName == null) {
      return '✗ 未找到文件名，请使用格式：修改xxx.txt文件，内容为yyy';
    }

    // 提取内容 - 优先提取双引号中的内容（只提取引号内的内容）
    String? content;
    
    // 支持"改为"、"改成"等表达方式
    final contentKeywords = ['内容为', '内容是', '改为', '改成', '内容'];
    int? contentIndex;
    for (var keyword in contentKeywords) {
      final index = command.toLowerCase().indexOf(keyword);
      if (index != -1) {
        contentIndex = index;
        break;
      }
    }
    
    if (contentIndex != null) {
      final afterContent = command.substring(contentIndex);
      final contentMatch = englishQuotePattern.firstMatch(afterContent) ?? 
                          chineseQuotePattern.firstMatch(afterContent);
      if (contentMatch != null) {
        content = contentMatch.group(1);
      } else {
        // 如果没有引号，提取"改为"或"改成"后面的内容
        final keywordMatch = RegExp(r'(?:改为|改成|内容为|内容是|内容)[:：]?\s*').firstMatch(afterContent);
        if (keywordMatch != null) {
          final afterKeyword = afterContent.substring(keywordMatch.end);
          if (afterKeyword.isNotEmpty) {
            content = afterKeyword.trim();
          }
        }
      }
    }
    
    // 如果没有找到带引号的内容，尝试其他格式
    if (content == null || content.isEmpty) {
      final quotedContentPatterns = [
        RegExp(r"内容[是为]?['""]([^'""]+)['""]", caseSensitive: false),
        RegExp(r"内容[是为]?[《""]([^《""》]+)[》""]", caseSensitive: false),
        RegExp(r'改为[《""]?([^《""》]+)[》""]?', caseSensitive: false),
        RegExp(r'改成[《""]?([^《""》]+)[》""]?', caseSensitive: false),
      ];
      
      for (var pattern in quotedContentPatterns) {
        final match = pattern.firstMatch(command);
        if (match != null) {
          content = match.group(1);
          break;
        }
      }
    }

    // 如果还是没有找到，尝试不带引号的格式
    if (content == null || content.isEmpty) {
      final contentPattern = RegExp(
        r'(?:内容[是为]?|改为|改成)[:：]?\s*([^，,。.\n""]+)',
        caseSensitive: false,
      );
      final contentMatch = contentPattern.firstMatch(command);
      if (contentMatch != null) {
        content = contentMatch.group(1)?.trim();
      }
    }

    if (content == null || content.isEmpty) {
      return '✗ 未找到要写入的内容，请使用格式：修改xxx.txt文件，内容为yyy';
    }

    // 执行修改操作
    final success = await _fileController.modifyTxtFile(
      fileName!,
      content: content,
    );

    if (success) {
      return '✓ 文件修改成功！\n'
          '文件名: ${fileName.split(Platform.pathSeparator).last}\n'
          '路径: $fileName\n'
          '新内容: $content';
    } else {
      return '✗ 文件修改失败，请检查文件是否存在\n'
          '尝试的文件路径: $fileName';
    }
  }

  /// 处理删除文件指令
  Future<String> _handleDeleteCommand(String command, {String? selectedFilePath}) async {
    // 提取文件名 - 支持多种格式
    String? fileName;
    
    // 如果提供了已选择的文件路径，优先使用（这是最重要的）
    if (selectedFilePath != null && selectedFilePath.isNotEmpty) {
      final file = File(selectedFilePath);
      if (await file.exists()) {
        fileName = selectedFilePath;
        // 如果文件存在，直接使用这个路径，不需要继续解析命令
      } else {
        print('警告：已选择的文件不存在: $selectedFilePath');
      }
    }
    
    // 只有在没有已选择文件路径时，才从命令中解析
    if (fileName == null) {
      // 优先检查是否包含完整文件路径（Windows路径格式）
      final windowsPathPattern = RegExp(r'([A-Za-z]:[\\/][^\s，,。.""]+)', caseSensitive: false);
      final pathMatch = windowsPathPattern.firstMatch(command);
      if (pathMatch != null) {
        final fullPath = pathMatch.group(1);
        if (fullPath != null) {
          final file = File(fullPath);
          if (await file.exists()) {
            fileName = fullPath;
          }
        }
      }
    }
    
    // 方法1: 匹配 xxx.txt 格式
    if (fileName == null) {
      final filePattern1 = RegExp(r'([^\s，,。.]+\.txt)', caseSensitive: false);
      final match1 = filePattern1.firstMatch(command);
      if (match1 != null) {
        final extractedFileName = match1.group(1);
        if (extractedFileName != null) {
          // 如果已选择文件且文件名匹配，使用已选择的路径
          if (selectedFilePath != null) {
            final selectedFileName = selectedFilePath.split(Platform.pathSeparator).last;
            if (selectedFileName.toLowerCase() == extractedFileName.toLowerCase()) {
              fileName = selectedFilePath;
            } else {
              // 尝试在桌面查找
              final desktopPath = _getDesktopPath();
              if (desktopPath != null) {
                final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                if (await desktopFile.exists()) {
                  fileName = desktopFile.path;
                } else {
                  fileName = extractedFileName;
                }
              } else {
                fileName = extractedFileName;
              }
            }
          } else {
            // 尝试在桌面查找
            final desktopPath = _getDesktopPath();
            if (desktopPath != null) {
              final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
              if (await desktopFile.exists()) {
                fileName = desktopFile.path;
              } else {
                fileName = extractedFileName;
              }
            } else {
              fileName = extractedFileName;
            }
          }
        }
      }
    }
    
    // 方法2: 匹配"名为xxx"或"文件名xxx"（不带引号）
    if (fileName == null) {
      final namePattern = RegExp(
        r'(?:名为|文件名|文件名为)[《""]?([^《""》\s，,。.]+)[》""]?',
        caseSensitive: false,
      );
      final nameMatch = namePattern.firstMatch(command);
      if (nameMatch != null) {
        var extractedFileName = nameMatch.group(1);
        if (extractedFileName != null) {
          if (!extractedFileName.toLowerCase().endsWith('.txt')) {
            extractedFileName = '$extractedFileName.txt';
          }
          // 如果已选择文件且文件名匹配，使用已选择的路径
          if (selectedFilePath != null) {
            final selectedFileName = selectedFilePath.split(Platform.pathSeparator).last;
            if (selectedFileName.toLowerCase() == extractedFileName.toLowerCase()) {
              fileName = selectedFilePath;
            } else {
              // 尝试在桌面查找
              final desktopPath = _getDesktopPath();
              if (desktopPath != null) {
                final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
                if (await desktopFile.exists()) {
                  fileName = desktopFile.path;
                } else {
                  fileName = extractedFileName;
                }
              } else {
                fileName = extractedFileName;
              }
            }
          } else {
            // 尝试在桌面查找
            final desktopPath = _getDesktopPath();
            if (desktopPath != null) {
              final desktopFile = File('$desktopPath${Platform.pathSeparator}$extractedFileName');
              if (await desktopFile.exists()) {
                fileName = desktopFile.path;
              } else {
                fileName = extractedFileName;
              }
            } else {
              fileName = extractedFileName;
            }
          }
        }
      }
    }
    
    if (fileName == null) {
      return '✗ 未找到文件名，请使用格式：删除xxx.txt文件\n'
          '提示：请先选择文件，或直接在指令中指定文件名';
    }

    // 执行删除操作
    final success = await _fileController.deleteTxtFile(fileName!);

    if (success) {
      return '✓ 文件删除成功！\n'
          '文件名: ${fileName.split(Platform.pathSeparator).last}\n'
          '路径: $fileName';
    } else {
      return '✗ 文件删除失败，请检查文件是否存在\n'
          '尝试的文件路径: $fileName';
    }
  }
}
