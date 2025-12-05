import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img; // 引入 image 库
import 'package:path_provider/path_provider.dart'; // 需要 path_provider

class AnalysisModule {
  // Dify API 配置
  static const String _apiKey = 'app-5LrdPZcsaJYZXfATF05O4A7k';
  static const String _baseUrl = 'https://api.dify.ai/v1';
  
  static final String _userId = 'flutter-user-fixed-id'; 

  String? _conversationId;
  
  /// 压缩图片并转换为 JPG
  /// 返回压缩后的临时文件路径
  Future<String?> compressImage(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return null;

      // 读取图片
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes); // 自动识别 BMP, PNG, JPG 等
      
      if (image == null) return null;
      
      // 调整大小：如果宽度超过 1024，则等比缩小（Dify/Claude 对超大图处理较慢且费 Token）
      img.Image resized = image;
      if (image.width > 1024) {
        resized = img.copyResize(image, width: 1024);
      }
      
      // 转换为 JPG 格式，质量 80
      final jpgBytes = img.encodeJpg(resized, quality: 80);
      
      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/upload_temp_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(jpgBytes);
      
      print('图片压缩完成: ${(file.lengthSync()/1024).toStringAsFixed(1)}KB -> ${(tempFile.lengthSync()/1024).toStringAsFixed(1)}KB');
      
      return tempPath;
    } catch (e) {
      print('图片压缩失败: $e');
      // 压缩失败则返回原路径（作为降级方案）
      return sourcePath;
    }
  }

  /// 上传文件到 Dify
  Future<Map<String, dynamic>?> uploadFile(String filePath, String user) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return null;
      }

      // 检查文件大小（限制 10MB）
      if (await file.length() > 10 * 1024 * 1024) {
        print('文件过大，请先压缩');
        return null;
      }

      final url = Uri.parse('$_baseUrl/files/upload');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $_apiKey';
      
      // 自动判断 MIME 类型
      String mimeType = 'image/jpeg';
      if (filePath.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filePath.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (filePath.toLowerCase().endsWith('.bmp')) {
        mimeType = 'image/bmp';
      } else if (filePath.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      final mimeTypeParts = mimeType.split('/');

      // 添加文件
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
      ));
      
      request.fields['user'] = user;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('文件上传成功: $data');
        return data;
      } else {
        print('文件上传失败: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('文件上传错误: $e');
      return null;
    }
  }

  /// 发送带图片的消息（包含自动压缩）
  Future<String> sendMessageWithImage(String message, String imagePath) async {
    // 1. 先尝试压缩/转换图片
    String finalPath = imagePath;
    final compressedPath = await compressImage(imagePath);
    if (compressedPath != null) {
      finalPath = compressedPath;
    }

    // 2. 上传处理后的文件
    final uploadResult = await uploadFile(finalPath, _userId);
    
    if (uploadResult == null) {
      return '图片上传失败，请重试';
    }
    
    // 3. 构造文件信息
    final files = [
      {
        'type': 'image',
        'transfer_method': 'local_file',
        'upload_file_id': uploadResult['id'],
      }
    ];
    
    // 4. 发送消息
    return await sendMessage(message, files: files);
  }

  /// 发送消息基础方法
  Future<String> sendMessage(
    String message, {
    List<Map<String, dynamic>>? files,
  }) async {
    if (message.trim().isEmpty && (files == null || files.isEmpty)) {
      return '请输入问题';
    }

    // 重试机制：最多重试 3 次
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$_baseUrl/chat-messages');
        
        final requestBody = {
          'inputs': {},
          'query': message,
          'response_mode': 'blocking',
          'user': _userId,
        };
        
        if (files != null && files.isNotEmpty) {
          requestBody['files'] = files;
        }
        
        if (_conversationId != null && _conversationId!.isNotEmpty) {
          requestBody['conversation_id'] = _conversationId!;
        }
        
        // 创建一个新的 client 实例以避免 Keep-Alive 问题
        final client = http.Client();
        http.Response response;
        
        try {
          response = await client.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'Connection': 'close', // 明确要求不保持连接，避免复用导致的关闭
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 30)); // 增加超时设置
        } finally {
          client.close();
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          
          if (data['conversation_id'] != null) {
            _conversationId = data['conversation_id'];
          }
          
          if (data['answer'] != null) {
            return data['answer'];
          } else {
            return '未收到回复';
          }
        } else {
          // 如果是 500, 502, 503, 504 错误，尝试重试
          if ([500, 502, 503, 504].contains(response.statusCode)) {
             retryCount++;
             print('服务器错误 (${response.statusCode})，正在重试 ($retryCount/$maxRetries)...');
             await Future.delayed(Duration(seconds: retryCount)); // 指数退避
             continue;
          }

          if (response.statusCode == 404) {
            _conversationId = null;
             return '会话已失效，请重试';
          }
          
          // 尝试解析错误信息
          try {
             final errorData = jsonDecode(utf8.decode(response.bodyBytes));
             return '请求失败 (${response.statusCode}): ${errorData['message'] ?? response.body}';
          } catch (e) {
             return '请求失败 (${response.statusCode}): ${response.body}';
          }
        }
      } catch (e) {
        // 捕获网络异常
        print('请求异常: $e');
        
        // 检查是否是连接中断异常
        bool shouldRetry = e.toString().contains('Connection closed') || 
                          e.toString().contains('Connection reset') ||
                          e.toString().contains('ClientException') ||
                          e.toString().contains('SocketException') ||
                          e.toString().contains('TimeoutException');

        if (shouldRetry && retryCount < maxRetries - 1) {
          retryCount++;
          print('捕获到网络异常，正在重试 ($retryCount/$maxRetries)...');
          await Future.delayed(Duration(seconds: retryCount * 2)); // 稍微长一点的延迟
          continue;
        }

        if (retryCount >= maxRetries - 1) {
           return '网络请求失败，已重试 $maxRetries 次: ${e.toString().split('\n').first}';
        }
        
        return '发生错误: $e';
      }
    }
    return '请求失败，请稍后重试';
  }

  void clearConversation() {
    _conversationId = null;
  }

  /// 上传文档到 Dify 知识库 (Dataset)
  /// 
  /// [filePath] 本地文件路径
  /// [datasetId] 知识库 ID (UUID)
  /// [datasetApiKey] 知识库的 API Key (注意：通常与 App API Key 不同)
  /// [indexingTechnique] 索引方式：'high_quality' (高质量) 或 'economy' (经济)
  Future<Map<String, dynamic>?> uploadDocumentToDataset({
    required String filePath,
    required String datasetId,
    required String datasetApiKey,
    String indexingTechnique = 'economy', 
    String processRuleMode = 'automatic', // automatic 或 custom
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('文件不存在: $filePath');
        return null;
      }

      // 知识库文档创建接口
      final url = Uri.parse('$_baseUrl/datasets/$datasetId/document/create_by_file');
      
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $datasetApiKey';
      
      // 构造 data 参数 (JSON 字符串)
      // 文档：https://docs.dify.ai/v/zh-hans/guides/knowledge-base/create-document
      final dataParams = {
        'indexing_technique': indexingTechnique,
        'process_rule': {
          'mode': processRuleMode,
          'rules': {} // 如果是 custom 模式，这里需要更多配置
        }
      };
      request.fields['data'] = jsonEncode(dataParams);

      // 获取 MIME 类型
      String mimeType = _getMimeType(filePath);
      final mimeTypeParts = mimeType.split('/');

      // 添加文件
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
      ));

      print('开始上传文件到知识库: $datasetId');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Dify 返回的数据通常包含 document 信息和 batch 信息
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('文件上传并创建文档成功: ${data['document']['id']}');
        return data;
      } else {
        print('上传失败: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('知识库上传异常: $e');
      return null;
    }
  }

  /// 辅助方法：获取文件 MIME 类型
  String _getMimeType(String filePath) {
    final ext = filePath.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'json':
        return 'application/json';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'html':
      case 'htm':
        return 'text/html';
      default:
        return 'application/octet-stream';
    }
  }
}
