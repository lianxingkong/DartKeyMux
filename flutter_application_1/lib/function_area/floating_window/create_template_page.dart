import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../all_template/base/key_widget.dart';
import '../all_template/base/template_document.dart';
import '../all_template/custom_template/snap_engine.dart';
import '../all_template/custom_template/editor_canvas.dart';
import '../all_template/custom_template/property_panel.dart';

/// 模板编辑器：全画画布 + 悬浮顶栏(名称) + 悬浮工具条。
/// 画布全屏铺放，globalPosition == 画布坐标，几何计算无偏移。
class CreateTemplatePage extends StatefulWidget {
  const CreateTemplatePage({super.key, this.initial, this.editIndex = -1});

    /// 编辑已有模板：index >= 0 时，调用方按"覆盖第 index 个"处理返回值
  const CreateTemplatePage.withDraft(TemplateDraft draft, int index)
      : initial = draft,
        editIndex = index;

  final TemplateDraft? initial;
  final int editIndex;

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  late String _name;
  // ★ 只创建一次、页面销毁时释放。旧写法在每次 build 里
  //   new 一个 TextEditingController（带空 listener）→ 逐帧泄漏，
  //   且页面 rebuild 时名字输入框丢失光标/文本。
  late final TextEditingController _nameCtrl;
  late List<KeyWidget> _widgets; // 顺序即层级：靠后 = 上层（需求5）
  String? _selId;
  List<GuideLine> _guides = [];
  Size _canvas = Size.zero;

  @override
  void initState() {
    super.initState();
    _name = widget.initial?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);
    _widgets = List.of(widget.initial?.widgets ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); // ★ 释放，防泄漏
    super.dispose();
  }

  KeyWidget? get _sel =>
      _widgets.where((w) => w.id == _selId).firstOrNull;

  void _upd(KeyWidget w) => setState(() {
    final i = _widgets.indexWhere((e) => e.id == w.id);
    if (i >= 0) _widgets[i] = w;
  });

  // ── 新建（放在画布中心）──
  void _add(KShape shape) => setState(() {
    final w = KeyWidget.spawn(shape, Offset(_canvas.width / 2, _canvas.height / 2), _canvas);
    _widgets.add(w);
    _selId = w.id;
  });

  // ── 拖动（带吸附）──
  void _onDrag(KeyWidget w, Offset delta) {
    var c = w.centerPx(_canvas).translate(delta.dx, delta.dy);
    final others = [
      for (final o in _widgets)
        if (o.id != w.id) o.aabbPx(_canvas),
    ];
    final r = SnapEngine.snapMove(c, w.halfPx(_canvas), _canvas, others);
    setState(() {
      _guides = r.guides;
      final i = _widgets.indexWhere((e) => e.id == w.id);
      if (i >= 0) {
        _widgets[i] = w.copyWith(
          cx: r.center.dx / _canvas.width,
          cy: r.center.dy / _canvas.height,
        );
      }
    });
  }

  void _onDragEnd() => setState(() => _guides = []);

  // ── 旋转（45° 吸附）──
  void _onRotate(KeyWidget w, Offset gp) {
    final c = w.centerPx(_canvas);
    var deg = math.atan2(gp.dy - c.dy, gp.dx - c.dx) * 180 / math.pi + 90;
    deg = (deg % 360 + 360) % 360;
    final snapped = (deg / 45).round() * 45.0;
    if ((deg - snapped).abs() <= 7) deg = snapped % 360;
    _upd(w.copyWith(rotation: deg % 360));
  }

  // ── 缩放：柄在本地 45° 对角线上，投影即新 half；对“他人的边到中心的距离”吸附 ──
  void _onResize(KeyWidget w, Offset gp) {
    final c = w.centerPx(_canvas);
    final d = gp - c;
    final ct = math.cos(w.rotationRad), st = math.sin(w.rotationRad);
    final lx =  d.dx * ct + d.dy * st;   // 逆旋转到本地系
    final ly = -d.dx * st + d.dy * ct;
    var half = ((lx + ly) / 2).clamp(14.0, _canvas.width * 2.0); // 需求3：可越界放大
    final cands = <double>[];
    for (final o in _widgets) {
      if (o.id == w.id) continue;
      final r = o.aabbPx(_canvas);
      cands
        ..add((r.left - c.dx).abs())
        ..add((r.right - c.dx).abs())
        ..add((r.top - c.dy).abs())
        ..add((r.bottom - c.dy).abs());
    }
    half = SnapEngine.snapScalar(half, cands);
    _upd(w.copyWith(size: 2 * half / _canvas.width));
  }

  // ── 层级 / 复制 / 删除 ──
  void _reorder(int dir) { // +1 上移 / -1 下移 / ±999 置顶/置底
    final i = _widgets.indexWhere((e) => e.id == _selId);
    if (i < 0) return;
    setState(() {
      final w = _widgets.removeAt(i);
      var j = i + dir;
      if (j < 0) j = 0;
      if (j > _widgets.length) j = _widgets.length;
      _widgets.insert(j, w);
    });
  }

  void _duplicate() {
    final s = _sel;
    if (s == null) return;
    setState(() {
      final i = _widgets.indexOf(s);
      final w = KeyWidget(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        shape: s.shape, key: s.key,
        cx: (s.cx + .04).clamp(-1.0, 2.0),
        cy: (s.cy + .04).clamp(-1.0, 2.0),
        size: s.size, rotation: s.rotation,
        idleColor: s.idleColor, pressedColor: s.pressedColor,
      );
      _widgets.insert(i + 1, w);
      _selId = w.id;
    });
  }

  void _delete() => setState(() {
    _widgets.removeWhere((e) => e.id == _selId);
    _selId = null;
  });

  Future<void> _openProps() async {
    final s = _sel;
    if (s == null) return;
    await showWidgetPropertySheet(
      context: context,
      w: s,
      onChanged: _upd,
      onReorder: _reorder,
      onDuplicate: _duplicate,
      onDelete: _delete,
    );
  }

  void _save() {
    if (_widgets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('至少放一个组件再保存哦')));
      return;
    }
    final name = _name.trim().isEmpty ? '未命名模板' : _name.trim();
    // ★ 键位兜底：映射键被清空/纯空白时回落到 'a'，
    //   防止空字符串进存档、之后作为 rune 发给后端引发不可控行为
    final widgets = [
      for (final w in _widgets)
        w.copyWith(key: w.key.trim().isEmpty ? 'a' : w.key.trim()),
    ];
    Navigator.pop(context, TemplateDraft(name: name, widgets: widgets));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      body: LayoutBuilder(builder: (context, cons) {
        _canvas = cons.biggest; // 布局期间缓存，供回调使用
        return Stack(children: [
          // 画布（全屏，最底层）
          Positioned.fill(
            child: EditorCanvas(
              size: _canvas,
              widgets: _widgets,
              selectedId: _selId,
              guides: _guides,
              onBackgroundTap: () => setState(() { _selId = null; _guides = []; }),
              onSelect: (w) => setState(() => _selId = w.id),
              onDrag: _onDrag,
              onDragEnd: _onDragEnd,
              onRotate: _onRotate,
              onResize: _onResize,
            ),
          ),
          // 顶栏
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 12, right: 12,
            child: _topBar(),
          ),
          // 底部工具条
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 0, right: 0,
            child: _toolbar(),
          ),
        ]);
      }),
    );
  }

  Widget _topBar() => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(children: [
            const BackButton(),
            Expanded(
              child: TextField(
                controller: _nameCtrl, // ★ 不再每次 build 新建 controller
                onChanged: (v) => _name = v,
                decoration: const InputDecoration(
                  hintText: '模板名称', border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('$_widgets 个组件', style: TextStyle(color: Colors.blueGrey.shade400)),
            ),
          ]),
        ),
      );

  Widget _toolbar() {
    final hasSel = _sel != null;
    return Center(
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(32),
        color: Colors.blueGrey.shade900,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _tb(Icons.crop_square, '方', () => _add(KShape.square)),
            _tb(Icons.circle_outlined, '圆', () => _add(KShape.circle)),
            const SizedBox(width: 6),
            _tb(Icons.tune, '属性', _openProps, enabled: hasSel),
            _tb(Icons.copy_all_outlined, '复制', _duplicate, enabled: hasSel),
            _tb(Icons.delete_outline, '删除', _delete, enabled: hasSel, red: true),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('保存'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tb(IconData i, String label, VoidCallback onTap,
      {bool enabled = true, bool red = false}) {
    final c = enabled ? (red ? Colors.redAccent : Colors.white) : Colors.white30;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(i, color: c),
        tooltip: label,
      ),
    );
  }
}
