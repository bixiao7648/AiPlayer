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

  // 在 analysis_module.dart 中添加博查 AI 搜索功能

  static const String _claudeApiKey = 'sk-E7GV9bCm2w5eHYrxpigisBXJNveFbZqGW8BthWFHBgLbIdCM';
  static const String _bochaApiKey = 'sk-301089b06b0049a5b3daae3274e101cb';
  static const String _claudeBaseUrl = 'https://chat.cloudapi.vip/v1';
  static const String _bochaBaseUrl = 'https://api.bochaai.com';
  
  /// 带联网搜索的消息发送
  Future<String> sendMessageWithSearch(String message) async {
    try {
      // 步骤1: 先用博查 AI 搜索相关信息
      final searchResults = await _searchWithBocha(message);
      
      // 步骤2: 将搜索结果和用户问题一起发给 Claude
      final contextMessage = '''
用户问题: $message

相关搜索结果:
$searchResults

请基于以上搜索结果，回答用户的问题。如果搜索结果不足以回答问题，请说明。
''';
      
      // 步骤3: 调用 Claude 分析
      return await _sendToClaude(contextMessage);
      
    } catch (e) {
      return '发生错误: $e';
    }
  }
  
  /// 调用博查 AI 搜索
  Future<String> _searchWithBocha(String query) async {
    final url = Uri.parse('$_bochaBaseUrl/v1/web-search');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_bochaApiKey',
      },
      body: jsonEncode({
        'query': query,
        'freshness': 'noLimit',
        'summary': true,
        'count': 5,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      // 添加调试输出
      print('博查 AI 响应: ${jsonEncode(data)}');
      
      // 提取搜索结果 - 添加更多空值检查
      StringBuffer results = StringBuffer();
      
      // 如果有 summary 字段，直接使用摘要
      if (data['summary'] != null && data['summary'].toString().isNotEmpty) {
        results.writeln('=== 搜索摘要 ===');
        results.writeln(data['summary']);
        results.writeln();
      }
      
      // 尝试多种可能的响应格式
      dynamic webPages;
      if (data['data'] != null && data['data']['webPages'] != null) {
        webPages = data['data']['webPages'];
      } else if (data['webPages'] != null) {
        webPages = data['webPages'];
      } else if (data['results'] != null) {
        webPages = data['results'];
      }
      
      if (webPages != null && webPages is List && webPages.isNotEmpty) {
        results.writeln('=== 参考来源 ===');
        for (var i = 0; i < webPages.length; i++) {
          final page = webPages[i];
          if (page != null && page is Map) {
            // 尝试不同的字段名
            final title = page['name'] ?? page['title'] ?? page['snippet'] ?? '未知标题';
            final snippet = page['snippet'] ?? page['description'] ?? page['content'] ?? '';
            final url = page['url'] ?? page['link'] ?? '';
            
            results.writeln('${i + 1}. $title');
            if (snippet.isNotEmpty) {
              results.writeln('   $snippet');
            }
            if (url.isNotEmpty) {
              results.writeln('   来源: $url');
            }
            results.writeln();
          }
        }
      }
      
      // 如果什么都没解析到，返回原始响应
      if (results.isEmpty) {
        return '搜索返回数据: ${jsonEncode(data)}';
      }
      
      return results.toString();
    } else {
      throw Exception('搜索失败: ${response.statusCode}\n响应: ${response.body}');
    }
  }
  
  /// 发送给 Claude（原有逻辑）
  Future<String> _sendToClaude(String message) async {
    final url = Uri.parse('$_claudeBaseUrl/chat/completions');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_claudeApiKey',
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
  }
}
