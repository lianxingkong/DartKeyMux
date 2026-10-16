import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/src/generated/keymux.pbgrpc.dart';

import '../../services/connect_grc.dart';

/// ── 指针追踪状态 ──
class MousePointer {
  final int id;
  Offset downPos;
  final DateTime downTime;
  bool hasMoved = false;       // 是否产生过有效位移
  bool dragActivated = false;  // 是否已进入拖动（发送了 DOWN）
  MousePointer(this.id, this.downPos, this.downTime);
}

/// ── 鼠标触控引擎（纯逻辑，无 UI）──
///
/// 封装两套触控逻辑：
///   • **拖动模式**（mouseMode=0）：单指按下=按住按键，移动=拖动，松手=释放；
///     双指=滚轮，三指=中键拖动。
///   • **触控板**（mouseMode=1）：模拟笔记本电脑触控板 —
///     单指移动=光标、单指轻触=左键、单指按住后移动=拖动；
///     双指移动=滚轮、双指轻触=右键；三指轻触=中键、三指按住后移动=中键拖动。
///
/// 由创建页和播放页共用，避免逻辑重复。
class MouseTouchEngine {
  final _grpc = GrpcKeyService.instance;

  // ── 参数（可通过外部 setState 修改）──
  double sensitivity;
  int mouseMode;       // 0=拖动, 1=触控板
  int dragButton;      // 拖动模式下的按键：0=左, 1=右, 2=中

  // ── 指针追踪（多点触控）──
  final Map<int, MousePointer> ptrs = <int, MousePointer>{};
  int activeFingerCount = 0;

  // ── 画圆点 ──
  final ValueNotifier<Offset?> fingerPos = ValueNotifier(null);
  Offset curPos = Offset.zero;
  int dotFinger = -1; // 用于画点的指针 id

  // ── 阈值常量 ──
  static const double tapMaxDist = 10.0;   // 轻触判定最大位移
  static const int tapMaxMs = 200;          // 轻触判定最长时间
  static const double scrollThreshold = 3.0; // 滚轮灵敏度阈值

  MouseTouchEngine({
    this.sensitivity = 1.0,
    this.mouseMode = 0,
    this.dragButton = 0,
  });

  void dispose() {
    fingerPos.dispose();
  }

  // ════════════════════════════════════════════
  //  按键映射
  // ════════════════════════════════════════════

  MouseEvent_EventType downOf(int btn) => switch (btn) {
    0 => MouseEvent_EventType.LEFT_DOWN,
    1 => MouseEvent_EventType.RIGHT_DOWN,
    2 => MouseEvent_EventType.MIDDLE_DOWN,
    _ => MouseEvent_EventType.LEFT_DOWN,
  };

  MouseEvent_EventType upOf(int btn) => switch (btn) {
    0 => MouseEvent_EventType.LEFT_UP,
    1 => MouseEvent_EventType.RIGHT_UP,
    2 => MouseEvent_EventType.MIDDLE_UP,
    _ => MouseEvent_EventType.LEFT_UP,
  };

  String btnLabel(int btn) => switch (btn) {
    0 => '左键',
    1 => '右键',
    2 => '中键',
    _ => '左键',
  };

  // ════════════════════════════════════════════
  //  gRPC 发送
  // ════════════════════════════════════════════

  void send(MouseEvent_EventType type, int dx, int dy, int scroll) {
    _grpc.sendPos(type: type, dx: dx, dy: dy, scrollDelta: scroll);
  }

  void sendDelta(MouseEvent_EventType type, Offset d) {
    final dd = d * sensitivity;
    send(type, dd.dx.round(), dd.dy.round(), 0);
  }

  void sendScrollDelta(Offset d) {
    final dd = d * sensitivity;
    send(MouseEvent_EventType.SCROLL, 0, 0, dd.dy.round());
  }

  // ════════════════════════════════════════════
  //  触控事件分发
  // ════════════════════════════════════════════

  void onDown(PointerDownEvent e) {
    final ptr = MousePointer(e.pointer, e.position, DateTime.now());
    ptrs[e.pointer] = ptr;
    activeFingerCount = ptrs.length;

    // 画圆点用第一个手指
    if (dotFinger < 0 || !ptrs.containsKey(dotFinger)) {
      dotFinger = e.pointer;
      curPos = e.position;
      fingerPos.value = curPos;
    }

    if (mouseMode == 0) {
      onDownDrag(ptr);
    }
    // 触控板：不立即发送，等判定
  }

  void onMove(PointerMoveEvent e) {
    final ptr = ptrs[e.pointer];
    if (ptr == null) return;

    if (mouseMode == 0) {
      final dist = (e.position - ptr.downPos).distance;
      if (dist > tapMaxDist) ptr.hasMoved = true;
      onMoveDrag(ptr, e);
    } else {
      onMoveTap(ptr, e);
    }

    // 更新圆点
    if (e.pointer == dotFinger) {
      curPos += e.delta;
      fingerPos.value = curPos;
    }
  }

  void onUp(PointerUpEvent e) {
    final ptr = ptrs.remove(e.pointer);
    if (ptr == null) return;
    final wasCount = activeFingerCount;
    activeFingerCount = ptrs.length;

    if (e.pointer == dotFinger) {
      dotFinger = ptrs.keys.firstOrNull ?? -1;
    }

    if (mouseMode == 0) {
      onUpDrag(ptr, wasCount);
    } else {
      onUpTap(ptr, wasCount);
    }
  }

  void onCancel(PointerCancelEvent e) {
    final ptr = ptrs.remove(e.pointer);
    if (ptr == null) return;
    activeFingerCount = ptrs.length;
    if (ptr.dragActivated) {
      // 拖动中的指针被取消 → 释放按键防止按钮卡死
      final btn = mouseMode == 0 ? dragButton : 0; // 拖动模式用自定义键，触控板默认左键
      send(upOf(btn), 0, 0, 0);
    }
    if (e.pointer == dotFinger) {
      dotFinger = ptrs.keys.firstOrNull ?? -1;
    }
  }

  // ───────── 拖动模式 ─────────

  void onDownDrag(MousePointer ptr) {
    final n = activeFingerCount;
    if (n == 1) {
      sendDelta(downOf(dragButton), Offset.zero);
      ptr.dragActivated = true;
    } else if (n == 3 && dragButton != 2) {
      // 三指 → 强制中键拖动
      sendDelta(MouseEvent_EventType.MIDDLE_DOWN, Offset.zero);
      ptr.dragActivated = true;
    }
    // 双指不发送 DOWN（滚轮模式）
  }

  void onMoveDrag(MousePointer ptr, PointerMoveEvent e) {
    final n = activeFingerCount;
    if (n >= 2 && e.delta.dy.abs() > scrollThreshold) {
      sendScrollDelta(e.delta);
    } else if (n == 1 && ptr.dragActivated) {
      sendDelta(MouseEvent_EventType.MOVE, e.delta);
    } else if (n == 3) {
      sendDelta(MouseEvent_EventType.MOVE, e.delta);
    }
  }

  void onUpDrag(MousePointer ptr, int beforeCount) {
    if (ptr.dragActivated) {
      final btn = (beforeCount >= 3 && dragButton != 2)
          ? 2 // 三指强制中键
          : dragButton;
      send(upOf(btn), 0, 0, 0);
    }
  }

  // ───────── 触控板 ─────────

  void onMoveTap(MousePointer ptr, PointerMoveEvent e) {
    final n = activeFingerCount;
    final dur = DateTime.now().difference(ptr.downTime).inMilliseconds;
    final dist = (e.position - ptr.downPos).distance;
    // 捕获"刚好越过移动阈值"的瞬间（用于判断是否在按住足够久后首次移动）
    final justCrossed = dist > tapMaxDist && !ptr.hasMoved;
    if (dist > tapMaxDist) ptr.hasMoved = true;

    // 双指以上 + 垂直移动 → 滚轮（优先，不发送 MOVE）
    if (n >= 2 && e.delta.dy.abs() > scrollThreshold) {
      sendScrollDelta(e.delta);
      return;
    }

    // 单指 / 三指：发送 MOVE
    if (n == 1 || n == 3) {
      // 刚好越过移动阈值 + 按下已超 200ms → 判定为「按住后拖动」
      if (justCrossed && dur > tapMaxMs) {
        final btn = n == 3 ? 2 : 0; // 三指=中键, 单指=左键
        sendDelta(downOf(btn), Offset.zero);
        ptr.dragActivated = true;
      }
      // 发送光标移动（拖动激活后 MOVE 会携带按钮状态，否则是纯光标移动）
      sendDelta(MouseEvent_EventType.MOVE, e.delta);
    }
  }

  void onUpTap(MousePointer ptr, int beforeCount) {
    final dur = DateTime.now().difference(ptr.downTime).inMilliseconds;
    final isTap = !ptr.hasMoved && dur <= tapMaxMs;

    if (ptr.dragActivated) {
      // 拖动结束 → 释放按键
      final btn = beforeCount >= 3 ? 2 : 0; // 三指=中键, 单指=左键
      send(upOf(btn), 0, 0, 0);
    } else if (isTap) {
      // 轻触 → 完整点击（DOWN + UP）
      final btn = btnForTapClick(beforeCount);
      if (btn >= 0) {
        sendDelta(downOf(btn), Offset.zero);
        Future.delayed(const Duration(milliseconds: 30), () {
          send(upOf(btn), 0, 0, 0);
        });
      }
    }
    // 仅移动光标（无拖动、非轻触）→ 无按键需要释放
  }

  /// 触控板：轻触时根据手指数量映射按键
  int btnForTapClick(int fingers) => switch (fingers) {
    1 => 0, // 左键
    2 => 1, // 右键
    3 => 2, // 中键
    _ => -1,
  };

  /// 触控板：按住拖动时根据手指数量映射按键
  int btnForTapDrag(int fingers) => switch (fingers) {
    1 => 0, // 左键拖动
    2 => 1, // 右键拖动（非滚轮时）
    3 => 2, // 中键拖动
    _ => 0,
  };

  // ════════════════════════════════════════════
  //  核心触控层 UI（两个页面共用）
  // ════════════════════════════════════════════

  /// 返回全屏触控层（圆点 + Listener），嵌入各页面的 Stack 中。
  List<Widget> buildTouchLayers() => [
    // ── 层 1：圆点绘制 ──
    Positioned.fill(
      child: RepaintBoundary(
        child: CustomPaint(painter: FingerDotPainter(fingerPos)),
      ),
    ),
    // ── 层 2：全屏多点触控 ──
    Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: onDown,
        onPointerMove: onMove,
        onPointerUp: onUp,
        onPointerCancel: onCancel,
        child: const SizedBox.expand(),
      ),
    ),
  ];

  // ════════════════════════════════════════════
  //  共享侧边栏 UI（创建页 & 播放页共用）
  // ════════════════════════════════════════════

  /// 右侧把手：点击打开 endDrawer
  Widget buildSidebarHandle(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.10),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Center(
            child: Icon(Icons.chevron_left, size: 16, color: Colors.black38),
          ),
        ),
      );

  /// 侧边栏参数面板
  ///
  /// [onChanged] 由调用方传入 setState，引擎值变更后触发页面重绘。
  /// [showSave] 为 true 时显示"保存"按钮（创建页）；false 时隐藏（播放页）。
  Widget buildSettingsDrawer(
    BuildContext context,
    VoidCallback onChanged, {
    bool showSave = false,
    VoidCallback? onSave,
  }) =>
      Drawer(
        width: 260,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child:SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(children: [
                    const Text('触控板设置',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭',
                    ),
                  ]),
                  const Divider(),

                  // ── 功能 1：模式选择 ──
                  const Text('触控模式',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _sharedModeBtn(
                          '拖动', Icons.touch_app, 0, mouseMode == 0, onChanged),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _sharedModeBtn('触板', Icons.tap_and_play, 1,
                          mouseMode == 1, onChanged),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── 功能 2：拖动按键选择（仅拖动模式可见）──
                  if (mouseMode == 0) ...[
                    const Text('拖动按键',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      _sharedBtnChip('左键', 0, dragButton == 0, onChanged),
                      const SizedBox(width: 6),
                      _sharedBtnChip('右键', 1, dragButton == 1, onChanged),
                      const SizedBox(width: 6),
                      _sharedBtnChip('中键', 2, dragButton == 2, onChanged),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // ── 功能 3：灵敏度 ──
                  Row(children: [
                    const Text('灵敏度',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${(sensitivity * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  Slider(
                    value: sensitivity,
                    min: 0.25,
                    max: 3.0,
                    divisions: 11,
                    onChanged: (v) {
                      sensitivity = v;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── 模式说明 ──
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mouseMode == 0
                          ? '拖动模式：单指按拖动按键，双指滚轮，三指中键拖动'
                          : '触控板：模拟笔记本电脑触控板\n'
                            '单指移动=光标 · 单指轻触=左键\n'
                            '按住后移动=拖动 · 双指=滚轮\n'
                            '双指轻触=右键 · 三指轻触=中键',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 功能 4：操作按钮 ──
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('返回'),
                      ),
                    ),
                    if (showSave) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // 先关抽屉
                            onSave?.call();
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('保存'),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ),
        ),
      );

  // ── 侧边栏内部小部件 ──

  Widget _sharedModeBtn(
    String label,
    IconData icon,
    int mode,
    bool active,
    VoidCallback onChanged,
  ) =>
      ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 18,
              color: active ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label),
        ]),
        selected: active,
        onSelected: (_) {
          mouseMode = mode;
          onChanged();
        },
        selectedColor: Colors.blueGrey.shade700,
        labelStyle: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
      );

  Widget _sharedBtnChip(
    String label,
    int btn,
    bool selected,
    VoidCallback onChanged,
  ) =>
      ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: selected,
        onSelected: (_) {
          dragButton = btn;
          onChanged();
        },
        selectedColor: Colors.blue.shade100,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      );
}

/// 圆点画笔
class FingerDotPainter extends CustomPainter {
  FingerDotPainter(this.notifier) : super(repaint: notifier);

  final ValueNotifier<Offset?> notifier;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = notifier.value;
    if (pos == null) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(pos, 16, paint);
  }

  @override
  bool shouldRepaint(FingerDotPainter oldDelegate) => false;
}