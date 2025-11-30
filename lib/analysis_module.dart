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
  
  /// 带联网搜索的消息发送（三步流程）
  Future<String> sendMessageWithSearch(String message) async {
    print('\n════════════════════════════════════════════════════════');
    print('🚀 开始联网搜索流程');
    print('📝 用户原始问题: $message');
    print('════════════════════════════════════════════════════════\n');
    
    try {
      // 步骤1: 让 Claude 提炼搜索关键词
      print('⏳ [步骤 1/3] 开始提炼搜索关键词...');
      final searchQuery = await _refineSearchQuery(message);
      print('✅ [步骤 1/3] 搜索关键词提炼完成: "$searchQuery"\n');
      
      if (searchQuery.isEmpty) {
        print('ℹ️  Claude 判断此问题无需联网搜索，直接回答');
        print('════════════════════════════════════════════════════════\n');
        return await _sendToClaude(message);
      }
      
      // 步骤2: 用提炼后的关键词调用博查 AI 搜索
      print('⏳ [步骤 2/3] 开始网络搜索...');
      print('🔍 搜索关键词: $searchQuery');
      final searchResults = await _searchWithBocha(searchQuery);
      print('✅ [步骤 2/3] 网络搜索完成');
      print('📊 搜索结果长度: ${searchResults.length} 字符\n');
      
      // 步骤3: 将搜索结果和原始问题一起发给 Claude 进行最终回答
      print('⏳ [步骤 3/3] Claude 正在分析搜索结果并生成回答...');
      final contextMessage = '''
用户的原始问题: $message

我为此进行了网络搜索，使用的搜索关键词是: $searchQuery

搜索结果如下:
$searchResults

请基于以上搜索结果，用中文详细回答用户的问题。如果搜索结果不足以回答问题，请说明原因并尽可能提供你的分析。
''';
      
      final finalAnswer = await _sendToClaude(contextMessage);
      print('✅ [步骤 3/3] 最终回答生成完成');
      print('💬 回答长度: ${finalAnswer.length} 字符');
      print('\n════════════════════════════════════════════════════════');
      print('✨ 联网搜索流程完成！');
      print('════════════════════════════════════════════════════════\n');
      
      return finalAnswer;
      
    } catch (e) {
      print('❌ 联网搜索流程出错: $e');
      print('════════════════════════════════════════════════════════\n');
      return '发生错误: $e';
    }
  }

  /// 让 Claude 提炼搜索关键词
  /// 这一步可以优化用户问题，提取最适合搜索的关键词
  Future<String> _refineSearchQuery(String userMessage) async {
    print('   📋 构建搜索词提炼提示...');
    
    final prompt = '''
用户问了这个问题: "$userMessage"

请分析这个问题，然后：
1. 如果这个问题需要查询最新信息、实时数据、新闻事件等，请提炼出最适合用于网络搜索的关键词或短语（中文或英文）
2. 如果这是一个通用知识问题、数学计算、代码问题等不需要联网的问题，请直接回复"NO_SEARCH"

要求：
- 搜索关键词要简洁、准确
- 去除口语化表达
- 保留核心概念和时间信息
- 只返回搜索关键词或"NO_SEARCH"，不要有其他解释

示例：
用户: "2025年11月29日有什么新闻" → 2025年11月29日 新闻
用户: "最近AI有什么突破" → AI breakthrough 2025 latest
用户: "什么是递归" → NO_SEARCH
用户: "1+1等于几" → NO_SEARCH

现在请处理用户的问题。
''';

    try {
      print('   🤖 正在调用 Claude 提炼搜索词...');
      final response = await _sendToClaude(prompt);
      final refined = response.trim();
      
      print('   📥 Claude 原始回复: "$refined"');
      
      // 如果 Claude 认为不需要搜索
      if (refined.toUpperCase().contains('NO_SEARCH') || 
          refined.toUpperCase() == 'NO' ||
          refined.isEmpty) {
        print('   ⚠️  判断为无需搜索');
        return '';
      }
      
      print('   ✨ 提炼后的搜索词: "$refined"');
      return refined;
    } catch (e) {
      print('   ❌ 搜索词提炼失败: $e');
      print('   ↩️  回退使用原始问题');
      return userMessage;
    }
  }

  /// 调用博查 AI 搜索
  Future<String> _searchWithBocha(String query) async {
    print('   🌐 准备调用博查 AI API...');
    print('   🔗 API URL: $_bochaBaseUrl/v1/web-search');
    
    final url = Uri.parse('$_bochaBaseUrl/v1/web-search');
    
    final requestBody = {
      'query': query,
      'freshness': 'noLimit',
      'summary': true,
      'count': 5,
    };
    
    print('   �� 请求参数: ${jsonEncode(requestBody)}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_bochaApiKey',
      },
      body: jsonEncode(requestBody),
    );
    
    print('   📥 HTTP 状态码: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      print('   📊 博查 AI 完整响应:');
      print('   ${jsonEncode(data)}');
      print('');
      
      // 提取搜索结果
      StringBuffer results = StringBuffer();
      
      // 如果有 summary 字段，直接使用摘要
      if (data['summary'] != null && data['summary'].toString().isNotEmpty) {
        print('   ✅ 找到搜索摘要');
        results.writeln('=== 搜索摘要 ===');
        results.writeln(data['summary']);
        results.writeln();
      }
      
      // 尝试多种可能的响应格式
      dynamic webPages;
      if (data['data'] != null && data['data']['webPages'] != null) {
        webPages = data['data']['webPages'];
        print('   ✅ 从 data.webPages 获取结果');
      } else if (data['webPages'] != null) {
        webPages = data['webPages'];
        print('   ✅ 从 webPages 获取结果');
      } else if (data['results'] != null) {
        webPages = data['results'];
        print('   ✅ 从 results 获取结果');
      } else {
        print('   ⚠️  未找到网页结果');
      }
      
      if (webPages != null && webPages is List && webPages.isNotEmpty) {
        print('   📄 找到 ${webPages.length} 条搜索结果');
        results.writeln('=== 参考来源 ===');
        for (var i = 0; i < webPages.length; i++) {
          final page = webPages[i];
          if (page != null && page is Map) {
            final title = page['name'] ?? page['title'] ?? page['snippet'] ?? '未知标题';
            final snippet = page['snippet'] ?? page['description'] ?? page['content'] ?? '';
            final url = page['url'] ?? page['link'] ?? '';
            
            print('   📌 结果 ${i + 1}: $title');
            
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
        print('   ⚠️  无法解析搜索结果，返回原始数据');
        return '搜索返回数据: ${jsonEncode(data)}';
      }
      
      print('   ✅ 搜索结果解析完成');
      return results.toString();
    } else {
      print('   ❌ 博查 AI 请求失败');
      print('   📥 错误响应: ${response.body}');
      throw Exception('搜索失败: ${response.statusCode}\n响应: ${response.body}');
    }
  }
  
  /// 发送给 Claude（原有逻辑）
  Future<String> _sendToClaude(String message) async {
    print('   🤖 调用 Claude API...');
    print('   📝 消息长度: ${message.length} 字符');
    
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

    print('   📥 Claude HTTP 状态码: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      // 解析返回的消息
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final content = data['choices'][0]['message']['content'];
        print('   ✅ Claude 回复成功，长度: ${content?.length ?? 0} 字符');
        return content ?? '未收到回复';
      } else {
        print('   ❌ Claude 响应格式错误');
        return '响应格式错误';
      }
    } else {
      print('   ❌ Claude 请求失败');
      print('   📥 错误响应: ${response.body}');
      return '请求失败: ${response.statusCode}\n${response.body}';
    }
  }
}
