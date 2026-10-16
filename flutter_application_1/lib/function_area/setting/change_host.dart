import 'package:flutter/foundation.dart';  
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_config.dart';
import '../services/connect_grc.dart';


/// 动态修改 gRPC 连接地址（主机 + 端口）。
/// 提交时立即更新全局配置并重建 gRPC 通道，保证动态更改即时生效。
class ChangeHost extends StatefulWidget {
  final ValueListenable<String> valueHost;
  final ValueListenable<int> valuePort;
  final ValueChanged<String> valueUpdateHost;
  final ValueChanged<int> valueUpdatePort;

  const ChangeHost({
    super.key,
    required this.valueHost,
    required this.valuePort,
    required this.valueUpdateHost,
    required this.valueUpdatePort,
  });

  @override
  State<ChangeHost> createState() => _ChangHost();
}

class _ChangHost extends State<ChangeHost> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  String? _hostError;
  String? _portError;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: widget.valueHost.value);
    _portController =
        TextEditingController(text: widget.valuePort.value.toString());
    widget.valuePort.addListener(_syncPortFromNotifier);
  }

  @override
  void dispose() {
    widget.valuePort.removeListener(_syncPortFromNotifier);
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  /// 外部修改端口时同步回输入框
  void _syncPortFromNotifier() {
    final s = widget.valuePort.value.toString();
    if (_portController.text != s) _portController.text = s;
  }

  // ── 输入校验 ──

  bool _validateHost(String v) {
    final t = v.trim();
    if (t.isEmpty) {
      _hostError = '主机地址不能为空';
      return false;
    }
    if (t == 'localhost') { _hostError = null; return true; }

    final ip = t.split('.');
    if (ip.length == 4) {
      for (final p in ip) {
        final n = int.tryParse(p);
        if (n == null || n < 0 || n > 255) { _hostError = 'IP 每段 0-255'; return false; }
      }
      _hostError = null;
      return true;
    }
    if (RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$').hasMatch(t)) {
      _hostError = null;
      return true;
    }
    _hostError = '格式：IP / localhost / 主机名';
    return false;
  }

  bool _validatePort(String v) {
    final n = int.tryParse(v.trim());
    if (n == null || n < 1 || n > 65535) {
      _portError = '端口 1–65535';
      return false;
    }
    _portError = null;
    return true;
  }

  // ── 应用并重连 ──

  void _apply() {
    final hostOk = _validateHost(_hostController.text);
    final portOk = _validatePort(_portController.text);
    setState(() {});
    if (!hostOk || !portOk) return;

    final newHost = _hostController.text.trim();
    final newPort = int.parse(_portController.text.trim());

    // 1) 更新全局配置
    widget.valueUpdateHost(newHost);
    widget.valueUpdatePort(newPort);

    // 2) 立即重建 gRPC 通道（不依赖 listener 延迟，解决 ??= 失效问题）
    GrpcKeyService.instance.init(host: newHost, port: newPort);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 端口行（保留原有 compact 横排风格）──
        Row(
          children: [
            const Text('主机地址', style: TextStyle(fontSize: 15)),
            const Spacer(),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _hostController,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: '例：192.168.1.100',
                  errorText: _hostError,
                ),
                onChanged: (_) {
                  if (_hostError != null) setState(() => _validateHost(_hostController.text));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── 端口行 ──
        Row(
          children: [
            const Text('反代端口', style: TextStyle(fontSize: 15)),
            const Spacer(),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  hintText: '端口',
                  errorText: _portError,
                ),
                onChanged: (_) {
                  if (_portError != null) setState(() => _validatePort(_portController.text));
                },
                onSubmitted: (_) => _apply(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── 连接按钮 ──
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(Icons.cable, size: 18),
            label: const Text('连接'),
          ),
        ),
      ],
    );
  }
}
