import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/floating_window/create_template_page.dart';
import 'package:flutter_application_1/function_area/floating_window/create_mouse_move_page.dart';
import '../all_template/base/template_document.dart';
import '../all_template/player_template/custom_play_page.dart';

class ChooseTemplate extends StatefulWidget {
  const ChooseTemplate({super.key});
  @override
  State<ChooseTemplate> createState() => _ChooseTemplateState();
}

class _ChooseTemplateState extends State<ChooseTemplate> {
  @override
  void initState() {
    super.initState();
    TemplateService.instance.loadOnce();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemplateService.instance,
      builder: (context, _) {
        final templates = TemplateService.instance.templates;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final draft = TemplateService.instance.draftAt(index);
            final isMouse = draft.isMouse;

            return GestureDetector(
              // ★ 按类型路由播放页
              onTap: () => _openPlay(context, draft, isMouse),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: isMouse
                      ? const Color.fromARGB(255, 243, 225, 202) // 鼠标模板：暖色底
                      : const Color.fromARGB(255, 202, 225, 243), // 键盘模板：冷色底
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // 模板名 + 类型标签
                    Positioned(
                      left: 16, bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            draft.name,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMouse
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isMouse ? '🖱️ 鼠标模板' : '⌨️ 键盘模板',
                              style: TextStyle(
                                fontSize: 11,
                                color: isMouse
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 操作按钮
                    Positioned(
                      right: 16, bottom: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── 编辑：按类型路由到对应编辑器 ──
                          _circleIconBtn(Icons.edit, () async {
                            if (isMouse) {
                              final result =
                                  await Navigator.push<TemplateDraft>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateMouseMovePage(initial: draft),
                                ),
                              );
                              if (result == null) return;
                              TemplateService.instance
                                  .updateTemplate(index, result.toJson());
                            } else {
                              final result =
                                  await Navigator.push<TemplateDraft>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CreateTemplatePage.withDraft(
                                          draft, index),
                                ),
                              );
                              if (result == null) return;
                              TemplateService.instance
                                  .updateTemplate(index, result.toJson());
                            }
                          }),
                          const SizedBox(width: 12),
                          _circleIconBtn(Icons.delete_outline,
                              () => TemplateService.instance.deleteTemplate(
                                  context, index)),
                          // ★ 鼠标模板不显示分享按钮
                          if (!isMouse) ...[
                            const SizedBox(width: 12),
                            _circleIconBtn(Icons.share,
                                () => TemplateService.instance.shareTemplate(
                                    context, index)),
                          ],
                          const SizedBox(width: 12),
                          _autoStartBtn(index),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        );
      },
    );
  }

  /// 按类型打开播放页
  void _openPlay(BuildContext context, TemplateDraft draft, bool isMouse) {
    if (isMouse) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateMouseMovePage(
            initial: draft,
            playMode: true,
          ),
        ),
      );
    } else {
      openCustomPlayPage(context, draft);
    }
  }

  Widget _circleIconBtn(IconData icon, VoidCallback onTap,
      {Color? bgColor, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 20, color: iconColor ?? const Color.fromARGB(255, 60, 90, 120)),
      ),
    );
  }

  /// 自启动按钮：激活时琥珀色背景 + 白色图标，未激活时与其它按钮一致
  Widget _autoStartBtn(int index) {
    final isActive = TemplateService.instance.autoStartIndex == index;
    return _circleIconBtn(
      Icons.flash_on,
      () => TemplateService.instance.selfstartingTemlate(index),
      bgColor: isActive ? Colors.amber.shade600 : null,
      iconColor: isActive ? Colors.white : null,
    );
  }
}