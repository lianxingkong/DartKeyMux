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
    final portOk = _validatePort(_portController.text);
    setState(() {});
    if (!portOk) return;

    // 主机地址固定不可改，始终取当前配置值
    final newHost = widget.valueHost.value;
    final newPort = int.parse(_portController.text.trim());

    // 1) 更新全局配置（只更新端口）
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
        // ── 主机行：只读展示（地址固定，不可修改）──
        Row(
          children: [
            const Text('主机地址', style: TextStyle(fontSize: 15)),
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _hostController,
                readOnly: true,          // ★ 不可更改（弹出键盘也不会出现）
                enableInteractiveSelection: true, // 仍可长按复制，方便查看
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.12),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  // 明确的"固定"语义
                  suffixIcon: const Icon(Icons.lock_outline, size: 16),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '主机地址已固定，如需更改请重新编译',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
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
