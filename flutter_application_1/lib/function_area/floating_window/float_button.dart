import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/services/template_service.dart';  // ★ 换成导入 Service

class FloatButton extends StatelessWidget {
  const FloatButton({super.key});

  static final fabKey = GlobalKey();

  Future<void> _showMenu(BuildContext context) async {
    final box = fabKey.currentContext!.findRenderObject() as RenderBox;
    final fabPosition = box.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    const menuWidth = 160.0;

    final position = RelativeRect.fromLTRB(
      screenSize.width - menuWidth - 16,
      fabPosition.dy - 140,   // 菜单的悬浮控件的间距
      16,
      screenSize.height - fabPosition.dy,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      constraints: const BoxConstraints(minWidth: menuWidth),
      items: const [
        PopupMenuItem(
          value: 'add_file',
          height: 56,
          child: Row(children: [
            Icon(Icons.file_upload_outlined, size: 20),
            SizedBox(width: 8),
            Text('导入文件'),
          ]),
        ),
        PopupMenuItem(
          value: 'add_new_template',
          height: 56,
          child: Row(children: [
            Icon(Icons.add_chart_outlined, size: 20),
            SizedBox(width: 8),
            Text('新建模板'),
          ]),
        ),
      ],
    );

    if (!context.mounted) return;

    if (result == 'add_file') {
      debugPrint('导入文件');
    } else if (result == 'add_new_template') {
      // ★ 唯一的改动：交给 TemplateService，让它收 draft、写列表、存盘、通知主页
      await TemplateService.instance.addTemplate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: fabKey,
      onPressed: () => _showMenu(context),
      child: const Icon(Icons.add),
    );
  }
}
