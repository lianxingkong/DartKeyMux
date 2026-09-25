import 'package:flutter/material.dart';

class GuideLine {
  const GuideLine({required this.vertical, required this.pos});
  final bool vertical; // true = 竖线(吸附了 x)，false = 横线(吸附了 y)
  final double pos;    // 画布坐标
}

class SnapResult {
  const SnapResult({required this.center, required this.guides});
  final Offset center;
  final List<GuideLine> guides;
}

/// 吸附引擎：移动时“自己的边/中心 ↔ 他人的边/中心 ↔ 屏幕边与中线”
class SnapEngine {
  static const double dist = 14.0;

  static SnapResult snapMove(
      Offset c, double half, Size canvas, List<Rect> others) {
    final xs = <double>[0, canvas.width / 2, canvas.width];
    final ys = <double>[0, canvas.height / 2, canvas.height];
    for (final r in others) {
      xs..add(r.left)..add(r.center.dx)..add(r.right);
      ys..add(r.top)..add(r.center.dy)..add(r.bottom);
    }

    final guides = <GuideLine>[];

    double bestX = dist, shiftX = 0;
    double? gx;
    for (final probe in [c.dx - half, c.dx, c.dx + half]) {
      for (final cand in xs) {
        final d = (cand - probe).abs();
        if (d < bestX) { bestX = d; shiftX = cand - probe; gx = cand; }
      }
    }
    if (gx != null) guides.add(GuideLine(vertical: true, pos: gx));

    double bestY = dist, shiftY = 0;
    double? gy;
    for (final probe in [c.dy - half, c.dy, c.dy + half]) {
      for (final cand in ys) {
        final d = (cand - probe).abs();
        if (d < bestY) { bestY = d; shiftY = cand - probe; gy = cand; }
      }
    }
    if (gy != null) guides.add(GuideLine(vertical: false, pos: gy));

    return SnapResult(center: c.translate(shiftX, shiftY), guides: guides);
  }

  /// 数值吸附（缩放时的“边对齐”用）
  static double snapScalar(double v, Iterable<double> cands, [double th = 12.0]) {
    var best = th;
    var out = v;
    for (final c in cands) {
      final d = (c - v).abs();
      if (d < best) { best = d; out = c; }
    }
    return out;
  }
}
