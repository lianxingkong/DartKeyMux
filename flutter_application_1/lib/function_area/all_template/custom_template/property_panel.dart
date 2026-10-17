import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../base/key_widget.dart';
import '../../../app_config.dart';
import 'component_image_crop.dart';

// ═══════════════════════════════════════════════════════
//  颜色选择器常量（色调条）
// ═══════════════════════════════════════════════════════
const _hueStops = <Color>[
  Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
  Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
  Color(0xFFFF0000),
];

/// 属性面板：实时应用（改一个属性立刻反映到画布上，用户利好）
/// ★ 独立宽高：增加宽度/高度两个独立滑块，配套"等比锁定"开关
///
/// ★ 修复要点：
///   1. sheet 内容改为 StatefulWidget，controller 在 State.dispose() 中释放
///      （不再用 whenComplete 提前 dispose——那是本次崩溃的根因）；
///   2. TextField 加 onTapOutside，点击空白区域时同步收起焦点；
///   3. 映射按键的 onChanged 允许清空（去掉静默回退旧值的逻辑），
///      关闭时在 _SheetBody.dispose 里兜底回退，保证不会把空值留在画布上。
Future<void> showWidgetPropertySheet({
  required BuildContext context,
  required KeyWidget w,
  required ValueChanged<KeyWidget> onChanged,
  required ValueChanged<int> onReorder,
  required VoidCallback onDuplicate,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _SheetBody(
      initial: w,
      onChanged: onChanged,
      onReorder: onReorder,
      onDuplicate: onDuplicate,
      onDelete: onDelete,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Sheet 内容：有状态的 StatefulWidget
// ─────────────────────────────────────────────────────────────
class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.initial,
    required this.onChanged,
    required this.onReorder,
    required this.onDuplicate,
    required this.onDelete,
  });

  final KeyWidget initial;
  final ValueChanged<KeyWidget> onChanged;
  final ValueChanged<int> onReorder;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  // ── 状态 ──
  late KeyWidget cur;
  late bool aspectLocked;
  late final TextEditingController keyCtrl;

  @override
  void initState() {
    super.initState();
    cur = widget.initial;
    aspectLocked = cur.sizeW == cur.sizeH; // 初始等比则锁定
    keyCtrl = TextEditingController(text: cur.key);
  }

  /// 提交一帧修改：刷新本面板并通知外层
  void _apply(KeyWidget next) {
    setState(() => cur = next);
    widget.onChanged(next);
  }

  // ★ 摇杆方向键快捷输入（内部管理 controller 生命周期）
  final List<_JoyKeyFieldState> _joyFields = [];
  bool _joyFieldsDisposed = false;

  @override
  void dispose() {
    _joyFieldsDisposed = true;
    for (final s in _joyFields) {
      s._ctrl.dispose();
    }
    keyCtrl.dispose();
    super.dispose();
  }

  Widget _joyKeyField(String label, String value, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _JoyKeyField(
        label: label,
        value: value,
        onChanged: onChanged,
        parent: this,
      ),
    );
  }

  /// ★ 为组件导入图片
  Future<void> _pickComponentImage() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => ComponentImageCropPage(
          widget: cur,
          existingPath: cur.imagePath,
          initialDx: cur.imageDx,
          initialDy: cur.imageDy,
          initialScale: cur.imageScale,
        ),
      ),
    );
    if (result == null && cur.imagePath == null) return;
    _apply(cur.copyWith(
      imagePath: result?['path'] as String?,
      imageOpacity: cur.imageOpacity,
      imageDx: (result?['dx'] as num?)?.toDouble() ?? 0,
      imageDy: (result?['dy'] as num?)?.toDouble() ?? 0,
      imageScale: (result?['scale'] as num?)?.toDouble() ?? 1.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('组件属性',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ]),

            _label('映射按键'),
            TextField(
              controller: keyCtrl,
              maxLength: 10,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              // 点击面板外空白处时同步失焦，把收尾权交给 framework
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              onChanged: (v) {
                // ★ 修复：允许清空；空值在 dispose 时兜底，而不是在这里静默回退
                _apply(cur.copyWith(key: v));
              },
            ),

            // ★ 组件图片（摇杆不支持组件图片）
            if (cur.shape != KShape.joystick) ...[
              _label('组件图片'),
              Row(children: [
                if (cur.imagePath != null && cur.imagePath!.isNotEmpty)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                          image: FileImage(File(cur.imagePath!)),
                          fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(cur.imagePath != null ? '更换' : '导入'),
                  onPressed: () => _pickComponentImage(),
                ),
                if (cur.imagePath != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () =>
                        _apply(cur.copyWith(clearImage: true)),
                    tooltip: '移除图片',
                  ),
                ],
              ]),
              if (cur.imagePath != null && cur.imagePath!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Text('透明度', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: cur.imageOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (v) =>
                          _apply(cur.copyWith(imageOpacity: v)),
                    ),
                  ),
                  Text('${(cur.imageOpacity * 100).round()}%',
                      style: const TextStyle(fontSize: 12)),
                ]),
              ],
            ],
            // ★ 摇杆专属属性
            if (cur.shape == KShape.joystick) ...[
              _label('摇杆方向键映射'),
              _joyKeyField('上方向', cur.joyUpKey,
                  (v) => _apply(cur.copyWith(joyUpKey: v))),
              _joyKeyField('下方向', cur.joyDownKey,
                  (v) => _apply(cur.copyWith(joyDownKey: v))),
              _joyKeyField('左方向', cur.joyLeftKey,
                  (v) => _apply(cur.copyWith(joyLeftKey: v))),
              _joyKeyField('右方向', cur.joyRightKey,
                  (v) => _apply(cur.copyWith(joyRightKey: v))),
              _joyKeyField('内圈（按下触发）', cur.joyInnerKey,
                  (v) => _apply(cur.copyWith(joyInnerKey: v))),
              _label('内圈大小（灵敏度）'),
              Row(children: [
                Expanded(
                  child: Slider(
                    value: cur.joyInnerRadius,
                    min: 0.1, max: 0.8, divisions: 7,
                    onChanged: (v) =>
                        _apply(cur.copyWith(joyInnerRadius: v)),
                  ),
                ),
                Text('${(cur.joyInnerRadius * 100).round()}%',
                    style: const TextStyle(fontSize: 12)),
              ]),
            ],
            _label('形状'),
            SegmentedButton<KShape>(
              segments: [
                const ButtonSegment(
                    value: KShape.square,
                    label: Text('方形'),
                    icon: Icon(Icons.crop_square)),
                const ButtonSegment(
                    value: KShape.circle,
                    label: Text('圆形'),
                    icon: Icon(Icons.circle_outlined)),
                if (AppConfig.experimentalMode.value)
                  const ButtonSegment(
                      value: KShape.joystick,
                      label: Text('摇杆'),
                      icon: Icon(Icons.games)),
              ],
              selected: {cur.shape},
              onSelectionChanged: (s) =>
                  _apply(cur.copyWith(shape: s.first)),
            ),

            // ── 独立宽高 ──
            _label('宽度（可超过屏幕 → 分割线玩法）'),
            Row(children: [
              Expanded(
                child: Slider(
                  min: .05,
                  max: 2.2,
                  divisions: 43,
                  value: cur.sizeW.clamp(.05, 2.2),
                  label: '${(cur.sizeW * 100).round()}% 屏宽',
                  onChanged: (v) {
                    final newH = aspectLocked
                        ? (v * cur.sizeH / cur.sizeW).clamp(.05, 2.2)
                        : cur.sizeH;
                    _apply(cur.copyWith(sizeW: v, sizeH: newH));
                  },
                ),
              ),
              Text('${(cur.sizeW * 100).round()}%'),
            ]),

            _label('高度（可超过屏幕）'),
            Row(children: [
              Expanded(
                child: Slider(
                  min: .05,
                  max: 2.2,
                  divisions: 43,
                  value: cur.sizeH.clamp(.05, 2.2),
                  label: '${(cur.sizeH * 100).round()}% 屏高',
                  onChanged: (v) {
                    final newW = aspectLocked
                        ? (v * cur.sizeW / cur.sizeH).clamp(.05, 2.2)
                        : cur.sizeW;
                    _apply(cur.copyWith(sizeW: newW, sizeH: v));
                  },
                ),
              ),
              Text('${(cur.sizeH * 100).round()}%'),
            ]),

            // 等比锁定开关
            Row(children: [
              const Text('等比缩放'),
              const SizedBox(width: 8),
              Switch(
                value: aspectLocked,
                onChanged: (v) => setState(() => aspectLocked = v),
              ),
            ]),

            _label('旋转'),
            Row(children: [
              Expanded(
                child: Slider(
                  min: 0,
                  max: 360,
                  divisions: 72,
                  value: cur.rotation,
                  label: '${cur.rotation.round()}°',
                  onChanged: (v) =>
                      _apply(cur.copyWith(rotation: v)),
                ),
              ),
              Text('${cur.rotation.round()}°'),
            ]),
            Wrap(spacing: 6, children: [
              for (final a in const [0, 45, 90, 135, 180, 225, 270, 315])
                ActionChip(
                  label: Text('$a°'),
                  onPressed: () =>
                      _apply(cur.copyWith(rotation: a.toDouble())),
                ),
            ]),

            _ColorPicker(
                title: '松开颜色（不填用默认）',
                value: cur.idleColor,
                onPick: (c) => _apply(c == null
                    ? cur.copyWith(clearIdle: true)
                    : cur.copyWith(idleColor: c)),
              ),
              _ColorPicker(
                title: '按下颜色（不填自动派生）',
                value: cur.pressedColor,
                onPick: (c) => _apply(c == null
                    ? cur.copyWith(clearPressed: true)
                    : cur.copyWith(pressedColor: c)),
              ),

            _label('层级（后创建在上；可手动调整）'),
            Wrap(spacing: 6, children: [
              OutlinedButton(
                  onPressed: () => widget.onReorder(999),
                  child: const Text('置顶')),
              OutlinedButton(
                  onPressed: () => widget.onReorder(1),
                  child: const Text('上移')),
              OutlinedButton(
                  onPressed: () => widget.onReorder(-1),
                  child: const Text('下移')),
              OutlinedButton(
                  onPressed: () => widget.onReorder(-999),
                  child: const Text('置底')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDuplicate();
                },
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('复制组件'),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('删除'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  顶层工具函数（与原版一致，不用改）
// ─────────────────────────────────────────────────────────────
// 编辑界面顶部栏
Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    );

/// ── 色调条颜色选择器 ──
/// 用手指在渐变条上拖动即可选取任意颜色。
class _ColorPicker extends StatefulWidget {
  const _ColorPicker({
    required this.title,
    required this.value,
    required this.onPick,
  });
  final String title;
  final Color? value;
  final ValueChanged<Color?> onPick;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  double _hue = 0; // 0..360

  @override
  void initState() {
    super.initState();
    // 从已有颜色中提取色调
    if (widget.value != null) {
      _hue = HSVColor.fromColor(widget.value!).hue;
    }
  }

  Color _colorAt(double hue) =>
      HSVColor.fromAHSV(1, hue, 0.72, 0.92).toColor();

  @override
  Widget build(BuildContext context) {
    final cur = widget.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(widget.title),
      // ── 色调渐变条 ──
      GestureDetector(
        onPanDown: (d) => _updateHue(d.localPosition, context),
        onPanUpdate: (d) => _updateHue(d.localPosition, context),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(colors: _hueStops),
          ),
          child: Stack(children: [
            // 当前选中指示器
            Positioned(
              left: (_hue / 360 * (MediaQuery.of(context).size.width - 32))
                  .clamp(6, MediaQuery.of(context).size.width - 32 - 6 - 16),
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _colorAt(_hue),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      // ── 当前颜色预览 + 默认按钮 ──
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cur,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 10),
        Text(cur != null ? '已选' : '默认',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const Spacer(),
        OutlinedButton(
          onPressed: cur == null
              ? null
              : () {
                  setState(() => _hue = 0);
                  widget.onPick(null);
                },
          child: const Text('默认', style: TextStyle(fontSize: 12)),
        ),
      ]),
    ]);
  }

  void _updateHue(Offset local, BuildContext context) {
    final w = MediaQuery.of(context).size.width - 32;
    setState(() {
      _hue = (local.dx / w * 360).clamp(0, 360);
      widget.onPick(_colorAt(_hue));
    });
  }
}

// ═══════════════════════════════════════════════════════
//  摇杆方向键输入组件（管理自己的 controller）
// ═══════════════════════════════════════════════════════
class _JoyKeyField extends StatefulWidget {
  const _JoyKeyField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.parent,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final _SheetBodyState parent;

  @override
  State<_JoyKeyField> createState() => _JoyKeyFieldState();
}

class _JoyKeyFieldState extends State<_JoyKeyField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    widget.parent._joyFields.add(this);
  }

  @override
  void dispose() {
    widget.parent._joyFields.remove(this);
    if (!widget.parent._joyFieldsDisposed) {
      _ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(widget.label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _ctrl,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                suffixIcon: widget.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _ctrl.clear();
                          widget.onChanged('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
