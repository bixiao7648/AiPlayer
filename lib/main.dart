import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'mouse_controller.dart';
import 'keyboard_controller.dart';
import 'analysis_page.dart';  // 添加这行

Future<void> main() async {
  // 加载环境变量
  await dotenv.load(fileName: ".env");
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
  
  // 新增：文本输入控制器
  final TextEditingController _textInputController = TextEditingController();
  final TextEditingController _deleteCountController = TextEditingController(text: '1');

  @override
  void dispose() {
    _textInputController.dispose();
    _deleteCountController.dispose();
    super.dispose();
  }

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

  // 新增：创建新文件
  void _createNewFile() {
    _keyboardController.createNewFile();
  }

  // 新增：输入单次文本
  void _typeSingleText() {
    String text = _textInputController.text;
    if (text.isNotEmpty) {
      _keyboardController.typeText(text);
    } else {
      _keyboardController.typeText('Hello World!');
    }
  }

  // 新增：多次追加文本
  void _appendTextMultiple() {
    String text = _textInputController.text;
    if (text.isNotEmpty) {
      // 将文本按换行符分割，每行作为一次输入
      List<String> texts = text.split('\n').where((line) => line.isNotEmpty).toList();
      if (texts.isEmpty) {
        texts = ['Hello', 'World', '!'];
      }
      _keyboardController.appendTextMultiple(texts);
    } else {
      _keyboardController.appendTextMultiple(['第一行文本', '第二行文本', '第三行文本']);
    }
  }

  // 新增：删除文本（Backspace）
  void _deleteText() {
    int count = int.tryParse(_deleteCountController.text) ?? 1;
    if (count > 0) {
      _keyboardController.deleteText(count: count);
    }
  }

  // 新增：删除文本（Delete）
  void _deleteTextForward() {
    int count = int.tryParse(_deleteCountController.text) ?? 1;
    if (count > 0) {
      _keyboardController.deleteTextForward(count: count);
    }
  }

  // 新增：删除整行
  void _deleteLine() {
    _keyboardController.deleteLine();
  }

  // 新增：清空所有文本
  void _clearAllText() {
    _keyboardController.clearAllText();
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
                
                // 新增：文本操作部分
                const Text(
                  '文本操作',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // 文本输入框
                TextField(
                  controller: _textInputController,
                  decoration: const InputDecoration(
                    labelText: '输入要写入的文本',
                    hintText: '可以输入多行文本（用换行分隔）',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 15),
                
                // 创建新文件按钮
                ElevatedButton.icon(
                  onPressed: _createNewFile,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('创建新文件 (Ctrl+N)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                
                // 单次输入文本按钮
                ElevatedButton.icon(
                  onPressed: _typeSingleText,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('输入文本（单次）'),
                ),
                const SizedBox(height: 10),
                
                // 多次追加文本按钮
                ElevatedButton.icon(
                  onPressed: _appendTextMultiple,
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('多次追加文本'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // 删除文本部分
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _deleteCountController,
                        decoration: const InputDecoration(
                          labelText: '删除字符数',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteText,
                        icon: const Icon(Icons.backspace),
                        label: const Text('删除 (Backspace)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteTextForward,
                        icon: const Icon(Icons.delete),
                        label: const Text('删除 (Delete)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // 删除整行按钮
                ElevatedButton.icon(
                  onPressed: _deleteLine,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('删除整行 (Ctrl+Shift+K)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                
                // 清空所有文本按钮
                ElevatedButton.icon(
                  onPressed: _clearAllText,
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('清空所有文本 (全选+删除)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
