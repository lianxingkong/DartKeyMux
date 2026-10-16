import 'package:flutter/material.dart';
import 'key_widget.dart';

/// 组件纯视觉。编辑态与游玩态共用 → 所见即所得。
/// pressed：变色，给音游手感。
///
/// ★ 支持独立宽高：pxWidth / pxHeight 分别控制，圆形控件不同宽高时呈现椭圆。
class KeyWidgetView extends StatelessWidget {
  const KeyWidgetView({
    super.key,
    required this.w,
    this.pxSize,       // 兼容旧接口：等宽高时用
    this.pxWidth,      // 新接口：独立宽度（px）
    this.pxHeight,     // 新接口：独立高度（px）
    this.pressed = false,
  });

  final KeyWidget w;
  final double? pxSize;
  final double? pxWidth;
  final double? pxHeight;
  final bool pressed;

  double get _w => pxWidth ?? pxSize ?? 100;
  double get _h => pxHeight ?? pxSize ?? 100;

  Color get _idle => w.idleColor ??
      (w.shape == KShape.circle ? const Color(0xFF26A69A) : const Color(0xFF5C7CFA));
  Color get _active {
    final base = w.pressedColor ??
        HSLColor.fromColor(_idle)
            .withLightness((HSLColor.fromColor(_idle).lightness * 0.7).clamp(0.0, 1.0))
            .toColor();
    return base.withValues(alpha: 1);
  }

  @override
  Widget build(BuildContext context) {
    final c = pressed ? _active : _idle;
    final circle = w.shape == KShape.circle;
    final minSide = _w < _h ? _w : _h;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: c,
        // ★ 统一使用 rectangle + borderRadius 实现圆/椭圆，
        //   避免 AnimatedContainer 过渡期 shape==circle 与 borderRadius!=null 共存的断言崩溃
        shape: BoxShape.rectangle,
        borderRadius: circle
            ? BorderRadius.all(Radius.circular(minSide / 2))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 10, spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: minSide < 44
          ? null
          : FittedBox(
              child: Padding(
                padding: EdgeInsets.all(minSide * .14),
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
    );
  }
}