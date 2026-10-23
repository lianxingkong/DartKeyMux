import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../base/key_widget.dart';
import '../base/template_document.dart';
import '../base/key_widget_view.dart';
import '../base/floating_control.dart';
import '../base/mouse_touch_core.dart';
import '../../services/connect_grc.dart';
import '../../setting/mapping_key_page.dart';

// ── 延迟测量探针（方案 C，测完删除本段即可）──────────────────────────────
// 与 MainActivity.kt 的 "dkm_latency" 通道对应，取内核触摸时间戳。
// 日志 tag 固定为 DKM_LAT，便于 `adb logcat` 精确过滤。
const MethodChannel _kLatency = MethodChannel('dkm_latency');
Map<Object?, Object?>? _lastNativeTouchInfo;

/// 把 nativeTimeMs / uptimeMs / wallTimeMs 换算成墙钟时刻（毫秒）
int _nativeWallMs() {
  final info = _lastNativeTouchInfo;
  if (info == null) return -1;
  final native = (info['nativeTimeMs'] as num?)?.toInt() ?? 0;
  final uptime = (info['uptimeMs'] as num?)?.toInt() ?? 0;
  final wall = (info['wallTimeMs'] as num?)?.toInt() ?? 0;
  return wall - (uptime - native);
}
// ──────────────────────────────────────────────────────────────────────────

/// 自定义模板游玩页：
/// - 单个全屏 Listener 接收所有指针，从最上层组件开始做"旋转感知"命中
///   → 层级规则（需求5）与旋转精度一次到位
/// - 指针绑定语义：按下后滑出组件，抬手仍释放同一个键（真实琴键手感）
/// - 多点触控 → 天然支持"模拟键盘"（需求10）
/// - 悬浮控件替代静态返回按钮：可拖拽、搭载返回 + 锁屏，保持游玩界面干净
class CustomPlayPage extends StatefulWidget {
  const CustomPlayPage({super.key, required this.draft});
  final TemplateDraft draft;

  @override
  State<CustomPlayPage> createState() => _CustomPlayPageState();
}

class _CustomPlayPageState extends State<CustomPlayPage> {
  final _grpc = GrpcKeyService.instance;
  final _active = <int, KeyWidget>{}; // pointer id → 组件
  final _pressedIds = <String>{};
  /// 摇杆状态：pointer → 当前激活的方向键集合
  final _joyDirs = <int, Set<String>>{};
  /// 摇杆偏移显示：widget id → Offset (归一化 -1..1)
  final _joyOffsets = <String, Offset>{};
  /// 当前按下未松的键（用于链保护：目标已按下则不联立）
  final _heldKeys = <String>{};
  /// 联立覆盖：widget id → 原始 key（松开 trigger 时恢复）
  final _chainOverrides = <String, String>{};

  /// 锁屏状态：锁定时触摸层被 AbsorbPointer 吞掉，防止误触
  bool _locked = false;

  // ════════════════════════════════════════════
  //  ★ 混合模板：组件以外的区域交给鼠标触控引擎
  // ════════════════════════════════════════════

  /// 非空表示当前模板带鼠标底层（mix）
  ///
  /// ★ 混合模板的底层**固定为触控板「只移动」模式**：
  ///   不发送任何点击 / 滚轮，忽略多指，避免游玩时误触。
  late final MouseTouchEngine? _mouse = widget.draft.isMix
      ? MouseTouchEngine(
          sensitivity: widget.draft.sensitivity,
          mouseMode: 1,
          moveOnly: true,
        )
      : null;

  /// 归属鼠标层的指针 id
  final Set<int> _mousePtrs = <int>{};

  @override
  void initState() {
    super.initState();
    // 延迟测量：接收原生层上报的触摸内核时间戳
    _kLatency.setMethodCallHandler((call) async {
      if (call.method == 'touch') {
        _lastNativeTouchInfo = (call.arguments as Map?)?.cast<Object?, Object?>();
      }
      return null;
    });
    _grpc.startSession();
  }

  @override
  void dispose() {
    _mouse?.dispose();
    final heldKeys = <String>{ for (final w in _active.values) w.key };
    // ★ 补发摇杆释放
    for (final dirs in _joyDirs.values) {
      for (final k in dirs) {
        heldKeys.add(k);
      }
    }
    for (final k in heldKeys) {
      _grpc.sendKey(key: k, isRune: !isNamedKey(k), isPressed: false);
    }
    _active.clear();
    _pressedIds.clear();
    _joyDirs.clear();
    _joyOffsets.clear();
    _heldKeys.clear();
    _chainOverrides.clear();
    _grpc.endSession();
    super.dispose();
  }

  /// ★ 摇杆：根据手指位置更新方向键
  ///
  /// 逻辑（原始版本 + 中圈分段）：
  ///   1. 方向键：按 nx / ny 超过阈值触发（与距离无关）
  ///   2. 内圈键：手指在内圈半径内时触发（可空）
  ///   3. ★ 中圈键：手指**超出中圈半径**时额外按下（如 shift）
  ///      → 中圈内 = up，推出中圈 = shift + up
  void _joyUpdate(
      int ptr, KeyWidget w, Offset pos, Size s, Set<String> prev) {
    final c = w.centerPx(s);
    final outerR = w.halfWPx(s); // 摇杆必然 sizeW == sizeH
    final d = pos - c;
    final dist = d.distance;
    final innerR = w.joyInnerRadius * outerR;
    final midR = w.joyMidRadius * outerR;

    // 归一化偏移
    final nx = (d.dx / outerR).clamp(-1.0, 1.0);
    final ny = (d.dy / outerR).clamp(-1.0, 1.0);
    _joyOffsets[w.id] = Offset(nx, ny);

    final cur = <String>{};

    // 1. 方向键（deadzone 0.3，原始逻辑）
    if (nx > 0.3 && w.joyRightKey.isNotEmpty) cur.add(w.joyRightKey);
    if (nx < -0.3 && w.joyLeftKey.isNotEmpty) cur.add(w.joyLeftKey);
    if (ny > 0.3 && w.joyDownKey.isNotEmpty) cur.add(w.joyDownKey);
    if (ny < -0.3 && w.joyUpKey.isNotEmpty) cur.add(w.joyUpKey);

    // 2. 内圈按下（原始逻辑）
    if (dist <= innerR && w.joyInnerKey.isNotEmpty) cur.add(w.joyInnerKey);

    // 3. ★ 中圈分段：超出中圈 → 追加修饰键（shift 等）
    if (dist > midR && w.joyMidKey.isNotEmpty) cur.add(w.joyMidKey);

    // 发送变化
    for (final k in cur.difference(prev)) {
      _grpc.sendKey(key: k, isRune: !isNamedKey(k), isPressed: true);
    }
    for (final k in prev.difference(cur)) {
      _grpc.sendKey(key: k, isRune: !isNamedKey(k), isPressed: false);
    }
    _joyDirs[ptr] = cur;
  }

  /// ★ 临时替换组件的映射键（联立用）
  void _updWidgetKey(String id, String newKey) {
    final i = widget.draft.widgets.indexWhere((w) => w.id == id);
    if (i < 0) return;
    widget.draft.widgets[i] =
        widget.draft.widgets[i].copyWith(key: newKey);
    setState(() {});
  }

  KeyWidget? _hitTop(Offset p, Size s) {
    for (final w in widget.draft.widgets.reversed) { // 后创建 = 上层
      if (w.hitTest(p, s)) return w;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, cons) {
        final s = cons.biggest;

        void down(PointerDownEvent e) {
          if (_locked) return;
          final w = _hitTop(e.position, s);
          if (w == null) {
            // ★ 混合模板：组件以外的区域 → 执行鼠标模板逻辑
            if (_mouse != null) {
              _mousePtrs.add(e.pointer);
              _mouse.onDown(e);
            }
            return;
          }
          // ── 延迟测量：触摸进入 App 的第一站，此处打点 ──────────────────
          // wallMs   = 墙钟时刻（与后端日志可直接相减）
          // nativeMs = 内核触摸时刻换算的墙钟值（比 wallMs 更接近"真正按下"）
          // deltaMs  = 内核事件到本次分发的延迟
          debugPrint('DKM_LAT down'
              ' key="${w.key}"'
              ' ptr=${e.pointer}'
              ' wallMs=${DateTime.now().millisecondsSinceEpoch}'
              ' nativeMs=${_nativeWallMs()}'
              ' deltaMs=${(_lastNativeTouchInfo?['deltaMs'] as num?)?.toInt() ?? -1}');
          // ────────────────────────────────────────────────────────────
          _active[e.pointer] = w;
          _pressedIds.add(w.id);
          if (w.shape == KShape.joystick) {
            _joyDirs[e.pointer] = {};
            _joyUpdate(e.pointer, w, e.position, s, {});
          } else {
            final sendKey = w.key;
            _grpc.sendKey(
                key: sendKey, isRune: !isNamedKey(sendKey), isPressed: true);
            _heldKeys.add(sendKey);

            // ★ 按键联立：检查是否有链以当前键为触发
            for (final chain in widget.draft.chains) {
              // 三项任一为空 → 该规则未配置完整，跳过
              if (chain.triggerKey.isEmpty ||
                  chain.targetKey.isEmpty ||
                  chain.newKey.isEmpty) {
                continue;
              }
              if (chain.triggerKey != sendKey) continue;
              // 找到目标组件（匹配原始映射键）
              final target = widget.draft.widgets
                  .where((t) => t.id != w.id && t.key == chain.targetKey)
                  .firstOrNull;
              if (target == null) continue;
              // 保护锁：目标已按下 → 不联立
              if (_heldKeys.contains(target.key)) continue;
              // 覆盖目标映射键
              _chainOverrides[target.id] = target.key;
              _updWidgetKey(target.id, chain.newKey);
            }
          }
          setState(() {});
        }

        void move(PointerMoveEvent e) {
          // ★ 混合模板：鼠标层指针
          if (_mousePtrs.contains(e.pointer)) {
            _mouse?.onMove(e);
            setState(() {});
            return;
          }
          final w = _active[e.pointer];
          if (w == null || w.shape != KShape.joystick) return;
          final prev = _joyDirs[e.pointer] ?? {};
          _joyUpdate(e.pointer, w, e.position, s, prev);
          setState(() {});
        }

        /// 释放该指针占用的键盘组件（摇杆方向键 / 映射键 / 联立恢复）
        void releaseComponent(int ptr) {
          final w = _active.remove(ptr);
          if (w == null) return;
          _pressedIds.remove(w.id);

          if (w.shape == KShape.joystick) {
            final dirs = _joyDirs.remove(ptr) ?? {};
            for (final k in dirs) {
              _grpc.sendKey(
                  key: k, isRune: !isNamedKey(k), isPressed: false);
            }
            _joyOffsets.remove(w.id);
          } else {
            final sendKey = w.key;
            _grpc.sendKey(
                key: sendKey, isRune: !isNamedKey(sendKey), isPressed: false);
            _heldKeys.remove(sendKey);

            // ★ 恢复联立：释放以当前键为触发器的所有链
            for (final chain in widget.draft.chains) {
              if (chain.triggerKey != sendKey) continue;
              final target = widget.draft.widgets
                  .where((t) => t.id != w.id && _chainOverrides.containsKey(t.id))
                  .firstOrNull;
              if (target == null) continue;
              final original = _chainOverrides.remove(target.id);
              if (original != null) _updWidgetKey(target.id, original);
            }
          }
          setState(() {});
        }

        void up(PointerUpEvent e) {
          // ★ 混合模板：鼠标层指针
          if (_mousePtrs.remove(e.pointer)) {
            _mouse?.onUp(e);
            // 手指全部抬起 → 收起圆点
            if (_mousePtrs.isEmpty) _mouse?.fingerPos.value = null;
            setState(() {});
            return;
          }
          // ── 延迟测量：松开侧打点 ────────────────────────────────────
          debugPrint('DKM_LAT up'
              ' key="${_active[e.pointer]?.key ?? ""}"'
              ' ptr=${e.pointer}'
              ' wallMs=${DateTime.now().millisecondsSinceEpoch}'
              ' nativeMs=${_nativeWallMs()}');
          // ────────────────────────────────────────────────────────────
          releaseComponent(e.pointer);
        }

        void cancel(PointerCancelEvent e) {
          if (_mousePtrs.remove(e.pointer)) {
            _mouse?.onCancel(e);
            if (_mousePtrs.isEmpty) _mouse?.fingerPos.value = null;
            setState(() {});
            return;
          }
          releaseComponent(e.pointer);
        }

        return Stack(clipBehavior: Clip.none, children: [
          // ★ 背景图片（最底层）
          if (widget.draft.hasBackground)
            Positioned.fill(
              child: Opacity(
                opacity: widget.draft.backgroundOpacity,
                child: Image.file(
                  File(widget.draft.backgroundImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // 1. 组件（纯视觉，越界部分照常渲染但收不到点击 → 分割线效果）
          for (final w in widget.draft.widgets)
            Positioned(
              left: w.cx * s.width - w.halfWPx(s),
              top: w.cy * s.height - w.halfHPx(s),
              width: w.sizeW * s.width,
              height: w.sizeH * s.height,
              child: Transform.rotate(
                angle: w.rotationRad,
                child: KeyWidgetView(
                  w: w,
                  pxWidth: w.sizeW * s.width,
                  pxHeight: w.sizeH * s.height,
                  pressed: _pressedIds.contains(w.id),
                  joyOffset: w.shape == KShape.joystick
                      ? _joyOffsets[w.id]
                      : null,
                ),
              ),
            ),
          // ★ 混合模板：鼠标触控的手指圆点（不拦截触摸）
          if (_mouse != null)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: FingerDotPainter(_mouse.fingerPos),
                  ),
                ),
              ),
            ),
          // 2. 触摸层（吃掉所有指针）
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: down,
              onPointerMove: move,
              onPointerUp: up,
              onPointerCancel: cancel,
              child: const SizedBox.expand(),
            ),
          ),
          // 3. 锁屏遮罩（锁定时覆盖在触摸层上方，吞掉触摸事件）
          if (_locked)
            Positioned.fill(
              child: AbsorbPointer(
                absorbing: true,
                child: Container(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
          // 4. 悬浮控件（替代静态返回按钮；可拖拽，搭载返回 + 锁屏；后期可扩展更多功能按键）
          FloatingControl(
            initialX: 50,
            initialY: MediaQuery.of(context).padding.top + 8,
            actions: [
              FloatingAction(
                icon: Icons.arrow_back_ios_new,
                tooltip: '返回',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              FloatingAction(
                icon: _locked ? Icons.lock : Icons.lock_open,
                tooltip: _locked ? '解锁' : '锁屏',
                activeBuilder: () => _locked,
                onTap: () => setState(() => _locked = !_locked),
              ),
            ],
          ),
        ]);
      }),
    );
  }
}

/// 模板列表页调用：点某个模板 → 进游玩
void openCustomPlayPage(BuildContext context, TemplateDraft draft) =>
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => CustomPlayPage(draft: draft)));