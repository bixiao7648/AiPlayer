import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'analysis_module.dart';
import 'screenshot_helper.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path_provider/path_provider.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final AnalysisModule _analysisModule = AnalysisModule();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // 新增：当前选择的图片
  File? _selectedImage;
  String? _selectedImageName;

  final ScreenshotHelper _screenshotHelper = ScreenshotHelper();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 从粘贴板粘贴图片
  Future<void> _pasteImageFromClipboard() async {
    try {
      // 尝试获取粘贴板中的图片
      final imageBytes = await Pasteboard.image;
      
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // 保存到临时文件
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/clipboard_image_$timestamp.png');
        await tempFile.writeAsBytes(imageBytes);
        
        setState(() {
          _selectedImage = tempFile;
          _selectedImageName = 'clipboard_image_$timestamp.png';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已从粘贴板添加图片')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('粘贴板中没有图片')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('粘贴图片失败: $e')),
        );
      }
    }
  }

  /// 处理键盘快捷键（Ctrl+V 粘贴）
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final isVPressed = event.logicalKey == LogicalKeyboardKey.keyV;
      
      if (isControlPressed && isVPressed) {
        _pasteImageFromClipboard();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// 移除已选择的图片
  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageName = null;
    });
  }

  /// 发送消息（带或不带图片）
  void _sendMessage() async {
    final message = _inputController.text.trim();
    
    // 如果没有文字也没有图片，不发送
    if (message.isEmpty && _selectedImage == null) return;
    if (_isLoading) return;

    final hasImage = _selectedImage != null;
    final imagePath = _selectedImage?.path;
    final imageName = _selectedImageName;

    // 添加用户消息
    setState(() {
      _messages.add(ChatMessage(
        text: message.isEmpty ? '请分析这张图片' : message,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ));
      _isLoading = true;
    });

    // 清空输入框和图片
    _inputController.clear();
    setState(() {
      _selectedImage = null;
      _selectedImageName = null;
    });

    // 滚动到底部
    _scrollToBottom();

    // 调用 Dify API
    String response;
    if (hasImage && imagePath != null) {
      response = await _analysisModule.sendMessageWithImage(
        message.isEmpty ? '请分析这张图片' : message,
        imagePath,
      );
    } else {
      response = await _analysisModule.sendMessage(message);
    }

    // 添加 AI 回复
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });

    // 滚动到底部
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
      _analysisModule.clearConversation();
      _selectedImage = null;
      _selectedImageName = null;
    });
  }

  Future<void> _takeScreenshot() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'screenshot_$timestamp.bmp';
      final filePath = fileName;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在截图...')),
        );
      }

      final success = await _screenshotHelper.captureFullScreen(filePath);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('截图已保存: $filePath'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '打开文件夹',
                onPressed: () {
                  final file = File(filePath);
                  final dir = file.parent.path;
                  Process.run('explorer', [dir]);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('截图失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('截图出错: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dify AI 分析助手'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.screenshot),
            onPressed: _takeScreenshot,
            tooltip: '截图',
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
                          '开始与 Dify AI 对话',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '支持发送文字、图片，或按 Ctrl+V 粘贴图片',
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
                  const Text('Dify AI 正在思考...'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片预览区域
                if (_selectedImage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        // 图片缩略图
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 文件名
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedImageName ?? '图片',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '准备发送',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 删除按钮
                        IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          onPressed: _removeSelectedImage,
                          tooltip: '移除图片',
                        ),
                      ],
                    ),
                  ),
                ],
                // 输入框和按钮
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 选择图片按钮
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _isLoading ? null : _pickImage,
                      tooltip: '选择图片',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    // 粘贴图片按钮
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: _isLoading ? null : _pasteImageFromClipboard,
                      tooltip: '粘贴图片 (Ctrl+V)',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    // 文本输入框
                    Expanded(
                      child: Focus(
                        focusNode: _inputFocusNode,
                        onKeyEvent: _handleKeyEvent,
                        child: TextField(
                          controller: _inputController,
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: '输入消息或按 Ctrl+V 粘贴图片...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 发送按钮
                    FloatingActionButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      child: Icon(_isLoading ? Icons.hourglass_empty : Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 消息数据模型（添加图片支持）
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}

// 聊天气泡组件（添加图片显示）
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
                  // 如果有图片，显示图片
                  if (message.imagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.grey[300],
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error, size: 16),
                                SizedBox(width: 4),
                                Text('图片加载失败'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
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
