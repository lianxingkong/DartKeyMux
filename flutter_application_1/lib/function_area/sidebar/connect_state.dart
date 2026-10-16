import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';


class ConnectState extends StatefulWidget {
  final ValueListenable<bool> valueListenable;

  const ConnectState({super.key, required this.valueListenable,});

  @override
  State<ConnectState> createState() => _ConnectState();
}

class _ConnectState extends State<ConnectState> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.valueListenable,
      builder: (context, alive, _) {
        final color = alive ? Colors.green : Colors.red;
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 指示灯
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // 文字
              Text(
                alive ? "已连接" : "未连接",
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
