import 'dart:convert';
import 'key_widget.dart';

/// 模板文档。列表顺序即 z 顺序（后创建 = 上层，渲染与命中同规则）。
/// 对外 API（name / toJson / fromJson）与现有 TemplateService 完全兼容。
class TemplateDraft {
  const TemplateDraft({required this.name, required this.widgets});
  final String name;
  final List<KeyWidget> widgets;

  Map<String, dynamic> toJson() => {
    'v': 1,                                    // ★ 版本号，未来格式升级用
    'name': name,
    'ws': [for (final w in widgets) w.toMap()],
  };

  factory TemplateDraft.fromJson(String raw) =>
      TemplateDraft.fromMap(jsonDecode(raw) as Map<String, dynamic>);

  /// 安全解析：旧版本存档（纯文本如"预设模板A"）或损坏 JSON 返回 null
  /// 而不是抛异常 —— 列表页每帧 build 都在解析存档，绝不能在这里炸
  static TemplateDraft? tryParse(String raw) {
    try {
      return TemplateDraft.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  factory TemplateDraft.fromMap(Map<String, dynamic> m) {
    var i = 0;
    return TemplateDraft(
      name: ((m['name'] ?? '未命名') as String).trim().isEmpty
          ? '未命名' : (m['name'] as String),
      widgets: [
        for (final raw in (m['ws'] as List? ?? []))
          KeyWidget.fromMap((raw as Map).cast<String, dynamic>(), 'k${i++}'),
        // id 在导入时统一重生成，避免与本地模板冲突
      ],
    );
  }
}
