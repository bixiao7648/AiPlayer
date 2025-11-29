import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisModule {
  // API 配置
  static const String _apiKey = 'sk-E7GV9bCm2w5eHYrxpigisBXJNveFbZqGW8BthWFHBgLbIdCM';
  static const String _baseUrl = 'https://chat.cloudapi.vip/v1';
  static const String _model = 'claude-opus-4-5-20251101-thinking'; // 可以根据需要修改模型

  /// 发送消息到 Claude API
  /// 
  /// [message] 用户输入的问题
  /// 返回 Claude 的回答，如果出错则返回错误信息
  Future<String> sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return '请输入问题';
    }

    try {
      final url = Uri.parse('$_baseUrl/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': message,
            }
          ],
          'max_tokens': 4096,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // 解析返回的消息
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          final content = data['choices'][0]['message']['content'];
          return content ?? '未收到回复';
        } else {
          return '响应格式错误';
        }
      } else {
        return '请求失败: ${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      return '发生错误: $e';
    }
  }

  /// 发送消息并流式接收（可选实现）
  /// 如果 API 支持 streaming，可以实现这个方法
  Stream<String> sendMessageStream(String message) async* {
    // 这是一个简单的实现，实际流式传输需要 SSE 支持
    final result = await sendMessage(message);
    yield result;
  }
}
