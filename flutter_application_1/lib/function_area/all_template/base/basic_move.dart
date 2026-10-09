import 'package:flutter/material.dart';

/// 全屏点击层：
/// 基于 Listener（原始指针事件），按下/松开/移动瞬间触发，零延迟。
class FullScreenTap extends StatelessWidget {
  const FullScreenTap({
    super.key,
    this.onPointerDown,   // 按下（相对坐标）
    this.onPointerUp,     // 松开（相对坐标）
    this.onPointerMove,   // 实时移动（相对坐标）
  });

  final ValueChanged<Offset>? onPointerDown;
  final ValueChanged<Offset>? onPointerUp;
  final ValueChanged<Offset>? onPointerMove;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        // opaque：本层吞掉事件；translucent：事件同时透传给下层
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => onPointerDown?.call(event.localPosition),
        onPointerUp: (event) => onPointerUp?.call(event.localPosition),
        onPointerMove: (event) => onPointerMove?.call(event.delta),
        child: const SizedBox.expand(),  // 占满全屏，保证能收到事件
      ),
    );
  }
}
