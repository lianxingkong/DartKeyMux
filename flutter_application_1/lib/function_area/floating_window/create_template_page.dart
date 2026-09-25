import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/function_area/all_template/base/tap_zone.dart';

/// ═══════════ 模板草稿（创建页的产物，也是将来持久化的单位）═══════════
class TemplateDraft {
  const TemplateDraft({
    required this.name,
    required this.splitFraction,
    required this.leftKey,
    required this.rightKey,
  });

  final String name;        // 模板名
  final double splitFraction; // 分界线 0.05~0.95
  final String leftKey;
  final String rightKey;

  /// 存进 SharedPreferences 时转成 JSON 字符串
  Map<String, dynamic> toJson() => {
        'name': name,
        'split': splitFraction,
        'left': leftKey,
        'right': rightKey,
      };

  /// 从存档还原；老数据（纯文本如"预设模板A"）还原失败就给默认值
  factory TemplateDraft.fromJson(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return TemplateDraft(
        name: m['name'] as String? ?? '未命名模板',
        splitFraction: (m['split'] as num?)?.toDouble() ?? 0.5,
        leftKey: m['left'] as String? ?? 'a',
        rightKey: m['right'] as String? ?? 's',
      );
    } catch (_) {
      return TemplateDraft(name: raw, splitFraction: 0.5, leftKey: 'a', rightKey: 's');
    }
  }
}

/// ═══════════ 创建模板页 ═══════════
class CreateTemplatePage extends StatefulWidget {
  const CreateTemplatePage({super.key, this.initial});

  /// 编辑时传入旧草稿；新建时为 null
  final TemplateDraft? initial;

  @override
  State<CreateTemplatePage> createState() => _CreateTemplatePageState();
}

class _CreateTemplatePageState extends State<CreateTemplatePage> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _leftCtrl =
      TextEditingController(text: widget.initial?.leftKey ?? 'a');
  late final TextEditingController _rightCtrl =
      TextEditingController(text: widget.initial?.rightKey ?? 's');
  late double _split = widget.initial?.splitFraction ?? 0.5;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    super.dispose();
  }

  // ── 1. 实时预览：直接复用 TapZoneLayer，回调传空函数 ──
  Widget _buildPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Container(color: const Color.fromARGB(255, 204, 243, 234)),
            Positioned.fill(
              child: TapZoneLayer(
                splitFraction: _split,
                zoneKeys: {
                  TapZone.left: _leftCtrl.text.isEmpty ? 'a' : _leftCtrl.text,
                  TapZone.right: _rightCtrl.text.isEmpty ? 's' : _rightCtrl.text,
                },
                onZoneDown: (_, _, _) {},   // 预览区不做事，可换成提示语
                onZoneUp: (_, _, _) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. 校验 + 保存 ──
  void _save() {
    final name = _nameCtrl.text.trim();
    final left = _leftCtrl.text.trim();
    final right = _rightCtrl.text.trim();

    if (name.isEmpty) {
      _toast('请填写模板名');
      return;
    }
    if (left.isEmpty || right.isEmpty) {
      _toast('左右区域都要设置字符');
      return;
    }
    if (left == right) {
      _toast('两个区域的字符不能相同');
      return;
    }

    Navigator.pop(
      context,
      TemplateDraft(
        name: name,
        splitFraction: _split,
        leftKey: left,
        rightKey: right,
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '创建模板' : '编辑模板'), 
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(color: Color.fromARGB(255, 193, 162, 8))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('实时预览'),
          _buildPreview(),
          const SizedBox(height: 24),

          _section('模板名'),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: '例如：新建模板A',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          _section('分界线位置（${(_split * 100).toStringAsFixed(0)}%）'),
          Slider(
            value: _split,
            min: 0.05,
            max: 0.95,
            divisions: 18,   // 每次 5% 一档
            label: '${(_split * 100).toStringAsFixed(0)}%',
            onChanged: (v) => setState(() => _split = v),
          ),
          const SizedBox(height: 24),

          _section('区域按键'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _leftCtrl,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: '左区',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),   // 让预览跟着变
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _rightCtrl,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: '右区',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // const SizedBox(height: 32),
              // SizedBox(
              //   height: 52,
              //   child: FilledButton(
              //     onPressed: _save,
              //     child: const Text('保存模板', style: TextStyle(fontSize: 18)),
              //   ),
              // ),   // 备选方案，防止appbar右上角的按钮不显示
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}
