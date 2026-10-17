import 'dart:io';
import 'package:flutter/material.dart';
import 'key_widget.dart';

/// 组件纯视觉。编辑态与游玩态共用 → 所见即所得。
class KeyWidgetView extends StatefulWidget {
  const KeyWidgetView({
    super.key,
    required this.w,
    this.pxSize,
    this.pxWidth,
    this.pxHeight,
    this.pressed = false,
    this.joyOffset,
  });

  final KeyWidget w;
  final double? pxSize;
  final double? pxWidth;
  final double? pxHeight;
  final bool pressed;
  final Offset? joyOffset;

  @override
  State<KeyWidgetView> createState() => _KeyWidgetViewState();
}

class _KeyWidgetViewState extends State<KeyWidgetView> {
  double get _w => widget.pxWidth ?? widget.pxSize ?? 100;
  double get _h => widget.pxHeight ?? widget.pxSize ?? 100;

  Color get _idle => widget.w.idleColor ??
      (widget.w.shape == KShape.circle
          ? const Color(0xFF26A69A)
          : const Color(0xFF5C7CFA));
  Color get _active {
    final base = widget.w.pressedColor ??
        HSLColor.fromColor(_idle)
            .withLightness(
                (HSLColor.fromColor(_idle).lightness * 0.7).clamp(0.0, 1.0))
            .toColor();
    return base.withValues(alpha: 1);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    final c = widget.pressed ? _active : _idle;
    final isCircle = w.shape == KShape.circle;
    final isJoy = w.shape == KShape.joystick;
    final minSide = _w < _h ? _w : _h;

    if (isJoy) return _buildJoystick(w, c, minSide);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.rectangle,
        borderRadius: isCircle
            ? BorderRadius.all(Radius.circular(minSide / 2))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (w.imagePath != null &&
              w.imagePath!.isNotEmpty &&
              File(w.imagePath!).existsSync())
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.all(
                    Radius.circular(isCircle ? minSide / 2 : 0)),
                child: Opacity(
                  opacity: w.imageOpacity,
                  child: Transform.translate(
                    offset: Offset(w.imageDx, w.imageDy),
                    child: Transform.scale(
                      scale: w.imageScale,
                      alignment: Alignment.center,
                      child: Image.file(File(w.imagePath!), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            ),
          if (minSide >= 44)
            FittedBox(
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
        ],
      ),
    );
  }

  /// ★ 摇杆渲染：外圈 + 内圈（跟随拖拽偏移）
  Widget _buildJoystick(KeyWidget w, Color c, double minSide) {
    final joyOff = widget.joyOffset;
    final outerR = minSide / 2;
    final innerR = w.joyInnerRadius * outerR;
    final dx = joyOff != null ? joyOff.dx * (outerR - innerR) : 0.0;
    final dy = joyOff != null ? joyOff.dy * (outerR - innerR) : 0.0;

    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.8), width: 2.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            left: _w / 2 + dx - innerR,
            top: _h / 2 + dy - innerR,
            child: Container(
              width: innerR * 2,
              height: innerR * 2,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: .5), blurRadius: 6),
                ],
              ),
            ),
          ),
          // 方向标签（编辑模式可视，无 joyOffset 即未在拖动）
          if (joyOff == null && minSide >= 60) ...[
            _joyLabel('↑', w.joyUpKey, Alignment.topCenter),
            _joyLabel('↓', w.joyDownKey, Alignment.bottomCenter),
            _joyLabel('←', w.joyLeftKey, Alignment.centerLeft),
            _joyLabel('→', w.joyRightKey, Alignment.centerRight),
          ],
        ],
      ),
    );
  }

  Widget _joyLabel(String arrow, String key, Alignment align) {
    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          key.isEmpty ? arrow : '$arrow\n$key',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white70),
        ),
      ),
    );
  }
}