import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/function_area/floating_window/create_template_page.dart';
import '../all_template/base/template_document.dart';

import '../services/template_codec.dart';


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

  /// 取第 index 个模板的草稿；解析失败（旧格式纯文本 / 坏 JSON）时
  /// 兜底成“仅保留原字符串为名字”的空模板，保证列表页 build 不抛异常
  TemplateDraft draftAt(int index) {
    if (index < 0 || index >= templates.length) {
      return const TemplateDraft(name: '未知模板', widgets: []);
    }
    final raw = templates[index];
    return TemplateDraft.tryParse(raw) ??
        TemplateDraft(name: raw, widgets: const []);
  }

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
        content: Text('确定删除「${draftAt(index).name}」吗？'),
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

  /// 分享：导出紧凑码 → 复制剪贴板（如需系统分享面板，接 share_plus 即可）
  Future<void> shareTemplate(int index) async {
    final code = TemplateCodec.export(draftAt(index));
    await Clipboard.setData(ClipboardData(text: code));
    debugPrint('已复制分享码（${code.length} 字符）: $code');
  }

  /// 导入：解析 + sanitize；失败返回 false
  Future<bool> importTemplate(String raw) async {
    final draft = TemplateCodec.import(raw);
    if (draft == null) return false;
    templates.insert(0, jsonEncode(draft.toJson()));
    notifyListeners();
    await _persist();
    return true;
  }

  /// 自启动
  Future<void> selfstartingTemlate(int index) async {
    debugPrint('自启动：${draftAt(index).name}');
  }

  /// 覆盖第 index 个模板（越界则当新增）；持久化 + 通知
  void updateTemplate(int index, Map<String, dynamic> json) {
    final s = jsonEncode(json);
    if (index >= 0 && index < templates.length) {
      templates[index] = s;
    } else {
      templates.add(s);
    }
    _persist();   // ← 占位：换成你 service 里真正的落盘调用，见下方说明
    notifyListeners();
  }
}
