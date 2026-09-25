import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../base/key_widget.dart';
import '../base/key_widget_view.dart';
import 'snap_engine.dart' show GuideLine;

/// 编辑画布：只负责“画 + 抛出手势事件”，几何计算全在页面层做。
/// 画布必须全屏铺放（起点=屏幕原点），这样 globalPosition == 画布坐标。
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
  final void Function(KeyWidget w, Offset globalPos) onResize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // 需求3：允许组件越界显示
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
            onResize: (p) => onResize(w, p),
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
/// 外框比本体大一圈（_m），让柄可以放在本体之外且仍可命中。
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
  }); // ← 上一版漏了这个 ");"，是全部报错的根因

  static const double _m = 56; // 柄的外边距

  final KeyWidget w;
  final Size canvas;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onDrag; // 已换算到全局坐标的位移
  final VoidCallback onDragEnd;
  final ValueChanged<Offset> onRotate;
  final ValueChanged<Offset> onResize;

  @override
  Widget build(BuildContext context) {
    final c = w.centerPx(canvas);
    final side = w.halfPx(canvas) * 2;
    final box = side + _m * 2;

    return Positioned(
      left: c.dx - box / 2,
      top: c.dy - box / 2,
      width: box,
      height: box,
      child: Transform.rotate(
        angle: w.rotationRad,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 本体（正好覆盖组件大小）
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center: Offset(box / 2, box / 2),
                width: side,
                height: side,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: selected ? 1 : .8, // 未选中略透明，看清层叠
                      child: KeyWidgetView(w: w, pxSize: side),
                    ),
                  ),
                  // 手势层：拖动位移从“旋转后的局部系”换回全局系
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
                      child: IgnorePointer(child: CustomPaint(painter: _SelPainter())),
                    ),
                ],
              ),
            ),
            if (selected) ...[
              // 旋转柄：本体正上方
              Positioned(
                left: box / 2 - 17,
                top: box / 2 - side / 2 - 51,
                width: 34,
                height: 34,
                child: _Handle(
                  icon: Icons.rotate_90_degrees_ccw_outlined,
                  onPan: onRotate,
                ),
              ),
              // 缩放柄：本体右下角外侧（沿本地 45° 对角线）
              Positioned(
                left: box / 2 + side / 2 + 17,
                top: box / 2 + side / 2 + 17,
                width: 34,
                height: 34,
                child: _Handle(icon: Icons.open_in_full, onPan: onResize),
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
  final ValueChanged<Offset> onPan; // 直接用 globalPosition，画布全屏故 == 画布坐标

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => onPan(d.globalPosition),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepOrange, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
