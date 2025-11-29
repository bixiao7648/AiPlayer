import 'package:flutter/material.dart';
import 'mouse_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Controller Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Mouse Controller Demo'),
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

  void _testLeftClick() {
    // 左键点击屏幕中心 (示例坐标)
    _mouseController.leftClick(1560, 540);
  }

  void _testRightClick() {
    // 右键点击指定位置
    _mouseController.rightClick(1560, 540);
  }

  void _testDoubleClick() {
    // 双击指定位置
    _mouseController.doubleClick(1560, 540);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _testLeftClick,
              child: const Text('左键点击 (960, 540)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testRightClick,
              child: const Text('右键点击 (960, 540)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testDoubleClick,
              child: const Text('双击 (960, 540)'),
            ),
          ],
        ),
      ),
    );
  }
}
