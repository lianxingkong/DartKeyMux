import 'package:flutter/material.dart';

import '../services/template_service.dart'; // ✅ 同目录，直接相对引用即可

Future<void> showTemplateImportDialog(BuildContext context) async {
  final ctrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('导入模板'),
      content: TextField(
        controller: ctrl,
        maxLines: 5,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '粘贴分享码（GKT1.xxxxx…）',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          child: const Text('导入'),
          onPressed: () async {
            final ok = await TemplateService.instance.importTemplate(ctrl.text);
            if (ctx.mounted) Navigator.pop(ctx, ok);
          },
        ),
      ],
    ),
  );

  Future.delayed(const Duration(milliseconds: 400), ctrl.dispose);  // 延迟释放，防止卡死

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ok == true ? '导入成功' : '分享码无效')),
  );
}
