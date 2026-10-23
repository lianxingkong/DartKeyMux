import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../base/key_widget.dart';

/// ── 组件图片裁剪页 ──
///
/// 交互语义（与最终渲染 100% 一致）：
///   - 中央明亮矩形/圆形 = 裁剪框，代表组件本体
///   - 框外区域显示完整图片但被半透明遮罩压暗 → 用户能看清框内外
///   - 双指缩放/拖动图片，框内即最终效果
///
/// ★ 关键修复：
///   1. 遮罩改用 Path.combine(difference) 挖洞，
///      不再用 BlendMode.clear —— 后者会连带擦掉同一图层的图片，导致整屏变黑
///   2. 图片用显式 Positioned 几何绘制（与 KeyWidgetView 同一套算法）
///   3. 偏移归一化存储（相对裁剪框宽/高），乘回实际像素即可跨尺寸复用
class ComponentImageCropPage extends StatefulWidget {
  const ComponentImageCropPage({
    super.key,
    required this.widget,
    this.existingPath,
    this.initialDx = 0,
    this.initialDy = 0,
    this.initialScale = 1.0,
  });

  final KeyWidget widget;
  final String? existingPath;
  final double initialDx;
  final double initialDy;
  final double initialScale;

  @override
  State<ComponentImageCropPage> createState() =>
      _ComponentImageCropPageState();
}

class _ComponentImageCropPageState extends State<ComponentImageCropPage> {
  String? _imagePath;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _offsetRestored = false;

  /// 手势起点的缩放值 + 当前手指数
  ///
  /// ScaleUpdateDetails.scale 是相对手势起点的累计倍率，只能在起点值上乘
  /// 一次；每帧都乘当前值会指数级放大（两指微张就冲到 5×）。
  double _scaleStartValue = 1.0;
  int _scalePointerCount = 0;

  void _onScaleStart(ScaleStartDetails d) {
    _scaleStartValue = _scale;
    _scalePointerCount = d.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    // 手指数变化时以当前比例为基准重新起算，避免 scale 基准跳变
    if (d.pointerCount != _scalePointerCount) {
      _scalePointerCount = d.pointerCount;
      _scaleStartValue = d.scale == 0 ? _scale : _scale / d.scale;
      return;
    }
    setState(() {
      _scale = (_scaleStartValue * d.scale).clamp(0.3, 5.0);
      _offset += d.focalPointDelta;
    });
  }

  // ── 舞台 / 裁剪框尺寸（每次 build 按可用空间重算）──
  double _stageW = 240, _stageH = 240;
  double _cropW = 150, _cropH = 150;
  double get _cropLeft => (_stageW - _cropW) / 2;
  double get _cropTop => (_stageH - _cropH) / 2;
  double get _cropMin => math.min(_cropW, _cropH);

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale <= 0 ? 1.0 : widget.initialScale;
    if (widget.existingPath != null &&
        File(widget.existingPath!).existsSync()) {
      _imagePath = widget.existingPath;
    }
  }

  /// 依据可用空间 + 组件宽高比推算舞台与裁剪框尺寸
  void _calcStage(Size avail) {
    final w = widget.widget;
    final ratio = w.sizeH > 0 ? (w.sizeW / w.sizeH) : 1.0;

    // 舞台尽量大，但留出上下空间给提示与按钮
    final maxW = math.max(120.0, avail.width * 0.94);
    final maxH = math.max(120.0, math.min(avail.height * 0.50, 460.0));

    var sw = maxW;
    var sh = sw / ratio;
    if (sh > maxH) {
      sh = maxH;
      sw = sh * ratio;
    }
    _stageW = sw;
    _stageH = sh;

    // 裁剪框 = 舞台的 62%（居中），四周留白正好用来展示框外内容
    _cropW = sw * 0.62;
    _cropH = sh * 0.62;

    // 还原归一化偏移 → 裁剪框像素偏移（仅首次）
    if (!_offsetRestored &&
        (widget.initialDx != 0 || widget.initialDy != 0)) {
      _offsetRestored = true;
      _offset = Offset(
        widget.initialDx * _cropW,
        widget.initialDy * _cropH,
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  /// 保存：复制到应用目录 → 返回持久路径 + 归一化 crop 参数
  Future<void> _confirm() async {
    if (_imagePath == null) {
      Navigator.pop(context, null);
      return;
    }
    double dx = 0, dy = 0;
    if (_cropW > 0) dx = _offset.dx / _cropW;
    if (_cropH > 0) dy = _offset.dy / _cropH;
    final payload = {
      'dx': dx,
      'dy': dy,
      'scale': _scale,
    };
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dest = File(
          '${appDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(_imagePath!).copy(dest.path);
      Navigator.pop(context, {'path': dest.path, ...payload});
    } catch (_) {
      Navigator.pop(context, {'path': _imagePath!, ...payload});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('裁剪组件图片'),
        actions: [
          if (_imagePath != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '移除图片',
              onPressed: () => setState(() {
                _imagePath = null;
                _scale = 1.0;
                _offset = Offset.zero;
              }),
            ),
          TextButton(onPressed: _confirm, child: const Text('确定')),
        ],
      ),
      body: _imagePath == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('从相册选择'),
              ),
            )
          : SafeArea(
              child: LayoutBuilder(builder: (context, cons) {
                _calcStage(cons.biggest);
                final w = widget.widget;
                final isCircle = w.shape == KShape.circle;
                final radius = isCircle
                    ? _cropMin / 2
                    : (w.shape == KShape.square ? 0.0 : 10.0);

                // 图片显式几何（与 KeyWidgetView._buildImage 同一算法）
                final s = _scale <= 0 ? 1.0 : _scale;
                final iw = _cropW * s;
                final ih = _cropH * s;
                final imgLeft = _cropLeft + (_cropW - iw) / 2 + _offset.dx;
                final imgTop = _cropTop + (_cropH - ih) / 2 + _offset.dy;

                return SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 6),
                    const Text('明亮框内为组件显示区域，框外将被裁掉',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      child: Center(
                        child: SizedBox(
                          width: _stageW,
                          height: _stageH,
                          child: Stack(
                            children: [
                              // ── 舞台底色（暗色，衬托框外图片）──
                              Positioned.fill(
                                child: Container(color: const Color(0xFF2A2A2E)),
                              ),
                              // ── 完整图片（显式定位，可超出裁剪框）──
                              Positioned(
                                left: imgLeft,
                                top: imgTop,
                                width: iw,
                                height: ih,
                                child: Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                  width: iw,
                                  height: ih,
                                ),
                              ),
                              // ── 遮罩：框外压暗（Path 挖洞，安全无副作用）──
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CropOverlayPainter(
                                      cropRect: Rect.fromLTWH(
                                          _cropLeft, _cropTop, _cropW, _cropH),
                                      radius: radius,
                                    ),
                                  ),
                                ),
                              ),
                              // ── 裁剪框描边 ──
                              Positioned(
                                left: _cropLeft,
                                top: _cropTop,
                                width: _cropW,
                                height: _cropH,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(radius)),
                                      border: Border.all(
                                          color: Colors.lightBlueAccent,
                                          width: 2.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: const Text('更换图片'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => setState(() {
                            _scale = 1.0;
                            _offset = Offset.zero;
                          }),
                          icon: const Icon(Icons.center_focus_strong, size: 18),
                          label: const Text('居中复位'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ]),
                );
              }),
            ),
    );
  }
}

/// ── 裁剪遮罩绘制器 ──
///
/// 用 Path.combine(difference) 构造"整块减去裁剪框"的路径再填充，
/// 而不是 BlendMode.clear —— 后者会擦掉同一图层里已绘制的图片。
class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.cropRect, required this.radius});

  final Rect cropRect;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(cropRect, Radius.circular(radius)));
    final mask = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(
      mask,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter old) =>
      old.cropRect != cropRect || old.radius != radius;
}