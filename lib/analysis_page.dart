import 'package:flutter/material.dart';
import 'analysis_module.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final AnalysisModule _analysisModule = AnalysisModule();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _enableWebSearch = false; // 新增：联网搜索开关
  String _statusText = ''; // 新增：状态文本

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _inputController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _statusText = _enableWebSearch ? '正在分析问题...' : 'Claude 正在思考...';
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      String response;
      
      // 根据开关选择是否联网搜索
      if (_enableWebSearch) {
        // 三步流程的状态提示
        setState(() {
          _statusText = '步骤 1/3: Claude 正在提炼搜索关键词...';
        });
        
        await Future.delayed(const Duration(milliseconds: 500)); // 让用户看到状态变化
        
        setState(() {
          _statusText = '步骤 2/3: 正在搜索网络信息...';
        });
        
        // 这里会执行三步流程
        response = await _analysisModule.sendMessageWithSearch(message);
        
        setState(() {
          _statusText = '步骤 3/3: Claude 正在分析搜索结果...';
        });
      } else {
        response = await _analysisModule.sendMessage(message);
      }

      // 添加 AI 回复
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          hasWebSearch: _enableWebSearch,
        ));
        _isLoading = false;
        _statusText = '';
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: '发生错误: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
        _statusText = '';
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude AI 分析助手'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 联网搜索开关
          Row(
            children: [
              Icon(
                Icons.language,
                size: 20,
                color: _enableWebSearch ? Colors.green : Colors.grey,
              ),
              Switch(
                value: _enableWebSearch,
                onChanged: (value) {
                  setState(() {
                    _enableWebSearch = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: '清空对话',
          ),
        ],
      ),
      body: Column(
        children: [
          // 联网状态提示条
          if (_enableWebSearch)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.language, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    '联网搜索已启用',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '回答将基于实时网络信息',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '开始与 Claude 对话',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '提示: 开启联网搜索获取实时信息',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatBubble(message: message);
                    },
                  ),
          ),

          // 加载指示器
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_statusText),
                ],
              ),
            ),

          // 输入框区域
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: '输入您的问题...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      // 在输入框中显示联网状态
                      prefixIcon: _enableWebSearch
                          ? Icon(Icons.language, color: Colors.green[700])
                          : null,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 消息数据模型 - 添加联网标记
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasWebSearch; // 新增：标记是否使用了联网搜索

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasWebSearch = false,
  });
}

// 聊天气泡组件 - 显示联网标记
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: const Icon(Icons.smart_toy, color: Colors.purple),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 联网搜索标记
                  if (!message.isUser && message.hasWebSearch)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.language,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '基于网络搜索',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, color: Colors.blue),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
