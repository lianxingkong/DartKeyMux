import 'package:flutter/material.dart';

/// 全屏点击层：
/// 基于 Listener（原始指针事件），按下/松开瞬间触发，零延迟。
class FullScreenTap extends StatelessWidget {
  const FullScreenTap({
    super.key,
    this.onPointerDown,   // 按下（全局坐标）
    this.onPointerUp,     // 松开（全局坐标）
  });

  final ValueChanged<Offset>? onPointerDown;
  final ValueChanged<Offset>? onPointerUp;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        // opaque：本层吞掉事件；translucent：事件同时透传给下层
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) => onPointerDown?.call(event.position),
        onPointerUp: (event) => onPointerUp?.call(event.position),
        child: const SizedBox.expand(),  // 占满全屏，保证能收到事件
      ),
    );
  }
}
