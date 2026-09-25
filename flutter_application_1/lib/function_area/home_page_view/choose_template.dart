import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/floating_window/create_template_page.dart';
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
            // ★ 走 draftAt：旧版本存档（纯文本/旧 JSON 格式）解析失败时兜底，
            //   旧写法 TemplateDraft.fromJson 遇到坏数据会在 build 期间抛异常
            final draft = TemplateService.instance.draftAt(index);
            return GestureDetector(
              // ✅ 新模型：自定义模板 → 进自定义游玩页
              onTap: () => openCustomPlayPage(context, draft),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 202, 225, 243),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16, bottom: 16,
                      child: Text(
                        draft.name,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    Positioned(
                      right: 16, bottom: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _circleIconBtn(Icons.edit, () async {
                            final result = await Navigator.push<TemplateDraft>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateTemplatePage.withDraft(draft, index),
                              ),
                            );
                            if (result == null) return; // 用户没保存
                            TemplateService.instance.updateTemplate(index, result.toJson());
                          }),
                          const SizedBox(width: 12),
                          _circleIconBtn(Icons.delete_outline,
                              () => TemplateService.instance.deleteTemplate(context, index)),
                          const SizedBox(width: 12),
                          _circleIconBtn(Icons.share,
                              () => TemplateService.instance.shareTemplate(index)),
                          const SizedBox(width: 12),
                          _circleIconBtn(Icons.flash_on,
                              () => TemplateService.instance.selfstartingTemlate(index)),
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

  Widget _circleIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color.fromARGB(255, 60, 90, 120)),
      ),
    );
  }
}
