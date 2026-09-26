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
  static const _storageKeyAutoStartIndex = 'auto_start_index';
  static const _storageKeyAutoStartMaster = 'auto_start_master';

  List<String> templates = ['预设模板A'];

  int? _autoStartIndex;            // 当前拥有自启动属性的模板下标（null = 无）
  bool _autoStartMasterEnabled = false;  // 侧边栏总开关

  bool _loaded = false; // 防止重复读档

  // ---------- 自启动 getter ----------
  int? get autoStartIndex => _autoStartIndex;
  bool get autoStartMasterEnabled => _autoStartMasterEnabled;

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
      }

      // ★ 自启动设置
      final autoIdx = prefs.getInt(_storageKeyAutoStartIndex);
      _autoStartIndex = autoIdx;
      _autoStartMasterEnabled = prefs.getBool(_storageKeyAutoStartMaster) ?? false;

      // 校验下标合法性（模板可能已被删除）
      if (_autoStartIndex != null &&
          (_autoStartIndex! < 0 || _autoStartIndex! >= templates.length)) {
        _autoStartIndex = null;
      }

      notifyListeners();
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

  Future<void> _persistAutoStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_autoStartIndex != null) {
        await prefs.setInt(_storageKeyAutoStartIndex, _autoStartIndex!);
      } else {
        await prefs.remove(_storageKeyAutoStartIndex);
      }
      await prefs.setBool(_storageKeyAutoStartMaster, _autoStartMasterEnabled);
      debugPrint('【存盘-自启动】index=$_autoStartIndex master=$_autoStartMasterEnabled');
    } catch (e) {
      debugPrint('【存盘-自启动】异常: $e');
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
    // 插入导致所有旧模板下标 +1，自启动下标也需同步
    if (_autoStartIndex != null) {
      _autoStartIndex = _autoStartIndex! + 1;
      await _persistAutoStart();
    }
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

    // 如果删除的刚好是自启动模板，清除自启动属性
    if (_autoStartIndex == index) {
      _autoStartIndex = null;
      await _persistAutoStart();
    } else if (_autoStartIndex != null && _autoStartIndex! > index) {
      // 删除导致下标前移，自启动下标需减1
      _autoStartIndex = _autoStartIndex! - 1;
      await _persistAutoStart();
    }

    notifyListeners();
    await _persist();
  }


  /// 分享：导出紧凑码 → 复制剪贴板（如需系统分享面板，接 share_plus 即可）
  Future<void> shareTemplate(BuildContext context, int index) async {
    final code = TemplateCodec.export(draftAt(index));
    await Clipboard.setData(ClipboardData(text: code));
    debugPrint('已复制分享码（${code.length} 字符）: $code');

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('已复制'),
        content: const Text('分享码已复制到剪贴板'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }


  /// 导入：解析 + sanitize；失败返回 false
  Future<bool> importTemplate(String raw) async {
    debugPrint('【导入】开始，收到 ${raw.length} 字符，前20字符: ${raw.substring(0, raw.length.clamp(0, 20))}');
    final draft = TemplateCodec.import(raw);
    debugPrint('【导入】解析完成: ${draft?.name}');
    if (draft == null) return false;
    templates.insert(0, jsonEncode(draft.toJson()));
    // 插入导致所有旧模板下标 +1，自启动下标也需同步
    if (_autoStartIndex != null) {
      _autoStartIndex = _autoStartIndex! + 1;
      await _persistAutoStart();
    }
    debugPrint('【导入】已插入列表');
    notifyListeners();
    await _persist();
    debugPrint('【导入】存盘完成');
    return true;
  }


  /// 自启动：同一模板再次点击 = 取消；不同模板 = 转移自启动属性
  Future<void> selfstartingTemlate(int index) async {
    if (_autoStartIndex == index) {
      _autoStartIndex = null;
      debugPrint('自启动已取消：${draftAt(index).name}');
    } else {
      final prev = _autoStartIndex != null ? '（原：${draftAt(_autoStartIndex!).name}）' : '';
      _autoStartIndex = index;
      debugPrint('自启动已设置：${draftAt(index).name} $prev');
    }
    notifyListeners();
    await _persistAutoStart();
  }

  /// 侧边栏自启动总开关
  Future<void> setAutoStartMaster(bool value) async {
    _autoStartMasterEnabled = value;
    notifyListeners();
    await _persistAutoStart();
    debugPrint('自启动总开关：$value');
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
