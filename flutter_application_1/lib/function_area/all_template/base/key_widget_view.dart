import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'key_widget.dart';

/// 组件纯视觉。编辑态与游玩态共用 → 所见即所得。
///
/// ★ 关键修复（图片不占满的真根因）：
///   容器带 alignment 时，Container 会把 child 包进 Align，
///   而 Align 传给 child 的是 **loose 约束**。此时 Stack 默认 StackFit.loose
///   会缩到"最大的非定位子节点"——也就是按键文字那个 FittedBox（几十像素），
///   于是 Positioned.fill 的图片只填满文字大小的一小块，四周露出组件底色。
///   修复：Stack 用 StackFit.expand 强制撑满组件，文字用 Center 包裹不被拉伸。
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

  bool get _hasImage =>
      widget.w.imagePath != null &&
      widget.w.imagePath!.isNotEmpty &&
      File(widget.w.imagePath!).existsSync();

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
        // ★ 必须 expand：否则 Stack 会缩到按键文字的大小
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_hasImage)
            ClipRRect(
              borderRadius: BorderRadius.all(
                  Radius.circular(isCircle ? minSide / 2 : 0)),
              child: _buildImage(w),
            ),
          if (w.showKeyLabel && minSide >= 44)
            // Center 包裹：让文字保持自然大小而不是被 expand 拉伸
            Center(
              child: FittedBox(
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
            ),
        ],
      ),
    );
  }

  /// ★ 图片层：用显式 Positioned 几何代替 Transform
  ///
  /// 语义（与裁剪页完全一致）：
  ///   - scale = 1 → 图片正好铺满组件（cover）
  ///   - scale > 1 → 以组件中心为原点放大
  ///   - imageDx / imageDy 为归一化偏移（相对组件宽/高），乘回像素再加
  /// 显式算出 left/top/width/height，不依赖 Transform 的约束传递，
  /// 任何尺寸下结果都确定。
  Widget _buildImage(KeyWidget w) {
    final s = w.imageScale <= 0 ? 1.0 : w.imageScale;
    final iw = _w * s;
    final ih = _h * s;
    final left = (_w - iw) / 2 + w.imageDx * _w;
    final top = (_h - ih) / 2 + w.imageDy * _h;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: left,
          top: top,
          width: iw,
          height: ih,
          child: Opacity(
            opacity: w.imageOpacity,
            child: Image.file(
              File(w.imagePath!),
              fit: BoxFit.cover,
              width: iw,
              height: ih,
            ),
          ),
        ),
      ],
    );
  }

  /// ★ 摇杆渲染：外圈 + 中圈（虚线）+ 内圈 + 方向标签
  ///
  /// 中圈是"轻推/重推"分界：
  ///   - 距中心 ≤ 中圈 → 只触发方向键（例如 up）
  ///   - 距中心 > 中圈 → 追加触发中圈映射键（例如 shift → shift+up）
  Widget _buildJoystick(KeyWidget w, Color c, double minSide) {
    final joyOff = widget.joyOffset;
    final outerR = minSide / 2;
    final innerR = w.joyInnerRadius * outerR;
    final midR = w.joyMidRadius * outerR;
    final dx = joyOff != null ? joyOff.dx * (outerR - innerR) : 0.0;
    final dy = joyOff != null ? joyOff.dy * (outerR - innerR) : 0.0;
    final hasMidKey = w.joyMidKey.isNotEmpty;

    return Container(
      width: _w,
      height: _h,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        border: Border.all(color: c.withValues(alpha: 0.8), width: 2.5),
      ),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // ★ 中圈（虚线，轻推/重推分界）
          if (hasMidKey)
            IgnorePointer(
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  radius: midR,
                  color: Colors.amber.withValues(alpha: 0.85),
                  strokeWidth: 1.8,
                ),
              ),
            ),
          // 内圈（死区）
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
            // ★ 中圈映射键提示（放在虚线环的左上斜角，避开方向标签）
            if (hasMidKey)
              _joyLabel('◌', w.joyMidKey,
                  Alignment(-midR / outerR * 0.72, -midR / outerR * 0.72),
                  labelColor: Colors.amber.shade200),
          ],
        ],
      ),
    );
  }

  Widget _joyLabel(String arrow, String key, Alignment align,
      {Color labelColor = Colors.white70}) {
    return Center(
      child: Align(
        alignment: align,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            key.isEmpty ? arrow : '$arrow\n$key',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: labelColor),
          ),
        ),
      ),
    );
  }
}

/// ── 虚线圆绘制器（摇杆中圈）──
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({
    required this.radius,
    required this.color,
    this.strokeWidth = 1.8,
    this.dashLength = 6.0,
    this.gapLength = 4.0,
  });

  final double radius;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 1) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = ((circumference / (dashLength + gapLength)).ceil())
        .clamp(1, 400);
    final dashAngle = (dashLength / circumference) * 2 * math.pi;
    final gapAngle = (gapLength / circumference) * 2 * math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      if (startAngle >= 2 * math.pi) break;
      final sweep = math.min(dashAngle, 2 * math.pi - startAngle);
      canvas.drawArc(rect, startAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) =>
      old.radius != radius || old.color != color;
}