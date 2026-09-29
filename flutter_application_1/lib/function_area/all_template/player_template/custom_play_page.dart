import 'package:flutter/material.dart';

import '../base/key_widget.dart';
import '../base/template_document.dart';
import '../base/key_widget_view.dart';
import '../base/floating_control.dart';
import '../../services/connect_grc.dart';

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

  /// 锁屏状态：锁定时触摸层被 AbsorbPointer 吞掉，防止误触
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _grpc.startSession();
  }

  @override
  void dispose() {
    // ★ 多点触控压键退出（一根手指压着组件、另一根点返回）时，
    //   _active 里还有没抬起的键：先补发 keyUp 再收流，
    //   否则服务端可能死等 keyUp 而永不返回 keyReturn（会话悬挂）。
    final heldKeys = <String>{ for (final w in _active.values) w.key };
    for (final k in heldKeys) {
      _grpc.sendKey(key: k, isRune: true, isPressed: false);
    }
    _active.clear();
    _pressedIds.clear();
    _grpc.endSession();
    super.dispose();
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
          _grpc.sendKey(key: w.key, isRune: true, isPressed: true);
          setState(() {});
        }

        void up(PointerEvent e) {
          if (_locked) return;
          final w = _active.remove(e.pointer);
          if (w == null) return;
          _pressedIds.remove(w.id);
          _grpc.sendKey(key: w.key, isRune: true, isPressed: false);
          setState(() {});
        }

        return Stack(clipBehavior: Clip.none, children: [
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
                ),
              ),
            ),
          // 2. 触摸层（吃掉所有指针）
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: down,
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