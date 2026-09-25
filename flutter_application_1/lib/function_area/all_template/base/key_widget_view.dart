import 'package:flutter/material.dart';
import 'key_widget.dart';

/// 组件纯视觉。编辑态与游玩态共用 → 所见即所得。
/// pressed：变色 + 微缩，给音游手感。
class KeyWidgetView extends StatelessWidget {
  const KeyWidgetView({
    super.key,
    required this.w,
    required this.pxSize,   // 边长（px）
    this.pressed = false,
  });

  final KeyWidget w;
  final double pxSize;
  final bool pressed;

  Color get _idle => w.idleColor ??
      (w.shape == KShape.circle ? const Color(0xFF26A69A) : const Color(0xFF5C7CFA));
  Color get _active => w.pressedColor ?? _idle.withValues(alpha: 0.5); // 不填自动派生

  @override
  Widget build(BuildContext context) {
    final c = pressed ? _active : _idle;
    final circle = w.shape == KShape.circle;
    return AnimatedScale(
      scale: pressed ? 0.93 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: c,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(pxSize * .12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .22),
              blurRadius: 10, spreadRadius: 1,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: pxSize < 44
            ? null // 太小就不写字了
            : FittedBox(
                child: Padding(
                  padding: EdgeInsets.all(pxSize * .14),
                  child: Text(
                    w.key,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: c.computeLuminance() > .45
                          ? const Color(0xEE263238)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
