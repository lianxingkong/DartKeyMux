import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../base/key_widget.dart';
import '../base/key_widget_view.dart';

/// ── 背景图片裁剪/缩放页 ──
///
/// 从相册选取图片后进入此页：
/// - 图片可双指缩放、拖动
/// - 半透明叠加当前模板组件（所见即所得）
/// - 确定后保存到应用目录并返回路径 + 透明度
class BackgroundCropPage extends StatefulWidget {
  const BackgroundCropPage({
    super.key,
    required this.widgets,
    this.existingPath,
    this.initialOpacity = 1.0,
  });

  final List<KeyWidget> widgets;
  final String? existingPath;
  final double initialOpacity;

  @override
  State<BackgroundCropPage> createState() => _BackgroundCropPageState();
}

class _BackgroundCropPageState extends State<BackgroundCropPage> {
  String? _imagePath;
  double _scale = 1.0;
  double _opacity = 1.0;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _opacity = widget.initialOpacity;
    if (widget.existingPath != null && File(widget.existingPath!).existsSync()) {
      _imagePath = widget.existingPath;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _imagePath = picked.path;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _clearImage() async {
    setState(() {
      _imagePath = null;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _save() async {
    if (_imagePath == null) {
      Navigator.pop(context, null);
      return;
    }

    // 复制到应用目录（防止原始文件被删除）
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final destFile = File(
          '${appDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(_imagePath!).copy(destFile.path);
      Navigator.pop(context, {
        'path': destFile.path,
        'opacity': _opacity,
      });
    } catch (_) {
      // 复制失败则用原路径
      Navigator.pop(context, {
        'path': _imagePath!,
        'opacity': _opacity,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('背景图片'),
        actions: [
          if (_imagePath != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearImage, tooltip: '移除图片'),
          TextButton(onPressed: _save, child: const Text('确定')),
        ],
      ),
      body: _imagePath == null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('尚未选择背景图片', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('从相册选择'),
              ),
            ]))
          : LayoutBuilder(builder: (context, cons) {
              final s = cons.biggest;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // ── 背景图片（可手势缩放/拖动）──
                  GestureDetector(
                    onScaleUpdate: (d) {
                      setState(() {
                        _scale = (_scale * d.scale).clamp(0.3, 5.0);
                        _offset += d.focalPointDelta;
                      });
                    },
                    child: Transform.translate(
                      offset: _offset,
                      child: Transform.scale(
                        scale: _scale,
                        child: Opacity(
                          opacity: _opacity,
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.contain,
                            width: s.width,
                            height: s.height,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── 模板组件半透明叠层 ──
                  ...widget.widgets.map((w) {
                    final c = w.centerPx(s);
                    final wp = w.sizeW * s.width;
                    final hp = w.sizeH * s.height;
                    return Positioned(
                      left: c.dx - wp / 2,
                      top: c.dy - hp / 2,
                      width: wp,
                      height: hp,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.blueAccent.withValues(alpha: 0.6),
                                  width: 2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Transform.rotate(
                              angle: w.rotationRad,
                              child: KeyWidgetView(
                                w: w,
                                pxWidth: wp,
                                pxHeight: hp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // ── 底部控制：透明度滑块 ──
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(children: [
                          const Text('透明度', style: TextStyle(fontSize: 13)),
                          Expanded(
                            child: Slider(
                              value: _opacity,
                              onChanged: (v) =>
                                  setState(() => _opacity = v),
                            ),
                          ),
                          Text('${(_opacity * 100).round()}%',
                              style: const TextStyle(fontSize: 13)),
                        ]),
                      ),
                    ),
                  ),
                  // ── 提示 ──
                  const Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text('双指缩放/拖动图片，组件仅供参考位置',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              backgroundColor: Colors.black26)),
                    ),
                  ),
                ],
              );
            }),
      floatingActionButton:
          _imagePath != null
              ? FloatingActionButton.small(
                  onPressed: _pickImage,
                  child: const Icon(Icons.swap_horiz),
                )
              : null,
    );
  }
}