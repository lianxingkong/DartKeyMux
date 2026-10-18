import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ── 形状（预留扩展：pill / diamond…）──
enum KShape { square, circle, joystick }

KShape _shapeFromId(String id) =>
    KShape.values.where((e) => e.name == id).firstOrNull ?? KShape.square;

int _c2i(Color c) => c.toARGB32(); // Flutter < 3.27 请改回 c.value

/// 单个按键组件的纯数据。
/// ★ 所有几何量均为"归一化"（屏幕宽高的比例），
///   这是分享模板到不同分辨率设备不错位的关键。
///
/// ★ 独立宽高：sizeW / sizeH 允许沿长或宽单独拉伸（方形→矩形，圆形→椭圆），
///   兼容旧存档（旧 size 字段自动映射为 sizeW = sizeH = size）。
class KeyWidget {
  KeyWidget({
    required this.id,
    required this.shape,
    required this.key,
    required this.cx,
    required this.cy,
    double? size,
    double? sizeW,
    double? sizeH,
    this.rotation = 0,
    this.idleColor,
    this.pressedColor,
    this.imagePath,           // ★ 组件内图片路径
    this.imageOpacity = 1.0,  // ★ 组件内图片透明度
    this.imageDx = 0,            // ★ 图片水平偏移
    this.imageDy = 0,            // ★ 图片垂直偏移
    this.imageScale = 1.0,       // ★ 图片缩放
    // ── 摇杆属性 ──
    this.joyInnerRadius = 0.3,   // 内圈半径占比 (0..1)
    this.joyUpKey = 'up',        // 上方向映射键
    this.joyDownKey = 'down',    // 下方向映射键
    this.joyLeftKey = 'left',    // 左方向映射键
    this.joyRightKey = 'right',  // 右方向映射键
    this.joyInnerKey = '',       // 内圈按下映射键（空=不触发）
    // ★ 中圈分段映射（轻推/重推）
    this.joyMidRadius = 0.6,     // 中圈半径占比（虚线分界）
    this.joyMidKey = '',         // 中圈映射键：超出中圈时追加按下（如 shift）
    this.showKeyLabel = true,   // ★ 默认显示按键文本
  }) : assert(size != null || (sizeW != null && sizeH != null),
            '必须提供 size 或同时提供 sizeW 与 sizeH') {
    if (size != null) {
      _sizeW = size;
      _sizeH = size;
    } else {
      _sizeW = sizeW;
      _sizeH = sizeH;
    }
  }

  final String id;
  final KShape shape;
  final String key;          // 映射按键，作为 rune 发给后端

  final double cx, cy;       // 中心（比例）。允许越界 → 越界部分天然成为"分区线"

  // ── 独立宽高（归一化，相对屏宽/屏高）──
  double? _sizeW;
  double? _sizeH;

  /// 宽度（相对屏宽的比例）
  double get sizeW => _sizeW!;
  /// 高度（相对屏高的比例）
  double get sizeH => _sizeH!;

  /// 兼容旧代码：取宽高平均值。设值时同时设宽高。
  double get size => (sizeW + sizeH) / 2;
  set size(double v) {
    _sizeW = v;
    _sizeH = v;
  }

  final double rotation;     // 角度制 0~360
  final Color? idleColor;    // 可选：松开色
  final Color? pressedColor; // 可选：按下色（不填自动派生）
  final String? imagePath;   // ★ 组件内图片
  final double imageOpacity;  // ★ 图片透明度 0..1
  final double imageDx;       // ★ 图片水平偏移（归一化：相对组件宽的比例，0=居中）
  final double imageDy;       // ★ 图片垂直偏移（归一化：相对组件高的比例）
  final double imageScale;    // ★ 图片缩放比，默认 1.0
  final bool showKeyLabel;    // ★ 是否显示映射按键文本（默认 true）

  // ── 摇杆属性 ──
  final double joyInnerRadius;   // 内圈半径占比（死区）
  final double joyMidRadius;     // ★ 中圈半径占比（轻推/重推分界，虚线）
  final String joyUpKey;         // 上方向
  final String joyDownKey;       // 下方向
  final String joyLeftKey;       // 左方向
  final String joyRightKey;      // 右方向
  final String joyInnerKey;      // 中心按下（死区触发）
  /// ★ 中圈映射键：手指超出中圈距离时追加按下（如 shift → 组合成 shift+up）
  ///   为空则不追加任何键。
  final String joyMidKey;

  double get rotationRad => rotation * math.pi / 180;

  KeyWidget copyWith({
    String? key, KShape? shape, double? cx, double? cy,
    double? size, double? sizeW, double? sizeH,
    double? rotation, Color? idleColor, Color? pressedColor,
    bool clearIdle = false, bool clearPressed = false,
    String? imagePath, double? imageOpacity, bool clearImage = false,
    double? imageDx, double? imageDy, double? imageScale,
    double? joyInnerRadius, double? joyMidRadius,
    String? joyUpKey, String? joyDownKey,
    String? joyLeftKey, String? joyRightKey, String? joyInnerKey,
    String? joyMidKey,
    bool? showKeyLabel,
  }) {
    final w = KeyWidget(
      id: id, shape: shape ?? this.shape, key: key ?? this.key,
      cx: cx ?? this.cx, cy: cy ?? this.cy,
      sizeW: sizeW ?? _sizeW,
      sizeH: sizeH ?? _sizeH,
      rotation: rotation ?? this.rotation,
      idleColor: clearIdle ? null : (idleColor ?? this.idleColor),
      pressedColor: clearPressed ? null : (pressedColor ?? this.pressedColor),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
      imageOpacity: imageOpacity ?? this.imageOpacity,
      imageDx: imageDx ?? this.imageDx,
      imageDy: imageDy ?? this.imageDy,
      imageScale: imageScale ?? this.imageScale,
      joyInnerRadius: joyInnerRadius ?? this.joyInnerRadius,
      joyMidRadius: joyMidRadius ?? this.joyMidRadius,
      joyUpKey: joyUpKey ?? this.joyUpKey,
      joyDownKey: joyDownKey ?? this.joyDownKey,
      joyLeftKey: joyLeftKey ?? this.joyLeftKey,
      joyRightKey: joyRightKey ?? this.joyRightKey,
      joyInnerKey: joyInnerKey ?? this.joyInnerKey,
      joyMidKey: joyMidKey ?? this.joyMidKey,
      showKeyLabel: showKeyLabel ?? this.showKeyLabel,
    );
    if (size != null) {
      w._sizeW = size;
      w._sizeH = size;
    }
    return w;
  }

  // ── 几何换算 ──
  Offset centerPx(Size s) => Offset(cx * s.width, cy * s.height);

  /// 半宽（px）
  double halfWPx(Size s) => sizeW * s.width / 2;
  /// 半高（px）
  double halfHPx(Size s) => sizeH * s.height / 2;

  /// 兼容旧代码：取半宽半高平均值
  double halfPx(Size s) => (halfWPx(s) + halfHPx(s)) / 2;

  /// 旋转命中：把全局点逆旋转到组件本地系再判断
  bool hitTest(Offset p, Size s) {
    final c = centerPx(s), hw = halfWPx(s), hh = halfHPx(s);
    if (hw < 1 || hh < 1) return false;
    final d = p - c;
    final lx =  d.dx * math.cos(rotationRad) + d.dy * math.sin(rotationRad);
    final ly = -d.dx * math.sin(rotationRad) + d.dy * math.cos(rotationRad);
    return shape == KShape.circle
        // 椭圆方程：(lx/a)² + (ly/b)² ≤ 1
        ? ((lx * lx) / (hw * hw) + (ly * ly) / (hh * hh) <= 1.0)
        // 矩形：各自比较半轴
        : (lx.abs() <= hw && ly.abs() <= hh);
  }

  /// 旋转后的外接矩形（吸附/对齐用）
  Rect aabbPx(Size s) {
    final c = centerPx(s), hw = halfWPx(s), hh = halfHPx(s);
    final ct = math.cos(rotationRad), st = math.sin(rotationRad);
    var minx = c.dx, maxx = c.dx, miny = c.dy, maxy = c.dy;
    for (final q in [Offset(-hw, -hh), Offset(hw, -hh), Offset(hw, hh), Offset(-hw, hh)]) {
      final x = c.dx + q.dx * ct - q.dy * st;
      final y = c.dy + q.dx * st + q.dy * ct;
      minx = math.min(minx, x); maxx = math.max(maxx, x);
      miny = math.min(miny, y); maxy = math.max(maxy, y);
    }
    return Rect.fromLTRB(minx, miny, maxx, maxy);
  }

  Map<String, dynamic> toMap() => {
    'shape': shape.name, 'key': key,
    'cx': cx, 'cy': cy,
    if (_sizeW == _sizeH)
      'size': sizeW                          // 正方形/正圆 → 兼容旧格式
    else
      ...{'sizeW': sizeW, 'sizeH': sizeH},   // 矩形/椭圆 → 新格式（spread 展开）
    'rot': rotation,
    if (idleColor != null) 'c0': _c2i(idleColor!),
    if (pressedColor != null) 'c1': _c2i(pressedColor!),
    if (imagePath != null && imagePath!.isNotEmpty) 'img': imagePath,
    if (imagePath != null && imagePath!.isNotEmpty) ...{
      'imgOp': imageOpacity,
      'imgDx': imageDx,
      'imgDy': imageDy,
      'imgSc': imageScale,
    },
    if (shape == KShape.joystick) ...{
      'jr': joyInnerRadius,
      'jmr': joyMidRadius,
      'jup': joyUpKey,
      'jdn': joyDownKey,
      'jlt': joyLeftKey,
      'jrt': joyRightKey,
      'jin': joyInnerKey,
      if (joyMidKey.isNotEmpty) 'jmk': joyMidKey,
    },
    if (!showKeyLabel) 'hideKey': true,  // 默认 true → 省略以精简存档
    };

  /// fromMap 同时承担"导入 sanitize"：所有量钳制到安全范围
  factory KeyWidget.fromMap(Map<String, dynamic> m, String id) {
    final s = (m['size'] as num?)?.toDouble();
    final sw = (m['sizeW'] as num?)?.toDouble();
    final sh = (m['sizeH'] as num?)?.toDouble();
    return KeyWidget(
      id: id,
      shape: _shapeFromId(m['shape'] ?? ''),
      key: ((m['key'] ?? 'a').toString()).trim().isEmpty
          ? 'a' : (m['key'] as String).trim(),
      cx: (((m['cx'] as num?)?.toDouble() ?? .5)).clamp(-1.0, 2.0),
      cy: (((m['cy'] as num?)?.toDouble() ?? .5)).clamp(-1.0, 2.0),
      sizeW: (sw ?? s ?? .3).clamp(.02, 4.0),
      sizeH: (sh ?? s ?? .3).clamp(.02, 4.0),
      rotation: ((((m['rot'] as num?)?.toDouble() ?? 0) % 360) + 360) % 360,
      idleColor: m['c0'] == null ? null : Color(m['c0'] as int),
      pressedColor: m['c1'] == null ? null : Color(m['c1'] as int),
      imagePath: m['img'] as String?,
      imageOpacity: (m['imgOp'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 1.0,
      imageDx: _sanitizeImageOffset((m['imgDx'] as num?)?.toDouble() ?? 0),
      imageDy: _sanitizeImageOffset((m['imgDy'] as num?)?.toDouble() ?? 0),
      imageScale: (m['imgSc'] as num?)?.toDouble() ?? 1.0,
      joyInnerRadius:
          (m['jr'] as num?)?.toDouble().clamp(0.1, 0.8) ?? 0.3,
      joyMidRadius:
          (m['jmr'] as num?)?.toDouble().clamp(0.2, 0.95) ?? 0.6,
      joyUpKey: (m['jup'] as String?) ?? 'up',
      joyDownKey: (m['jdn'] as String?) ?? 'down',
      joyLeftKey: (m['jlt'] as String?) ?? 'left',
      joyRightKey: (m['jrt'] as String?) ?? 'right',
      joyInnerKey: (m['jin'] as String?) ?? '',
      joyMidKey: (m['jmk'] as String?) ?? '',
      showKeyLabel: !(m['hideKey'] as bool? ?? false),
    );
  }

  /// 兼容旧存档：旧版 imageDx/imageDy 为绝对像素（典型值 10~200），
  /// 新版为归一化值（相对组件宽/高比例，典型值 -2..2）。
  /// 若检测到超大值（|v| > 5），按旧版预览基准 300px 折算为归一化值。
  static double _sanitizeImageOffset(double v) {
    if (v.abs() > 5.0) return v / 300.0;
    return v;
  }

  static int _n = 0;
  /// 编辑器"+□ / +○"新建
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
