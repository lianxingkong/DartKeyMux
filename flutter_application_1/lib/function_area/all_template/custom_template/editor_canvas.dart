import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../base/key_widget.dart';
import '../base/key_widget_view.dart';
import 'snap_engine.dart' show GuideLine;

/// 缩放模式：区分拖拽的是哪个柄
enum ResizeMode { uniform, width, height }

/// 编辑画布：只负责"画 + 抛出手势事件"，几何计算全在页面层做。
/// 画布必须全屏铺放（起点=屏幕原点），这样 globalPosition == 画布坐标。
///
/// ★ 独立宽高：每个组件用 sizeW/sizeH 渲染；编辑器提供三个缩放柄：
///   - 右下角（uniform）→ 等比例缩放
///   - 右边缘（width）→ 仅改宽度
///   - 下边缘（height）→ 仅改高度
class EditorCanvas extends StatelessWidget {
  const EditorCanvas({
    super.key,
    required this.size,
    required this.widgets,
    required this.selectedId,
    required this.guides,
    required this.onBackgroundTap,
    required this.onSelect,
    required this.onDrag,
    required this.onDragEnd,
    required this.onRotate,
    required this.onResize,
  });

  final Size size;
  final List<KeyWidget> widgets;
  final String? selectedId;
  final List<GuideLine> guides;
  final VoidCallback onBackgroundTap;
  final ValueChanged<KeyWidget> onSelect;
  final void Function(KeyWidget w, Offset globalDelta) onDrag;
  final VoidCallback onDragEnd;
  final void Function(KeyWidget w, Offset globalPos) onRotate;
  final void Function(KeyWidget w, Offset globalPos, ResizeMode mode) onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 背景点击层 + 网格 + 播放区边界
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBackgroundTap,
            child: CustomPaint(
              foregroundPainter: _BorderPainter(),
              painter: _GridPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // 组件（列表顺序 = z 顺序）
        for (final w in widgets)
          _EditorItem(
            key: ValueKey(w.id),
            w: w,
            canvas: size,
            selected: w.id == selectedId,
            onSelect: () => onSelect(w),
            onDrag: (d) => onDrag(w, d),
            onDragEnd: onDragEnd,
            onRotate: (p) => onRotate(w, p),
            onResize: (p, m) => onResize(w, p, m),
          ),
        // 吸附参考线
        if (guides.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GuidePainter(guides)),
            ),
          ),
      ],
    );
  }
}

/// 单个组件的编辑包装：本体 + 手势层 + 选中框 + 旋转/缩放柄。
/// ★ 独立宽高：box 现在是矩形；三个缩放柄分布在不同边缘。
class _EditorItem extends StatelessWidget {
  _EditorItem({
    super.key,
    required this.w,
    required this.canvas,
    required this.selected,
    required this.onSelect,
    required this.onDrag,
    required this.onDragEnd,
    required this.onRotate,
    required this.onResize,
  });

  static const double _m = 56; // 柄的外边距

  final KeyWidget w;
  final Size canvas;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;
  final ValueChanged<Offset> onRotate;
  final void Function(Offset globalPos, ResizeMode mode) onResize;

  @override
  Widget build(BuildContext context) {
    final c = w.centerPx(canvas);
    final wp = w.sizeW * canvas.width;  // 组件像素宽
    final hp = w.sizeH * canvas.height; // 组件像素高
    final boxW = wp + _m * 2;
    final boxH = hp + _m * 2;

    return Positioned(
      left: c.dx - boxW / 2,
      top: c.dy - boxH / 2,
      width: boxW,
      height: boxH,
      child: Transform.rotate(
        angle: w.rotationRad,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 本体（正好覆盖组件大小）
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center: Offset(boxW / 2, boxH / 2),
                width: wp,
                height: hp,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: selected ? 1 : .8,
                      child: KeyWidgetView(
                        w: w,
                        pxWidth: wp,
                        pxHeight: hp,
                      ),
                    ),
                  ),
                  // 手势层：拖动位移从"旋转后的局部系"换回全局系
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSelect,
                      onPanUpdate: (d) {
                        final ct = math.cos(w.rotationRad);
                        final st = math.sin(w.rotationRad);
                        onDrag(Offset(
                          d.delta.dx * ct - d.delta.dy * st,
                          d.delta.dx * st + d.delta.dy * ct,
                        ));
                      },
                      onPanEnd: (_) => onDragEnd(),
                    ),
                  ),
                  if (selected)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: _SelPainter()),
                      ),
                    ),
                ],
              ),
            ),
            if (selected) ...[
              // 旋转柄
              Positioned(
                left: boxW / 2 - 17,
                top: boxH / 2 - hp / 2 - 51,
                width: 34, height: 34,
                child: _Handle(
                    icon: Icons.rotate_90_degrees_ccw_outlined,
                    onPan: (gp) => onRotate(gp)),
              ),
              // ★ 摇杆只允许等比缩放，不显示单独的宽/高柄
              if (w.shape != KShape.joystick) ...[
                Positioned(
                  left: boxW / 2 + wp / 2 + 17,
                  top: boxH / 2 - 17,
                  width: 34, height: 34,
                  child: _Handle(
                      icon: Icons.swap_horiz,
                      onPan: (gp) => onResize(gp, ResizeMode.width)),
                ),
                Positioned(
                  left: boxW / 2 - 17,
                  top: boxH / 2 + hp / 2 + 17,
                  width: 34, height: 34,
                  child: _Handle(
                      icon: Icons.swap_vert,
                      onPan: (gp) => onResize(gp, ResizeMode.height)),
                ),
              ],
              // 等比缩放柄（摇杆也有）
              Positioned(
                left: boxW / 2 + wp / 2 + 17,
                top: boxH / 2 + hp / 2 + 17,
                width: 34, height: 34,
                child: _Handle(
                    icon: Icons.open_in_full,
                    onPan: (gp) => onResize(gp, ResizeMode.uniform)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.icon, required this.onPan});

  final IconData icon;
  final ValueChanged<Offset> onPan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onPan(d.globalPosition),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepOrange, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.deepOrange),
      ),
    );
  }
}

// ═══════════ 画笔们 ═══════════

void _dashLine(Canvas c, Paint p, Offset a, Offset b) {
  const d = 9.0, g = 6.0;
  final len = (b - a).distance;
  if (len < 1) return;
  final dir = (b - a) / len;
  var t = 0.0;
  while (t < len) {
    c.drawLine(a + dir * t, a + dir * math.min(t + d, len), p);
    t += d + g;
  }
}

class _SelPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.deepOrange;
    _dashLine(c, p, Offset.zero, Offset(s.width, 0));
    _dashLine(c, p, Offset(s.width, 0), Offset(s.width, s.height));
    _dashLine(c, p, Offset(s.width, s.height), Offset(0, s.height));
    _dashLine(c, p, Offset(0, s.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuidePainter extends CustomPainter {
  _GuidePainter(this.lines);
  final List<GuideLine> lines;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFF4081);
    for (final g in lines) {
      if (g.vertical) {
        _dashLine(c, p, Offset(g.pos, 0), Offset(g.pos, s.height));
      } else {
        _dashLine(c, p, Offset(0, g.pos), Offset(s.width, g.pos));
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter old) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = Colors.blueGrey.shade100;
    const step = 32.0;
    for (var x = step; x < s.width; x += step) {
      for (var y = step; y < s.height; y += step) {
        c.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BorderPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.blueGrey.shade300;
    _dashLine(c, p, Offset.zero, Offset(s.width, 0));
    _dashLine(c, p, Offset(s.width, 0), Offset(s.width, s.height));
    _dashLine(c, p, Offset(s.width, s.height), Offset(0, s.height));
    _dashLine(c, p, Offset(0, s.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}