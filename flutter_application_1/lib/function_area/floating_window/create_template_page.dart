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

/// ─────────────────────────────────────────────
///  混合模板「鼠标底层」接口
/// ─────────────────────────────────────────────
///
/// 编辑器只负责把指针事件转交进来，并把返回的 UI 插到对应位置；
/// 具体触控语义（仅移动、不点击、多指忽略…）全部由实现方决定。
/// 具体实现见 `create_mix_template_page.dart`。
abstract class MixBottomLayer {
  /// 保存进草稿的灵敏度
  double get sensitivity;

  /// 保存进草稿的触控模式
  int get mouseMode;

  void dispose();

  /// 指针按下。[hitWidget] 为 true 表示起点落在某个组件上。
  /// 返回 true 表示该指针已被鼠标层接管（画布无需再处理它）。
  bool onDown(PointerDownEvent e, bool hitWidget);

  void onMove(PointerMoveEvent e);
  void onUp(PointerUpEvent e);
  void onCancel(PointerCancelEvent e);

  /// 手指圆点覆盖层（必须不拦截触摸）
  Widget buildOverlay();

  /// 顶栏「混合」标识
  Widget buildBadge(BuildContext context);

  /// 右侧设置抽屉
  Widget buildSettingsDrawer(BuildContext context, VoidCallback onChanged);
}

/// 模板编辑器：全屏画布 + 悬浮顶栏(名称) + 悬浮工具条。
/// 画布全屏铺放，globalPosition == 画布坐标，几何计算无偏移。
///
/// ★ 独立宽高：sizeW/sizeH 取代单一 size；编辑器提供三个缩放柄。
/// ★ 双指缩放：双指拉升整体放大/缩小画布视图（0.3× ~ 3.0×）。
/// ★ 注入 [mixLayerFactory] → 变成「混合模板编辑器」：
///   底层换成鼠标触控层，组件仍走键盘逻辑。
class CreateTemplatePage extends StatefulWidget {
  const CreateTemplatePage({
    super.key,
    this.initial,
    this.editIndex = -1,
    this.mixLayerFactory,
  });

  /// 编辑已有模板：index >= 0 时，调用方按"覆盖第 index 个"处理返回值
  const CreateTemplatePage.withDraft(TemplateDraft draft, int index)
      : initial = draft,
        editIndex = index,
        mixLayerFactory = null;

  final TemplateDraft? initial;
  final int editIndex;

  /// 非空 → 本页为混合模板编辑器，底层由该层提供鼠标触控
  final MixBottomLayer Function()? mixLayerFactory;

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

  // ════════════════════════════════════════════
  //  ★ 混合模板：底层鼠标触控（实现全部在 create_mix_template_page.dart）
  // ════════════════════════════════════════════

  /// 鼠标底层；为 null 即普通键盘模板编辑器
  late final MixBottomLayer? _mixLayer = widget.mixLayerFactory?.call();

  bool get _mix => _mixLayer != null;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 画布缩放（双指拉升 / 工具栏 ± 按钮）
  double _canvasScale = 1.0;

  /// 双指缩放起点时的画布比例
  ///
  /// ★ ScaleUpdateDetails.scale 是「相对本次手势起点」的累计倍率，
  ///   只能在起点值上乘一次；每帧都拿它乘当前值会指数级放大
  ///   （两指稍微张开就一路冲到 3×）。
  double _scaleStartValue = 1.0;

  /// 当前手势的手指数，用于手指数变化时重新起算基准
  int _scalePointerCount = 0;

  /// ★ 背景图片
  String? _bgImage;
  double _bgOpacity = 1.0;

  /// ★ 按键联立链
  List<KeyChain> _chains = [];

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    _name = ini?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);
    _widgets = List.of(ini?.widgets ?? []);
    _bgImage = ini?.backgroundImage;
    _bgOpacity = ini?.backgroundOpacity ?? 1.0;
    _chains = List.of(ini?.chains ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mixLayer?.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════
  //  ★ 指针路由：组件内 → 键盘/画布逻辑；组件外 → 鼠标底层
  // ════════════════════════════════════════════

  /// 全局坐标 → 画布坐标（补偿双指缩放的 Transform.scale）
  Offset _toCanvas(Offset g) {
    if (_canvasScale == 1.0) return g;
    final center = Offset(_canvas.width / 2, _canvas.height / 2);
    return center + (g - center) / _canvasScale;
  }

  /// 是否命中任一组件（上层优先，与渲染 z 序一致）
  bool _hitsWidget(Offset globalPos) {
    final p = _toCanvas(globalPos);
    for (final w in _widgets.reversed) {
      if (w.hitTest(p, _canvas)) return true;
    }
    return false;
  }

  void _mixDown(PointerDownEvent e) =>
      _mixLayer?.onDown(e, _hitsWidget(e.position));

  void _mixMove(PointerMoveEvent e) => _mixLayer?.onMove(e);

  void _mixUp(PointerUpEvent e) => _mixLayer?.onUp(e);

  void _mixCancel(PointerCancelEvent e) => _mixLayer?.onCancel(e);

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
  void _onScaleStart(ScaleStartDetails d) {
    _scaleStartValue = _canvasScale;
    _scalePointerCount = d.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    // 单指拖动中途又落下一根手指：scale 的基准会跳变，
    // 以"当前比例 / 当前 scale"重设起点，保证这一帧画面不跳
    if (d.pointerCount != _scalePointerCount) {
      _scalePointerCount = d.pointerCount;
      _scaleStartValue = d.scale == 0 ? _canvasScale : _canvasScale / d.scale;
      return;
    }
    setState(() {
      _canvasScale = (_scaleStartValue * d.scale).clamp(0.3, 3.0);
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
      // ★ 完整复制：使用 copyWith 保留所有属性，再重建以换新 id
      final dup = s.copyWith(
        cx: (s.cx + .04).clamp(-1.0, 2.0),
        cy: (s.cy + .04).clamp(-1.0, 2.0),
      );
      final w = KeyWidget(
        id: 'w${DateTime.now().millisecondsSinceEpoch}',
        shape: dup.shape, key: dup.key,
        cx: dup.cx, cy: dup.cy,
        sizeW: dup.sizeW, sizeH: dup.sizeH,
        rotation: dup.rotation,
        idleColor: dup.idleColor, pressedColor: dup.pressedColor,
        imagePath: dup.imagePath, imageOpacity: dup.imageOpacity,
        imageDx: dup.imageDx, imageDy: dup.imageDy, imageScale: dup.imageScale,
        joyInnerRadius: dup.joyInnerRadius,
        joyMidRadius: dup.joyMidRadius,
        joyUpKey: dup.joyUpKey, joyDownKey: dup.joyDownKey,
        joyLeftKey: dup.joyLeftKey, joyRightKey: dup.joyRightKey,
        joyInnerKey: dup.joyInnerKey,
        joyMidKey: dup.joyMidKey,
        showKeyLabel: dup.showKeyLabel,
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
        // ★ 混合模板：最底层为鼠标触控层
        type: _mix ? 'mix' : 'keyboard',
        sensitivity: _mixLayer?.sensitivity ?? 1.0,
        mouseMode: _mixLayer?.mouseMode ?? 0,
        backgroundImage: _bgImage,
        backgroundOpacity: _bgOpacity,
        chains: _chains,
      ),
    );
  }

  /// ★ 打开按键联立管理对话框
  Future<void> _openChainsDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => _ChainsDialog(
        chains: _chains,
        widgetKeys: [for (final w in _widgets) w.key],
        onChanged: (newChains) => setState(() => _chains = newChains),
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
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFECEFF1),
      // ★ 混合模板：右侧鼠标底层参数抽屉
      endDrawer: _mixLayer?.buildSettingsDrawer(
        context,
        () => setState(() {}),
      ),
      drawerEnableOpenDragGesture: false,
      body: LayoutBuilder(builder: (context, cons) {
        _canvas = cons.biggest;
        // ★ 混合模板：监听整屏指针，组件外的指针交给鼠标底层
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _mix ? _mixDown : null,
          onPointerMove: _mix ? _mixMove : null,
          onPointerUp: _mix ? _mixUp : null,
          onPointerCancel: _mix ? _mixCancel : null,
          child: Stack(children: [
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
              onScaleStart: _onScaleStart,
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
          // ★ 混合模板：鼠标底层覆盖层（手指圆点，不拦截触摸）
          if (_mix) Positioned.fill(child: _mixLayer!.buildOverlay()),
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
          ]));
        },
      ),
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
            // ★ 混合模板标识（明确底层是鼠标触控）
            if (_mix)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _mixLayer!.buildBadge(context),
              ),
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
              // ★ 按键联立（实验性功能）
              ValueListenableBuilder<bool>(
                valueListenable: AppConfig.experimentalMode,
                builder: (_, exp, __) => exp
                    ? _tb(Icons.link, '联立', _openChainsDialog,
                        active: _chains.isNotEmpty)
                    : const SizedBox.shrink(),
              ),
              // ★ 混合模板：鼠标触控参数
              if (_mix)
                _tb(Icons.touch_app, '触控', () =>
                    _scaffoldKey.currentState?.openEndDrawer()),
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
      {bool enabled = true, bool red = false, bool active = false}) {
    final c = enabled
        ? (red ? Colors.redAccent : (active ? Colors.amber : Colors.white))
        : Colors.white30;
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

/// ── 按键联立管理对话框 ──
///
/// 列表显示所有已配置的链；支持新增与删除。
/// 每条链：按下 triggerKey → 临时将 targetKey 替换为 newKey；
/// 松开 triggerKey 恢复。
class _ChainsDialog extends StatefulWidget {
  const _ChainsDialog({
    required this.chains,
    required this.widgetKeys,
    required this.onChanged,
  });

  final List<KeyChain> chains;
  final List<String> widgetKeys;
  final ValueChanged<List<KeyChain>> onChanged;

  @override
  State<_ChainsDialog> createState() => _ChainsDialogState();
}

class _ChainsDialogState extends State<_ChainsDialog> {
  late List<KeyChain> _chains;

  @override
  void initState() {
    super.initState();
    _chains = List.of(widget.chains);
  }

  void _add() {
    setState(() {
      final first = widget.widgetKeys.isNotEmpty ? widget.widgetKeys.first : '';
      _chains.add(KeyChain(
        triggerKey: first,
        targetKey: first,
        newKey: '', // ★ 留空由用户自定义输入
      ));
    });
  }

  void _remove(int i) {
    setState(() => _chains.removeAt(i));
  }

  void _commit() => widget.onChanged(List.of(_chains));

  @override
  Widget build(BuildContext context) {
    final keys = widget.widgetKeys.toSet().toList()..sort();
    // 常用按键备选
    final presetKeys = <String>{
      ...keys,
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
      'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
      'u', 'v', 'w', 'x', 'y', 'z',
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      'space', 'enter', 'esc', 'tab', 'backspace',
      'up', 'down', 'left', 'right',
    }.toList()..sort();

    return AlertDialog(
      title: Row(children: [
        const Text('按键联立映射', style: TextStyle(fontSize: 18)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: '新增联立',
          onPressed: _add,
        ),
      ]),
      content: SizedBox(
        width: double.maxFinite,
        child: _chains.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                    '暂未设置联立规则。\n\n点击 + 新增一条：按下某个键时，\n另一个组件的映射键临时变为指定键。\n\n三个输入框都可直接输入任意按键\n（如 shift、f1），右侧按钮只是常用键备选。',
                    style: TextStyle(color: Colors.grey)),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _chains.length,
                itemBuilder: (_, i) {
                  final ch = _chains[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text('规则 ${i + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => _remove(i),
                              tooltip: '删除此规则',
                            ),
                          ]),
                          const SizedBox(height: 6),
                          // 触发键
                          Row(children: [
                            const SizedBox(
                                width: 70,
                                child: Text('按下', style: TextStyle(fontSize: 12))),
                            Expanded(
                              child: _KeyInput(
                                value: ch.triggerKey,
                                candidates: presetKeys,
                                onChanged: (v) => setState(() =>
                                    _chains[i] = KeyChain(
                                        triggerKey: v,
                                        targetKey: ch.targetKey,
                                        newKey: ch.newKey)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          // 目标键
                          Row(children: [
                            const SizedBox(
                                width: 70,
                                child: Text('将', style: TextStyle(fontSize: 12))),
                            Expanded(
                              child: _KeyInput(
                                value: ch.targetKey,
                                candidates: presetKeys,
                                onChanged: (v) => setState(() =>
                                    _chains[i] = KeyChain(
                                        triggerKey: ch.triggerKey,
                                        targetKey: v,
                                        newKey: ch.newKey)),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          // 新键
                          Row(children: [
                            const SizedBox(
                                width: 70,
                                child: Text('变为', style: TextStyle(fontSize: 12))),
                            Expanded(
                              child: _KeyInput(
                                value: ch.newKey,
                                candidates: presetKeys,
                                onChanged: (v) => setState(() =>
                                    _chains[i] = KeyChain(
                                        triggerKey: ch.triggerKey,
                                        targetKey: ch.targetKey,
                                        newKey: v)),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            _commit();
            Navigator.pop(context);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// ★ 按键输入框：**默认直接输入自定义值**（不再强制从列表选）。
///
/// 右侧小按钮可展开「常用键」列表快速填入，只是辅助，不限制输入内容。
/// 因此 shift / ctrl / f1 / 任意组合键都能直接敲进去。
class _KeyInput extends StatefulWidget {
  const _KeyInput({
    required this.value,
    required this.candidates,
    required this.onChanged,
  });

  final String value;
  final List<String> candidates;
  final ValueChanged<String> onChanged;

  @override
  State<_KeyInput> createState() => _KeyInputState();
}

class _KeyInputState extends State<_KeyInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _KeyInput old) {
    super.didUpdateWidget(old);
    // 外部值变化（例如从列表填入）时同步；用户正在输入时不打断
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 展开常用键列表（辅助填入，不替代手动输入）
  Future<void> _pickFromList() async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final tl = box.localToGlobal(Offset.zero);
    final br = box.localToGlobal(box.size.bottomRight(Offset.zero));
    final screen = MediaQuery.of(context).size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tl.dx,
        br.dy,
        screen.width - br.dx,
        screen.height - tl.dy,
      ),
      items: [
        for (final k in widget.candidates)
          PopupMenuItem(
            value: k,
            height: 38,
            child: Text(k, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
    if (selected == null) return;
    setState(() => _ctrl.text = selected);
    widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: const TextStyle(fontSize: 13),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        isDense: true,
        hintText: '自定义，如 shift',
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.list_alt, size: 18),
          tooltip: '从常用键中选择（也可直接输入）',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          onPressed: _pickFromList,
        ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 34, minHeight: 34),
      ),
      onChanged: (v) => widget.onChanged(v.trim()),
    );
  }
}