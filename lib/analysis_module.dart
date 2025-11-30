import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalysisModule {
  // Dify API 配置
  static const String _apiKey = 'app-5LrdPZcsaJYZXfATF05O4A7k';
  static const String _baseUrl = 'https://api.dify.ai/v1';
  
  // 固定 User ID，确保同一个用户访问同一个会话
  // 在实际应用中，建议使用登录用户的真实 ID 或设备唯一标识
  static final String _userId = 'flutter-user-fixed-id'; 

  // 只需要一个会话ID即可，不需要分开
  String? _conversationId;
  
  /// 发送消息到 Dify API
  /// 
  /// [message] 用户输入的问题
  /// 返回 Dify AI 的回答，如果出错则返回错误信息
  Future<String> sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return '请输入问题';
    }

    try {
      final url = Uri.parse('$_baseUrl/chat-messages');
      
      final requestBody = {
        'inputs': {},
        'query': message,
        'response_mode': 'blocking',
        'user': _userId, // <--- 修改这里：使用固定的 User ID
      };
      
      // 使用同一个会话ID
      if (_conversationId != null && _conversationId!.isNotEmpty) {
        requestBody['conversation_id'] = _conversationId!;
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // 更新全局会话ID
        if (data['conversation_id'] != null) {
          _conversationId = data['conversation_id'];
        }
        
        // 解析返回的消息
        if (data['answer'] != null) {
          return data['answer'];
        } else {
          return '未收到回复';
        }
      } else {
        // 如果遇到 404 错误（可能是服务端重置了会话），尝试清空 ID 重试
        if (response.statusCode == 404) {
          _conversationId = null;
           // 可选：这里可以递归调用一次 sendMessage(message) 自动重试
           return '会话已失效，请重试';
        }
        
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        return '请求失败: ${response.statusCode}\n${errorData['message'] ?? response.body}';
      }
    } catch (e) {
      return '发生错误: $e';
    }
  }

  /// 清除会话上下文
  void clearConversation() {
    _conversationId = null;
  }

  /// 发送消息并流式接收（可选实现）
  /// 如果 API 支持 streaming，可以实现这个方法
  Stream<String> sendMessageStream(String message) async* {
    // 这是一个简单的实现，实际流式传输需要 SSE 支持
    final result = await sendMessage(message);
    yield result;
  }
}
