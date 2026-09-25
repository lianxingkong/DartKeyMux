import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ── 形状（预留扩展：pill / diamond…）──
enum KShape { square, circle }

KShape _shapeFromId(String id) =>
    KShape.values.where((e) => e.name == id).firstOrNull ?? KShape.square;

int _c2i(Color c) => c.toARGB32(); // Flutter < 3.27 请改回 c.value

/// 单个按键组件的纯数据。
/// ★ 所有几何量均为“归一化”（屏幕宽高的比例），
///   这是分享模板到不同分辨率设备不错位的关键。
class KeyWidget {
  KeyWidget({
    required this.id,
    required this.shape,
    required this.key,
    required this.cx,
    required this.cy,
    required this.size,
    this.rotation = 0,
    this.idleColor,
    this.pressedColor,
  });

  final String id;
  final KShape shape;
  final String key;          // 映射按键，作为 rune 发给后端

  final double cx, cy;       // 中心（比例）。允许越界 → 越界部分天然成为“分区线”
  final double size;         // 边长/直径（相对屏宽）
  final double rotation;     // 角度制 0~360
  final Color? idleColor;    // 可选：松开色
  final Color? pressedColor; // 可选：按下色（不填自动派生）

  double get rotationRad => rotation * math.pi / 180;

  KeyWidget copyWith({
    String? key, KShape? shape, double? cx, double? cy,
    double? size, double? rotation, Color? idleColor, Color? pressedColor,
    bool clearIdle = false, bool clearPressed = false,
  }) => KeyWidget(
    id: id, shape: shape ?? this.shape, key: key ?? this.key,
    cx: cx ?? this.cx, cy: cy ?? this.cy, size: size ?? this.size,
    rotation: rotation ?? this.rotation,
    idleColor: clearIdle ? null : (idleColor ?? this.idleColor),
    pressedColor: clearPressed ? null : (pressedColor ?? this.pressedColor),
  );

  // ── 几何换算 ──
  Offset centerPx(Size s) => Offset(cx * s.width, cy * s.height);
  double halfPx(Size s) => size * s.width / 2;

  /// 旋转命中：把全局点逆旋转到组件本地系再判断（不能用 AABB！）
  bool hitTest(Offset p, Size s) {
    final c = centerPx(s), half = halfPx(s);
    if (half < 1) return false;
    final d = p - c;
    final lx =  d.dx * math.cos(rotationRad) + d.dy * math.sin(rotationRad);
    final ly = -d.dx * math.sin(rotationRad) + d.dy * math.cos(rotationRad);
    return shape == KShape.circle
        ? (lx * lx + ly * ly <= half * half)
        : (lx.abs() <= half && ly.abs() <= half);
  }

  /// 旋转后的外接矩形（吸附/对齐用）
  Rect aabbPx(Size s) {
    final c = centerPx(s), h = halfPx(s);
    final ct = math.cos(rotationRad), st = math.sin(rotationRad);
    var minx = c.dx, maxx = c.dx, miny = c.dy, maxy = c.dy;
    for (final q in [Offset(-h, -h), Offset(h, -h), Offset(h, h), Offset(-h, h)]) {
      final x = c.dx + q.dx * ct - q.dy * st;
      final y = c.dy + q.dx * st + q.dy * ct;
      minx = math.min(minx, x); maxx = math.max(maxx, x);
      miny = math.min(miny, y); maxy = math.max(maxy, y);
    }
    return Rect.fromLTRB(minx, miny, maxx, maxy);
  }

  Map<String, dynamic> toMap() => {
    'shape': shape.name, 'key': key,
    'cx': cx, 'cy': cy, 'size': size, 'rot': rotation,
    if (idleColor != null) 'c0': _c2i(idleColor!),
    if (pressedColor != null) 'c1': _c2i(pressedColor!),
  };

  /// fromMap 同时承担“导入 sanitize”：所有量钳制到安全范围
  factory KeyWidget.fromMap(Map<String, dynamic> m, String id) => KeyWidget(
    id: id,
    shape: _shapeFromId(m['shape'] ?? ''),
    key: ((m['key'] ?? 'a').toString()).trim().isEmpty
        ? 'a' : (m['key'] as String).trim(),
    cx: (((m['cx'] as num?)?.toDouble() ?? .5)).clamp(-1.0, 2.0),
    cy: (((m['cy'] as num?)?.toDouble() ?? .5)).clamp(-1.0, 2.0),
    size: (((m['size'] as num?)?.toDouble() ?? .3)).clamp(.02, 4.0),
    rotation: ((((m['rot'] as num?)?.toDouble() ?? 0) % 360) + 360) % 360,
    idleColor: m['c0'] == null ? null : Color(m['c0'] as int),
    pressedColor: m['c1'] == null ? null : Color(m['c1'] as int),
  );

  static int _n = 0;
  /// 编辑器“+□ / +○”新建
  factory KeyWidget.spawn(KShape shape, Offset centerPx, Size canvas) {
    _n++;
    return KeyWidget(
      id: 'w${DateTime.now().millisecondsSinceEpoch}_$_n',
      shape: shape, key: 'a',
      cx: (centerPx.dx / canvas.width).clamp(-.5, 1.5),
      cy: (centerPx.dy / canvas.height).clamp(-.5, 1.5),
      size: .3, rotation: 0,
    );
  }
}
