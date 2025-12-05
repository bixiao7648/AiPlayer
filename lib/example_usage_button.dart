// 这是一个 UI 使用示例
import 'package:flutter/material.dart';
import 'dify_service.dart'; // 记得导入上面创建的文件

class UploadButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.upload_file),
      label: Text('上传文件到知识库'),
      onPressed: () async {
        // 建议将 Key 和 ID 放在配置文件或 .env 中
        final difyService = DifyService(
          apiKey: '你的_DIFY_DATASET_API_KEY', 
          datasetId: '你的_DATASET_ID'
        );
        
        try {
          // 显示加载中
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('正在处理...'))
          );
          
          await difyService.pickAndUploadFile();
          
          // 成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传成功！'))
          );
        } catch (e) {
          // 错误提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('上传失败: $e'))
          );
        }
      },
    );
  }
}
