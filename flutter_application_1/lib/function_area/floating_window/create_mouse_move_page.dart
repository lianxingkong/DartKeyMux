import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/all_template/base/basic_move.dart';
import '.././services/connect_grc.dart';
import 'package:flutter_application_1/src/generated/keymux.pbgrpc.dart';



class CreateMouseMovePage extends StatefulWidget {
  const CreateMouseMovePage({super.key});

  @override
  State<CreateMouseMovePage> createState() => _CreateMouseMovePage();
}

class _CreateMouseMovePage extends State<CreateMouseMovePage> {
  /// 画圆点用的「绝对位置」，驱动 CustomPainter 重绘
  final ValueNotifier<Offset?> _fingerPos = ValueNotifier(null);
  final _grpc = GrpcKeyService.instance;

  /// 本地累计位置（显示用），和发给后端的 delta 是两回事
  Offset _curPos = Offset.zero;

  @override
  void dispose() {
    _fingerPos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('页面 build 执行（只应出现一次）');
    return Scaffold(
      body: Stack(
        children: [
          // 绘制层
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: FingerDotPainter(_fingerPos)),
            ),
          ),

          // 手势层
          FullScreenTap(
            // onPointerDown 拿到的还是绝对坐标（局部坐标）
            onPointerDown: (p) {
              _curPos = p;          // 以按下点为基准开始累计
              _fingerPos.value = _curPos;
            },
            // onPointerMove 拿到的是 delta（增量）
            onPointerMove: (delta) {
              // 在此处将 delta 传输
               _grpc.sendPos(type: MouseEvent_EventType.MOVE, dx: delta.dx.round(), dy: delta.dy.round(), scrollDelta: 0);
              _curPos += delta;
              _fingerPos.value = _curPos;
            },
            onPointerUp: (_) {
              // 触控板语义：松手后圆点留在原地
              // 如果想松手消失，改成 _fingerPos.value = null;
            },
          ),
        ],
      ),
    );
  }
}

/// 圆点画笔（不变）
class FingerDotPainter extends CustomPainter {
  FingerDotPainter(this.notifier) : super(repaint: notifier);

  final ValueNotifier<Offset?> notifier;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = notifier.value;
    if (pos == null) return;

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 20, paint);
  }

  @override
  bool shouldRepaint(FingerDotPainter oldDelegate) => false;
}
