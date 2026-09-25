import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/function_area/floating_window/create_template_page.dart';

/// 改成 ChangeNotifier：谁想听谁挂监听，支持多个监听者
class TemplateService extends ChangeNotifier {
  static final TemplateService instance = TemplateService._();
  TemplateService._();

  static const _storageKey = 'templates';

  List<String> templates = ['预设模板A'];

  List<String> selfstarting = [];   // 记录自启动模板信息

  bool _loaded = false; // 防止重复读档

  // ---------- 持久化 ----------

  Future<void> loadOnce() async {
    if (_loaded) return; // 已经读过一次就不再读
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      debugPrint('【读档】磁盘上取到: $saved');
      if (saved != null && saved.isNotEmpty) {
        templates = saved;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('【读档】异常: $e');
      _loaded = false; // 失败了允许下次重试
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setStringList(_storageKey, templates);
      debugPrint('【存盘】${ok ? '成功' : '失败'}: $templates');
    } catch (e) {
      debugPrint('【存盘】异常: $e');
    }
  }

  // ---------- 业务 ----------

  /// 新建：不带 initial，保存后追加到最前面
  Future<void> addTemplate(BuildContext context) async {
    final draft = await Navigator.push<TemplateDraft>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTemplatePage()),
    );
    if (draft == null) return;

    templates.insert(0, jsonEncode(draft.toJson())); // 新模板排最前
    notifyListeners();
    await _persist();
    debugPrint('【新建】已保存: ${draft.name}');
  }

  /// 编辑：传入旧草稿回填，保存后覆盖原位置
  Future<void> editTemplate(BuildContext context, int index) async {
    final oldDraft = TemplateDraft.fromJson(templates[index]);

    final draft = await Navigator.push<TemplateDraft>(
      context,
      MaterialPageRoute(builder: (_) => CreateTemplatePage(initial: oldDraft)),
    );
    if (draft == null) return;

    templates[index] = jsonEncode(draft.toJson());
    notifyListeners();
    await _persist();
    debugPrint('【编辑】已保存: ${draft.name}');
  }

  /// 删除
  Future<void> deleteTemplate(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模板'),
        content: Text('确定删除「${TemplateDraft.fromJson(templates[index]).name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirmed != true) return;

    templates.removeAt(index);
    notifyListeners();
    await _persist();
  }

  /// 分享
  Future<void> shareTemplate(int index) async {
    debugPrint('分享：${TemplateDraft.fromJson(templates[index]).name}');
  }

  /// 自启动
  Future<void> selfstartingTemlate(int index) async {
    debugPrint('自启动：${TemplateDraft.fromJson(templates[index]).name}');
  }
}
