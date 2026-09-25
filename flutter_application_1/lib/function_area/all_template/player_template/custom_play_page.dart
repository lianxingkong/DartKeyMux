import 'package:flutter/material.dart';

import '../base/key_widget.dart';
import '../base/template_document.dart';
import '../base/key_widget_view.dart';
import '../../services/connect_grc.dart';

/// 自定义模板游玩页：
/// - 单个全屏 Listener 接收所有指针，从最上层组件开始做“旋转感知”命中
///   → 层级规则（需求5）与旋转精度一次到位
/// - 指针绑定语义：按下后滑出组件，抬手仍释放同一个键（真实琴键手感）
/// - 多点触控 → 天然支持“模拟键盘”（需求10）
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
          final w = _hitTop(e.position, s);
          if (w == null) return;
          _active[e.pointer] = w;              // ✅ 修正：pointer，不是 pointerId
          _pressedIds.add(w.id);
          _grpc.sendKey(key: w.key, isRune: true, isPressed: true);
          setState(() {});
        }

        void up(PointerEvent e) {
          final w = _active.remove(e.pointer); // ✅ 同上
          if (w == null) return;
          _pressedIds.remove(w.id);
          _grpc.sendKey(key: w.key, isRune: true, isPressed: false);
          setState(() {});
        }

        return Stack(clipBehavior: Clip.none, children: [
          // 1. 组件（纯视觉，越界部分照常渲染但收不到点击 → 分割线效果）
          for (final w in widget.draft.widgets)
            Positioned(
              left: w.cx * s.width - w.halfPx(s),
              top: w.cy * s.height - w.halfPx(s),
              width: w.size * s.width,
              height: w.size * s.width,
              child: Transform.rotate(
                angle: w.rotationRad,
                child: KeyWidgetView(
                  w: w,
                  pxSize: w.size * s.width,
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
          // 3. 返回按钮（最顶层，仅这块小区域吃事件）
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(24),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
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
