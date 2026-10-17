import 'dart:convert';
import 'key_widget.dart';

/// ── 按键联立映射规则 ──
/// 当 triggerKey 被按下（不松开）时，targetKey 对应的组件映射键临时变为 newKey。
/// 松开 triggerKey 时恢复原映射。若 target 已经处于按下状态则不触发。
class KeyChain {
  const KeyChain({
    required this.triggerKey,
    required this.targetKey,
    required this.newKey,
  });

  final String triggerKey; // 触发条件：此键按下
  final String targetKey;  // 被联立的组件原映射键
  final String newKey;     // 临时变为的键

  Map<String, dynamic> toMap() => {
        'tk': triggerKey,
        'tg': targetKey,
        'nk': newKey,
      };

  factory KeyChain.fromMap(Map<String, dynamic> m) => KeyChain(
        triggerKey: (m['tk'] as String?) ?? '',
        targetKey: (m['tg'] as String?) ?? '',
        newKey: (m['nk'] as String?) ?? '',
      );
}

/// 模板文档。列表顺序即 z 顺序（后创建 = 上层，渲染与命中同规则）。
/// 对外 API（name / toJson / fromJson）与现有 TemplateService 完全兼容。
///
/// ★ 新增 type 字段区分键盘模板('keyboard')与鼠标模板('mouse')，
///   鼠标模板额外携带 sensitivity / mouseMode 配置。
class TemplateDraft {
  const TemplateDraft({
    required this.name,
    required this.widgets,
    this.type = 'keyboard',        // 'keyboard' 或 'mouse'
    this.sensitivity = 1.0,       // 仅鼠标模板使用
    this.mouseMode = 0,           // 仅鼠标模板使用：0=拖动, 1=点击
    this.backgroundImage,         // ★ 背景图片路径
    this.backgroundOpacity = 1.0, // ★ 背景透明度 0..1
    this.chains = const [],       // ★ 按键联立链
  });

  final String name;
  final List<KeyWidget> widgets;

  /// 'keyboard' 或 'mouse' —— 用于主页区分编辑/播放路由
  final String type;

  /// 鼠标灵敏度（仅 mouse 类型有效）
  final double sensitivity;

  /// 鼠标触控模式（仅 mouse 类型有效）：0 = 拖动模式, 1 = 点击模式
  final int mouseMode;

  /// ★ 背景图片（本地文件路径）
  final String? backgroundImage;

  /// ★ 背景透明度
  final double backgroundOpacity;

  bool get isMouse => type == 'mouse';
  bool get isKeyboard => type != 'mouse';
  bool get hasBackground => backgroundImage != null && backgroundImage!.isNotEmpty;

  /// ★ 按键联立映射链
  final List<KeyChain> chains;

  bool get hasChains => chains.isNotEmpty;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'v': 1,
      'name': name,
      'ws': [for (final w in widgets) w.toMap()],
    };
    // ★ 只有非默认类型才写入 type，保证旧存档兼容
    if (type != 'keyboard') {
      m['type'] = type;
      m['sensitivity'] = sensitivity;
      m['mouseMode'] = mouseMode;
    }
    // ★ 背景图
    if (backgroundImage != null && backgroundImage!.isNotEmpty) {
      m['bgImg'] = backgroundImage;
      m['bgOpacity'] = backgroundOpacity;
    }
    if (chains.isNotEmpty) {
      m['chains'] = [for (final c in chains) c.toMap()];
    }
    return m;
  }

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
    final t = (m['type'] as String?) ?? 'keyboard';
    return TemplateDraft(
      name: ((m['name'] ?? '未命名') as String).trim().isEmpty
          ? '未命名' : (m['name'] as String),
      widgets: [
        for (final raw in (m['ws'] as List? ?? []))
          KeyWidget.fromMap((raw as Map).cast<String, dynamic>(), 'k${i++}'),
      ],
      type: t,
      sensitivity: (m['sensitivity'] as num?)?.toDouble() ?? 1.0,
      mouseMode: (m['mouseMode'] as int?) ?? 0,
      backgroundImage: m['bgImg'] as String?,
      backgroundOpacity:
          (m['bgOpacity'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
      chains: [
        for (final c in (m['chains'] as List<dynamic>? ?? []))
          KeyChain.fromMap(c as Map<String, dynamic>),
      ],
    );
  }

  /// 复制并覆盖指定字段（不变的部分原样保留）
  TemplateDraft copyWith({
    String? name,
    List<KeyWidget>? widgets,
    String? type,
    double? sensitivity,
    int? mouseMode,
    String? backgroundImage,
    double? backgroundOpacity,
  }) =>
      TemplateDraft(
        name: name ?? this.name,
        widgets: widgets ?? this.widgets,
        type: type ?? this.type,
        sensitivity: sensitivity ?? this.sensitivity,
        mouseMode: mouseMode ?? this.mouseMode,
        backgroundImage: backgroundImage ?? this.backgroundImage,
        backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      );
}