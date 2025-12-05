import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart'; // 需要导入这个来处理 MediaType

class DifyService {
  // Dify API 基础地址 (如果是私有部署请修改为你的域名)
  static const String baseUrl = 'https://api.dify.ai/v1';
  
  // 你的知识库 API Key (在 Dify 知识库设置 -> API访问 中获取)
  final String apiKey;
  
  // 目标数据集 ID (在 Dify URL 中可以看到，例如 /datasets/{dataset_id}/documents)
  final String datasetId;

  DifyService({required this.apiKey, required this.datasetId});

  /// 1. 选择并上传文件的主流程
  Future<void> pickAndUploadFile() async {
    try {
      // 打开文件选择器
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'pdf', 'html', 'docx'], // Dify 支持的格式
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        print('已选择文件: ${file.path}');
        
        await _uploadToDify(file);
      } else {
        print('未选择文件');
      }
    } catch (e) {
      print('操作失败: $e');
      rethrow;
    }
  }

  /// 2. 执行上传请求
  Future<void> _uploadToDify(File file) async {
    var uri = Uri.parse('$baseUrl/datasets/$datasetId/document/create_by_file');
    
    var request = http.MultipartRequest('POST', uri);

    // 设置认证头
    request.headers['Authorization'] = 'Bearer $apiKey';

    // 添加文件
    // 注意：如果是二进制文件(PDF/Word)，最好显式指定 contentType，这里简单处理
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: path.basename(file.path),
    ));

    // 添加处理规则 (process_rule)
    // 这里的 mode: 'automatic' 是 Dify 的默认自动分段模式
    // 如果需要自定义分段，需要传入更复杂的 JSON 结构
    Map<String, dynamic> processRule = {
      "mode": "automatic"
    };
    request.fields['data'] = jsonEncode({
      "indexing_technique": "high_quality", // 或 "economy"
      "process_rule": processRule
    });

    print('开始上传文件到 Dify...');
    
    // 发送请求
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('文件上传成功: ${response.body}');
      var jsonResponse = jsonDecode(response.body);
      // 这里可以处理成功后的逻辑，比如通知 UI 更新
    } else {
      print('文件上传失败: ${response.statusCode}');
      print('错误详情: ${response.body}');
      throw Exception('Dify Upload Failed: ${response.body}');
    }
  }
}


