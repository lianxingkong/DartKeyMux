import 'dart:io';
import 'package:flutter/material.dart';

import '../base/key_widget.dart';
import '../base/template_document.dart';
import '../base/key_widget_view.dart';
import '../base/floating_control.dart';
import '../../services/connect_grc.dart';
import '../../setting/mapping_key_page.dart';

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

  @override
  void initState() {
    super.initState();
    _grpc.startSession();
  }

  @override
  void dispose() {
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
  void _joyUpdate(
      int ptr, KeyWidget w, Offset pos, Size s, Set<String> prev) {
    final c = w.centerPx(s);
    final outerR = w.halfWPx(s); // 摇杆必然 sizeW == sizeH
    final d = pos - c;
    final dist = d.distance;
    final innerR = w.joyInnerRadius * outerR;

    // 归一化偏移
    final nx = (d.dx / outerR).clamp(-1.0, 1.0);
    final ny = (d.dy / outerR).clamp(-1.0, 1.0);
    _joyOffsets[w.id] = Offset(nx, ny);

    // 判四个方向（deadzone 0.3）
    final cur = <String>{};
    if (nx > 0.3 && w.joyRightKey.isNotEmpty) cur.add(w.joyRightKey);
    if (nx < -0.3 && w.joyLeftKey.isNotEmpty) cur.add(w.joyLeftKey);
    if (ny > 0.3 && w.joyDownKey.isNotEmpty) cur.add(w.joyDownKey);
    if (ny < -0.3 && w.joyUpKey.isNotEmpty) cur.add(w.joyUpKey);

    // 内圈按下
    if (dist <= innerR && w.joyInnerKey.isNotEmpty) cur.add(w.joyInnerKey);

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

        void down(PointerEvent e) {
          if (_locked) return;
          final w = _hitTop(e.position, s);
          if (w == null) return;
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

        void move(PointerEvent e) {
          final w = _active[e.pointer];
          if (w == null || w.shape != KShape.joystick) return;
          final prev = _joyDirs[e.pointer] ?? {};
          _joyUpdate(e.pointer, w, e.position, s, prev);
          setState(() {});
        }

        void up(PointerEvent e) {
          final w = _active.remove(e.pointer);
          if (w == null) return;
          _pressedIds.remove(w.id);

          if (w.shape == KShape.joystick) {
            final dirs = _joyDirs.remove(e.pointer) ?? {};
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
          // 2. 触摸层（吃掉所有指针）
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: down,
              onPointerMove: move,
              onPointerUp: up,
              onPointerCancel: up,
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