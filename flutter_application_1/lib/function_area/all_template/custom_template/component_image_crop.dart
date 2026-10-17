import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../base/key_widget.dart';

/// ── 组件图片裁剪页 ──
///
/// 选取图片后在组件形状预览区中双指缩放/拖动定位，
/// 超出预览区部分自动裁剪。确认后复制到应用存储并返回路径与偏移参数。
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

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _offset = Offset(widget.initialDx, widget.initialDy);
    if (widget.existingPath != null &&
        File(widget.existingPath!).existsSync()) {
      _imagePath = widget.existingPath;
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

  /// ★ 保存：复制到应用目录 → 返回持久路径 + crop 参数
  Future<void> _confirm() async {
    if (_imagePath == null) {
      Navigator.pop(context, null);
      return;
    }
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dest = File(
          '${appDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(_imagePath!).copy(dest.path);
      Navigator.pop(context, {
        'path': dest.path,
        'dx': _offset.dx,
        'dy': _offset.dy,
        'scale': _scale,
      });
    } catch (_) {
      Navigator.pop(context, {
        'path': _imagePath!,
        'dx': _offset.dx,
        'dy': _offset.dy,
        'scale': _scale,
      });
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
                final s = cons.biggest;
                final previewSize = (s.width * 0.75).clamp(180.0, 360.0);
                final w = widget.widget;
                final isCircle = w.shape == KShape.circle;
                final borderRadius = isCircle
                    ? previewSize / 2
                    : (w.shape == KShape.square ? 0.0 : 12.0);

                return SingleChildScrollView(
                  child: Column(children: [
                    const SizedBox(height: 8),
                    const Text('双指缩放/拖动，超框自动裁切',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onScaleUpdate: (d) {
                        setState(() {
                          _scale = (_scale * d.scale).clamp(0.3, 5.0);
                          _offset += d.focalPointDelta;
                        });
                      },
                      child: Center(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.all(Radius.circular(borderRadius)),
                          child: Container(
                            width: previewSize,
                            height: previewSize,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              border: Border.all(
                                  color: Colors.blueAccent
                                      .withValues(alpha: 0.7),
                                  width: 2.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(borderRadius)),
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Transform.translate(
                                    offset: _offset,
                                    child: Transform.scale(
                                      scale: _scale,
                                      alignment: Alignment.center,
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                        width: previewSize,
                                        height: previewSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('更换图片'),
                    ),
                    const SizedBox(height: 24),
                  ]),
                );
              }),
            ),
    );
  }
}