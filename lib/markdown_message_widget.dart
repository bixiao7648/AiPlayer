import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class MarkdownMessageWidget extends StatelessWidget {
  final String data;
  final bool isUser;

  const MarkdownMessageWidget({
    super.key,
    required this.data,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        code: TextStyle(
          backgroundColor: isUser ? Colors.transparent : Colors.grey[200],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
      ),
      builders: {
        'pre': CodeBlockBuilder(context),
      },
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  CodeBlockBuilder(this.context);

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    // This method is called for the text content inside the pre/code tag
    return _buildCodeBlock(text.text);
  }

  Widget _buildCodeBlock(String codeContent) {
    // Basic detection of language or filename if possible (naive)
    // usually markdown is ```json\n...``` so the language might be handled by the parser,
    // but MarkdownElementBuilder.visitText gets the raw content inside.
    
    // Trim the content
    final content = codeContent.trimRight();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Code / File',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  // Copy Button
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('已复制到剪贴板'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.copy, size: 16, color: Colors.grey),
                    ),
                  ),
                  // Save Button
                  InkWell(
                    onTap: () => _saveFile(content),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          Icon(Icons.save_alt, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            '保存文件',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Code Content
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            border: Border.fromBorderSide(BorderSide(color: Colors.grey[300]!)),
          ),
          padding: const EdgeInsets.all(12),
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _saveFile(String content) async {
    try {
      // 1. Ask user where to save
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: 'output.txt', // Default filename
      );

      if (outputFile == null) {
        // User canceled the picker
        return;
      }

      // 2. Write the file
      final file = File(outputFile);
      await file.writeAsString(content);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('文件已保存: $outputFile'),
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: '打开文件夹',
              onPressed: () {
                // Open the folder (Windows/Explorer)
                final dir = file.parent.path;
                Process.run('explorer', [dir]);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
