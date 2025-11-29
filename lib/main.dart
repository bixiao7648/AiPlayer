import 'package:flutter/material.dart';
import 'mouse_controller.dart';
import 'keyboard_controller.dart';
import 'analysis_page.dart';  // 添加这行

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
