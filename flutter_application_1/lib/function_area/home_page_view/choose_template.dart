import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/all_template/system_template/two_side_template.dart';
import 'package:flutter_application_1/function_area/floating_window/create_template_page.dart';

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
    // ★ 不再需要手动挂/摘回调，ListenableBuilder 全权负责
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TemplateService.instance, // ★ 核心：自动监听 notifyListeners
      builder: (context, _) {
        final templates = TemplateService.instance.templates;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final draft = TemplateDraft.fromJson(templates[index]);
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TwoSideTemplate(
                    splitFraction: draft.splitFraction,
                    leftKey: draft.leftKey,
                    rightKey: draft.rightKey,
                  ),
                ),
              ),
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
                          _circleIconBtn(Icons.edit,
                              () => TemplateService.instance.editTemplate(context, index)),
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

  /// 圆形小按钮：写一次，多处复用
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
