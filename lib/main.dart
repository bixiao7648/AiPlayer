import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'mouse_controller.dart';
import 'keyboard_controller.dart';
import 'analysis_page.dart';
import 'file_command_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Input Controller Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Mouse & Keyboard Controller Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MouseController _mouseController = MouseController();
  final KeyboardController _keyboardController = KeyboardController();
  final FileCommandParser _fileCommandParser = FileCommandParser();
  
  // 添加文本输入控制器和结果状态
  final TextEditingController _commandController = TextEditingController();
  String _commandResult = '';
  bool _isProcessing = false;
  String? _selectedFilePath;  // 添加选中的文件路径

  // 鼠标测试方法
  void _testLeftClick() {
    _mouseController.leftClick(1560, 540);
  }

  void _testRightClick() {
    _mouseController.rightClick(1560, 540);
  }

  void _testDoubleClick() {
    _mouseController.doubleClick(1560, 540);
  }

  // 键盘测试方法
  void _testSingleKey() {
    // 按下单个键 - 例如按 'A'
    _keyboardController.pressKey(VK.A);
  }

  void _testTypeText() {
    // 连续输入文本
    _keyboardController.typeText('Hello World!');
  }

  void _testSelectAll() {
    // Ctrl+A 全选
    _keyboardController.pressKeyCombination([VK.CONTROL, VK.A]);
  }

  void _testCopy() {
    // Ctrl+C 复制
    _keyboardController.pressKeyCombination([VK.CONTROL, VK.C]);
  }

  void _testPaste() {
    // Ctrl+V 粘贴
    _keyboardController.pressKeyCombination([VK.CONTROL, VK.V]);
  }

  void _testSave() {
    // Ctrl+S 保存
    _keyboardController.pressKeyCombination([VK.CONTROL, VK.S]);
  }

  void _testShutDown() {
    // Alt+F4 关闭
    _keyboardController.pressKeyCombination([VK.ALT, VK.F4]);
  }

  void _openAnalysisPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalysisPage()),
    );
  }

  /// 选择文件
  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        setState(() {
          _selectedFilePath = filePath;
          // 如果输入框为空，自动填充修改指令
          if (_commandController.text.trim().isEmpty) {
            final fileName = filePath.split(Platform.pathSeparator).last;
            _commandController.text = '修改"$fileName"，内容为""';
          }
        });
      }
    } catch (e) {
      setState(() {
        _commandResult = '选择文件出错: $e';
      });
    }
  }

  /// 处理文件拖拽
  void _handleFileDrop(String filePath) {
    setState(() {
      _selectedFilePath = filePath;
      // 如果输入框为空，自动填充修改指令
      if (_commandController.text.trim().isEmpty) {
        final fileName = filePath.split(Platform.pathSeparator).last;
        _commandController.text = '修改"$fileName"，内容为""';
      }
    });
  }

  /// 执行文件操作指令
  Future<void> _executeFileCommand() async {
    String command = _commandController.text.trim();
    
    // 移除自动添加文件路径的逻辑，改为直接传递参数
    // 如果选中了文件，直接使用已选择的文件路径，不需要修改命令字符串
    
    if (command.isEmpty) {
      setState(() {
        _commandResult = '请输入指令';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _commandResult = '正在处理...';
    });

    try {
      // 传递已选择的文件路径
      final result = await _fileCommandParser.parseAndExecute(
        command,
        selectedFilePath: _selectedFilePath,
      );
      setState(() {
        _commandResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _commandResult = '执行出错: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _commandController.dispose();  // 释放资源
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 文件操作指令输入区域
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '文件操作指令',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          // 文件选择按钮
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _selectFile,
                            icon: const Icon(Icons.folder_open, size: 18),
                            label: const Text('选择文件'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 显示选中的文件
                      if (_selectedFilePath != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '已选择: ${_selectedFilePath!.split(Platform.pathSeparator).last}',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _selectedFilePath = null;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 支持文件拖拽的输入框
                      DragTarget<String>(
                        onAccept: (data) {
                          _handleFileDrop(data);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              border: candidateData.isNotEmpty
                                  ? Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                      style: BorderStyle.solid,
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _commandController,
                              decoration: InputDecoration(
                                hintText: _selectedFilePath != null
                                    ? '例如：内容为"新内容"'
                                    : '例如：生成一个内容为"1"的txt文件',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 2,
                              enabled: !_isProcessing,
                              onSubmitted: (_) => _executeFileCommand(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _executeFileCommand,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isProcessing ? '处理中...' : '执行指令'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      if (_commandResult.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _commandResult.contains('✓')
                                ? Colors.green.shade50
                                : _commandResult.contains('✗')
                                    ? Colors.red.shade50
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _commandResult.contains('✓')
                                  ? Colors.green.shade200
                                  : _commandResult.contains('✗')
                                      ? Colors.red.shade200
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            _commandResult,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                const Divider(),

                // 在最顶部添加 AI 分析按钮
                ElevatedButton.icon(
                  onPressed: _openAnalysisPage,
                  icon: const Icon(Icons.psychology),
                  label: const Text('打开 Claude AI 分析助手'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 40),
                const Divider(),
                
                // 鼠标控制部分
                const Text(
                  '鼠标控制',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testLeftClick,
                  child: const Text('左键点击 (1560, 540)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testRightClick,
                  child: const Text('右键点击 (1560, 540)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testDoubleClick,
                  child: const Text('双击 (1560, 540)'),
                ),
                
                const SizedBox(height: 40),
                const Divider(),
                
                // 键盘控制部分
                const Text(
                  '键盘控制',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testSingleKey,
                  child: const Text('单键输入 (按 A)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testTypeText,
                  child: const Text('连续输入 (Hello World!)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testSelectAll,
                  child: const Text('Ctrl+A (全选)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testCopy,
                  child: const Text('Ctrl+C (复制)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testPaste,
                  child: const Text('Ctrl+V (粘贴)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testSave,
                  child: const Text('Ctrl+S (保存)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _testShutDown,
                  child: const Text('Alt+F4 (关闭)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
