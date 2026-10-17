import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../all_template/base/key_widget.dart';
import '../all_template/base/template_document.dart';
import '../all_template/custom_template/snap_engine.dart';
import '../all_template/custom_template/editor_canvas.dart';
import '../all_template/custom_template/property_panel.dart';
import '../all_template/custom_template/background_crop.dart';
import '../../app_config.dart';

/// 模板编辑器：全屏画布 + 悬浮顶栏(名称) + 悬浮工具条。
/// 画布全屏铺放，globalPosition == 画布坐标，几何计算无偏移。
///
/// ★ 独立宽高：sizeW/sizeH 取代单一 size；编辑器提供三个缩放柄。
/// ★ 双指缩放：双指拉升整体放大/缩小画布视图（0.3× ~ 3.0×）。
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
  late final TextEditingController _nameCtrl;
  late List<KeyWidget> _widgets;
  String? _selId;
  List<GuideLine> _guides = [];
  Size _canvas = Size.zero;

  /// 画布缩放（双指拉升 / 工具栏 ± 按钮）
  double _canvasScale = 1.0;

  /// ★ 背景图片
  String? _bgImage;
  double _bgOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    _name = ini?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);
    _widgets = List.of(ini?.widgets ?? []);
    _bgImage = ini?.backgroundImage;
    _bgOpacity = ini?.backgroundOpacity ?? 1.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  // ── 拖动（带吸附；delta 需除以画布缩放）──
  void _onDrag(KeyWidget w, Offset delta) {
    final sd = delta / _canvasScale;               // ★ 缩放补偿
    var c = w.centerPx(_canvas).translate(sd.dx, sd.dy);
    final others = [
      for (final o in _widgets)
        if (o.id != w.id) o.aabbPx(_canvas),
    ];
    final r = SnapEngine.snapMove(c, w.halfWPx(_canvas), w.halfHPx(_canvas), _canvas, others);
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

  // ── 旋转（45° 吸附；gp 需除以画布缩放）──
  void _onRotate(KeyWidget w, Offset gp) {
    final sp = gp / _canvasScale;                   // ★ 缩放补偿
    final c = w.centerPx(_canvas);
    var deg = math.atan2(sp.dy - c.dy, sp.dx - c.dx) * 180 / math.pi + 90;
    deg = (deg % 360 + 360) % 360;
    final snapped = (deg / 45).round() * 45.0;
    if ((deg - snapped).abs() <= 7) deg = snapped % 360;
    _upd(w.copyWith(rotation: deg % 360));
  }

  // ── 缩放：三种模式 ——
  void _onResize(KeyWidget w, Offset gp, ResizeMode mode) {
    final sp = gp / _canvasScale;                   // ★ 缩放补偿
    final c = w.centerPx(_canvas);
    final d = sp - c;
    final ct = math.cos(w.rotationRad), st = math.sin(w.rotationRad);
    final lx =  d.dx * ct + d.dy * st;   // 逆旋转到本地系 x
    final ly = -d.dx * st + d.dy * ct;   // 逆旋转到本地系 y

    double newHalfW, newHalfH;

    switch (mode) {
      case ResizeMode.uniform:
        // 右下角 → 沿 45° 对角线投影，维持原有宽高比
        final half = ((lx + ly) / 2).clamp(14.0, _canvas.width * 2.0);
        final oldRatio = w.sizeW / (w.sizeH == 0 ? .01 : w.sizeH);
        final newW = (2 * half / _canvas.width).clamp(.02, 4.0);
        final newH = (newW / oldRatio).clamp(.02, 4.0);
        newHalfW = newW * _canvas.width / 2;
        newHalfH = newH * _canvas.height / 2;
        break;

      case ResizeMode.width:
        // 右侧边缘 → 仅改宽度（lx 为正时拉宽，为负时压窄）
        newHalfW = lx.abs().clamp(14.0, _canvas.width * 2.0);
        newHalfH = w.halfHPx(_canvas);
        break;

      case ResizeMode.height:
        // 下侧边缘 → 仅改高度（ly 为正时拉高，为负时压矮）
        newHalfW = w.halfWPx(_canvas);
        newHalfH = ly.abs().clamp(14.0, _canvas.height * 2.0);
        break;
    }

    // 吸附：对"他人的边到中心的距离"
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
    if (mode == ResizeMode.uniform || mode == ResizeMode.width) {
      newHalfW = SnapEngine.snapScalar(newHalfW, cands);
    }
    if (mode == ResizeMode.uniform || mode == ResizeMode.height) {
      newHalfH = SnapEngine.snapScalar(newHalfH, cands);
    }

    // ★ 摇杆强制等比：取宽高平均值
    if (w.shape == KShape.joystick) {
      final avg = (newHalfW + newHalfH) / 2;
      newHalfW = avg;
      newHalfH = avg;
    }

    final newSizeW =
        (2 * newHalfW / _canvas.width).clamp(.05, 4.0);
    final newSizeH =
        (2 * newHalfH / _canvas.height).clamp(.05, 4.0);
    _upd(w.copyWith(
      sizeW: newSizeW,
      sizeH: newSizeH,
    ));
  }

  // ── 画布缩放 ──
  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _canvasScale = (_canvasScale * d.scale).clamp(0.3, 3.0);
    });
  }

  // ── 层级 / 复制 / 删除 ──
  void _reorder(int dir) {
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
        sizeW: s.sizeW, sizeH: s.sizeH,
        rotation: s.rotation,
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
    final widgets = [
      for (final w in _widgets)
        w.copyWith(key: w.key.trim().isEmpty ? 'a' : w.key.trim()),
    ];
    Navigator.pop(
      context,
      TemplateDraft(
        name: name,
        widgets: widgets,
        backgroundImage: _bgImage,
        backgroundOpacity: _bgOpacity,
      ),
    );
  }

  /// ★ 打开背景图片裁剪页
  Future<void> _openBackgroundCrop() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => BackgroundCropPage(
          widgets: _widgets,
          existingPath: _bgImage,
          initialOpacity: _bgOpacity,
        ),
      ),
    );
    // null = 用户清除了背景
    setState(() {
      _bgImage = result?['path'] as String?;
      _bgOpacity = (result?['opacity'] as num?)?.toDouble() ?? 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      body: LayoutBuilder(builder: (context, cons) {
        _canvas = cons.biggest;
        return Stack(children: [
          // ★ 背景图片层（最底）
          if (_bgImage != null && File(_bgImage!).existsSync())
            Positioned.fill(
              child: Opacity(
                opacity: _bgOpacity,
                child: Image.file(
                  File(_bgImage!),
                  fit: BoxFit.cover,
                  width: _canvas.width,
                  height: _canvas.height,
                ),
              ),
            ),
          // 画布（全屏）+ 双指缩放手势
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) {},            // 必须提供才能触发 onScaleUpdate
              onScaleUpdate: _onScaleUpdate,
              child: Transform.scale(
                scale: _canvasScale,
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
            ),
          ),
          // 顶栏（不随画布缩放）
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 12, right: 12,
            child: _topBar(),
          ),
          // 底部工具条（不随画布缩放）
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
                controller: _nameCtrl,
                onChanged: (v) => _name = v,
                decoration: const InputDecoration(
                  hintText: '模板名称', border: InputBorder.none,
                ),
              ),
            ),
            // ★ 修复 bug：旧写法 '$_widgets 个组件' 会打印列表实例的 toString，
            //   应为 _widgets.length 取组件个数
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${_widgets.length} 个组件',
                style: TextStyle(color: Colors.blueGrey.shade400),
              ),
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
          child: SingleChildScrollView(   // 横向滑动来适应横竖屏以及屏幕尺寸不同带来的越界
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _tb(Icons.crop_square, '方', () => _add(KShape.square)),
              _tb(Icons.circle_outlined, '圆', () => _add(KShape.circle)),
              // ★ 摇杆组件（实验性功能）
              ValueListenableBuilder<bool>(
                valueListenable: AppConfig.experimentalMode,
                builder: (_, exp, __) => exp
                    ? _tb(Icons.games, '摇杆', () => _add(KShape.joystick))
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
              _tb(Icons.image, '背景', _openBackgroundCrop),
              const SizedBox(width: 6),
              // ★ 缩放按钮
              _tb(Icons.zoom_out, '缩小', () {
                setState(() => _canvasScale = (_canvasScale - 0.15).clamp(0.3, 3.0));
              }),
              Text(
                '${(_canvasScale * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              _tb(Icons.zoom_in, '放大', () {
                setState(() => _canvasScale = (_canvasScale + 0.15).clamp(0.3, 3.0));
              }),
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