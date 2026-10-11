import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/connect_grc.dart';
import 'package:flutter_application_1/src/generated/keymux.pbgrpc.dart';
import '../all_template/base/template_document.dart';


/// ── 指针追踪状态 ──
class _Ptr {
  final int id;
  Offset downPos;
  final DateTime downTime;
  bool hasMoved = false;       // 是否产生过有效位移
  bool dragActivated = false;  // 是否已进入拖动（发送了 DOWN）
  _Ptr(this.id, this.downPos, this.downTime);
}

/// ── 鼠标触控模拟页面 ──
///
/// 两套触控逻辑：
///   • **拖动模式**（mouseMode=0）：单指按下=按住按键，移动=拖动，松手=释放；
///     双指=滚轮，三指=中键拖动。
///   • **点击模式**（mouseMode=1）：快速轻触（<200ms、<10px）= 完整点击；
///     长按移动 = 自动进入拖动；双指轻触=右键，三指=中键。
///
/// 界面：全屏触控区 + 右侧隐藏式侧边栏（参数调节）。无悬浮按钮。
/// 侧边栏通过屏幕右边缘的微小把手唤出，常态隐藏防误触。
class CreateMouseMovePage extends StatefulWidget {
  const CreateMouseMovePage({
    super.key,
    this.initial,         // 编辑已有模板时传入
    this.playMode = false, // true = 纯使用模式（无保存按钮）
  });

  final TemplateDraft? initial;
  final bool playMode;

  @override
  State<CreateMouseMovePage> createState() => _CreateMouseMovePageState();
}

class _CreateMouseMovePageState extends State<CreateMouseMovePage> {
  // ── gRPC ──
  final _grpc = GrpcKeyService.instance;

  // ★ 用 GlobalKey 访问 Scaffold 状态，避免 Scaffold.of() 上下文问题
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── 参数（可通过侧边栏调节）──
  late double _sensitivity;
  late int _mouseMode;       // 0=拖动, 1=点击
  late int _dragButton;      // 拖动模式下的按键：0=左, 1=右, 2=中

  // ── 模板相关 ──
  late String _name;
  late final TextEditingController _nameCtrl;

  // ── 指针追踪（多点触控）──
  final Map<int, _Ptr> _ptrs = <int, _Ptr>{};
  int _activeFingerCount = 0;

  // ── 画圆点 ──
  final ValueNotifier<Offset?> _fingerPos = ValueNotifier(null);
  Offset _curPos = Offset.zero;
  int _dotFinger = -1; // 用于画点的指针 id

  // ── 阈值常量 ──
  static const double _tapMaxDist = 10.0;   // 轻触判定最大位移
  static const int _tapMaxMs = 200;          // 轻触判定最长时间
  static const double _scrollThreshold = 3.0; // 滚轮灵敏度阈值

  // ════════════════════════════════════════════
  //  初始化
  // ════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    _name = ini?.name ?? '';
    _nameCtrl = TextEditingController(text: _name);
    _sensitivity = ini?.sensitivity ?? 1.0;
    _mouseMode = ini?.mouseMode ?? 0;
    _dragButton = 0;

    // 如果是纯使用模式，自动开启 gRPC 会话
    if (widget.playMode) {
      _grpc.startSession();
    }
  }

  @override
  void dispose() {
    _fingerPos.dispose();
    _nameCtrl.dispose();
    if (widget.playMode) {
      _grpc.endSession();
    }
    super.dispose();
  }

  // ════════════════════════════════════════════
  //  按键映射
  // ════════════════════════════════════════════

  MouseEvent_EventType _downOf(int btn) => switch (btn) {
    0 => MouseEvent_EventType.LEFT_DOWN,
    1 => MouseEvent_EventType.RIGHT_DOWN,
    2 => MouseEvent_EventType.MIDDLE_DOWN,
    _ => MouseEvent_EventType.LEFT_DOWN,
  };

  MouseEvent_EventType _upOf(int btn) => switch (btn) {
    0 => MouseEvent_EventType.LEFT_UP,
    1 => MouseEvent_EventType.RIGHT_UP,
    2 => MouseEvent_EventType.MIDDLE_UP,
    _ => MouseEvent_EventType.LEFT_UP,
  };

  String _btnLabel(int btn) => switch (btn) {
    0 => '左键',
    1 => '右键',
    2 => '中键',
    _ => '左键',
  };

  // ════════════════════════════════════════════
  //  gRPC 发送
  // ════════════════════════════════════════════

  void _send(MouseEvent_EventType type, int dx, int dy, int scroll) {
    _grpc.sendPos(type: type, dx: dx, dy: dy, scrollDelta: scroll);
  }

  void _sendDelta(MouseEvent_EventType type, Offset d) {
    final dd = d * _sensitivity;
    _send(type, dd.dx.round(), dd.dy.round(), 0);
  }

  void _sendScrollDelta(Offset d) {
    final dd = d * _sensitivity;
    _send(MouseEvent_EventType.SCROLL, 0, 0, dd.dy.round());
  }

  // ════════════════════════════════════════════
  //  触控事件分发
  // ════════════════════════════════════════════

  void _onDown(PointerDownEvent e) {
    final ptr = _Ptr(e.pointer, e.position, DateTime.now());
    _ptrs[e.pointer] = ptr;
    _activeFingerCount = _ptrs.length;

    // 画圆点用第一个手指
    if (_dotFinger < 0 || !_ptrs.containsKey(_dotFinger)) {
      _dotFinger = e.pointer;
      _curPos = e.position;
      _fingerPos.value = _curPos;
    }

    if (_mouseMode == 0) {
      _onDownDrag(ptr);
    }
    // 点击模式：不立即发送，等判定
  }

  void _onMove(PointerMoveEvent e) {
    final ptr = _ptrs[e.pointer];
    if (ptr == null) return;

    final dist = (e.position - ptr.downPos).distance;
    if (dist > _tapMaxDist) ptr.hasMoved = true;

    if (_mouseMode == 0) {
      _onMoveDrag(ptr, e);
    } else {
      _onMoveTap(ptr, e);
    }

    // 更新圆点
    if (e.pointer == _dotFinger) {
      _curPos += e.delta;
      _fingerPos.value = _curPos;
    }
  }

  void _onUp(PointerUpEvent e) {
    final ptr = _ptrs.remove(e.pointer);
    if (ptr == null) return;
    final wasCount = _activeFingerCount;
    _activeFingerCount = _ptrs.length;

    if (e.pointer == _dotFinger) {
      _dotFinger = _ptrs.keys.firstOrNull ?? -1;
    }

    if (_mouseMode == 0) {
      _onUpDrag(ptr, wasCount);
    } else {
      _onUpTap(ptr, wasCount);
    }
  }

  void _onCancel(PointerCancelEvent e) {
    final ptr = _ptrs.remove(e.pointer);
    if (ptr == null) return;
    _activeFingerCount = _ptrs.length;
    if (ptr.dragActivated && _mouseMode == 0) {
      _send(_upOf(_dragButton), 0, 0, 0);
    }
    if (e.pointer == _dotFinger) {
      _dotFinger = _ptrs.keys.firstOrNull ?? -1;
    }
  }

  // ───────── 拖动模式 ─────────

  void _onDownDrag(_Ptr ptr) {
    final n = _activeFingerCount;
    if (n == 1) {
      _sendDelta(_downOf(_dragButton), Offset.zero);
      ptr.dragActivated = true;
    } else if (n == 3 && _dragButton != 2) {
      // 三指 → 强制中键拖动
      _sendDelta(MouseEvent_EventType.MIDDLE_DOWN, Offset.zero);
      ptr.dragActivated = true;
    }
    // 双指不发送 DOWN（滚轮模式）
  }

  void _onMoveDrag(_Ptr ptr, PointerMoveEvent e) {
    final n = _activeFingerCount;
    if (n >= 2 && e.delta.dy.abs() > _scrollThreshold) {
      _sendScrollDelta(e.delta);
    } else if (n == 1 && ptr.dragActivated) {
      _sendDelta(MouseEvent_EventType.MOVE, e.delta);
    } else if (n == 3) {
      _sendDelta(MouseEvent_EventType.MOVE, e.delta);
    }
  }

  void _onUpDrag(_Ptr ptr, int beforeCount) {
    if (ptr.dragActivated) {
      final btn = (beforeCount >= 3 && _dragButton != 2)
          ? 2 // 三指强制中键
          : _dragButton;
      _send(_upOf(btn), 0, 0, 0);
    }
  }

  // ───────── 点击模式 ─────────

  void _onMoveTap(_Ptr ptr, PointerMoveEvent e) {
    if (ptr.hasMoved && !ptr.dragActivated && _activeFingerCount >= 1) {
      // 进入拖动
      final btn = _btnForTapDrag(_activeFingerCount);
      if (btn >= 0) {
        _sendDelta(_downOf(btn), Offset.zero);
        ptr.dragActivated = true;
      }
    }
    if (ptr.dragActivated) {
      if (_activeFingerCount >= 2 && e.delta.dy.abs() > _scrollThreshold) {
        _sendScrollDelta(e.delta);
      } else {
        _sendDelta(MouseEvent_EventType.MOVE, e.delta);
      }
    }
  }

  void _onUpTap(_Ptr ptr, int beforeCount) {
    final dur = DateTime.now().difference(ptr.downTime).inMilliseconds;
    final isTap = !ptr.hasMoved && dur <= _tapMaxMs;

    if (ptr.dragActivated) {
      // 拖动结束
      final btn = _btnForTapDrag(beforeCount);
      _send(_upOf(btn), 0, 0, 0);
    } else if (isTap) {
      // 轻触 → 完整点击（DOWN + UP）
      final btn = _btnForTapClick(beforeCount);
      if (btn >= 0) {
        _sendDelta(_downOf(btn), Offset.zero);
        Future.delayed(const Duration(milliseconds: 30), () {
          _send(_upOf(btn), 0, 0, 0);
        });
      }
    }
  }

  /// 点击模式：轻触时根据手指数量映射按键
  int _btnForTapClick(int fingers) => switch (fingers) {
    1 => 0, // 左键
    2 => 1, // 右键
    3 => 2, // 中键
    _ => -1,
  };

  /// 点击模式：拖动时根据手指数量映射按键
  int _btnForTapDrag(int fingers) => switch (fingers) {
    1 => 0, // 左键拖动
    2 => 1, // 右键拖动（非滚轮时）
    3 => 2, // 中键拖动
    _ => 0,
  };

  // ════════════════════════════════════════════
  //  保存
  // ════════════════════════════════════════════

  void _save() {
    final name = _name.trim().isEmpty ? '未命名鼠标模板' : _name.trim();
    Navigator.pop(
      context,
      TemplateDraft(
        name: name,
        widgets: [],
        type: 'mouse',
        sensitivity: _sensitivity,
        mouseMode: _mouseMode,
      ),
    );
  }

  // ════════════════════════════════════════════
  //  界面
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFECEFF1),
      // ★ 隐藏式右侧侧边栏
      endDrawer: _settingsDrawer(),
      // ★ 禁止滑动手势打开侧边栏（只能通过把手按钮打开）
      drawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          // ── 层 1：圆点绘制 ──
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: FingerDotPainter(_fingerPos)),
            ),
          ),

          // ── 层 2：全屏多点触控 ──
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onDown,
              onPointerMove: _onMove,
              onPointerUp: _onUp,
              onPointerCancel: _onCancel,
              child: const SizedBox.expand(),
            ),
          ),

          // ── 层 3：顶栏 ──
          // playMode：极简返回按钮，不遮挡触控区
          if (widget.playMode)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 12,
              child: const BackButton(),
            )
          else
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 12,
              right: 44, // 右侧留出把手空间
              child: _topBar(),
            ),

          // ── 层 4：右侧把手（打开侧边栏）──
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _sidebarHandle(),
          ),

          // ── 层 5：模式状态指示（左下角半透明）──
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _modeIndicator(),
          ),
        ],
      ),
    );
  }

  // ──── 顶栏 ────

  /// 编辑模式的顶栏：名称输入 + 返回按钮
  Widget _topBar() => Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.92),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const BackButton(),
            Expanded(
              child: TextField(
                controller: _nameCtrl,
                onChanged: (v) => _name = v,
                decoration: const InputDecoration(
                  hintText: '模板名称',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ]),
        ),
      );

  // ──── 右侧把手 ────

  Widget _sidebarHandle() => GestureDetector(
        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
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

  // ──── 模式指示器 ────

  Widget _modeIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _mouseMode == 0
              ? '拖动模式 · ${_btnLabel(_dragButton)} · ${(_sensitivity * 100).round()}%'
              : '点击模式 · ${(_sensitivity * 100).round()}%',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );

  // ════════════════════════════════════════════
  //  侧边栏（参数面板）
  // ════════════════════════════════════════════

  Widget _settingsDrawer() => Drawer(
        width: 260,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(children: [
                  const Text('触控板设置',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                  ),
                ]),
                const Divider(),

                // ── 功能 1：模式选择 ──
                const Text('触控模式', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _modeBtn('拖动', Icons.touch_app, 0, _mouseMode == 0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeBtn('点击', Icons.tap_and_play, 1, _mouseMode == 1),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── 功能 2：拖动按键选择（仅拖动模式可见）──
                if (_mouseMode == 0) ...[
                  const Text('拖动按键', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _btnChip('左键', 0),
                    const SizedBox(width: 6),
                    _btnChip('右键', 1),
                    const SizedBox(width: 6),
                    _btnChip('中键', 2),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ── 功能 3：灵敏度 ──
                Row(children: [
                  const Text('灵敏度', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${(_sensitivity * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                Slider(
                  value: _sensitivity,
                  min: 0.25,
                  max: 3.0,
                  divisions: 11,
                  onChanged: (v) => setState(() => _sensitivity = v),
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
                    _mouseMode == 0
                        ? '拖动模式：单指按拖动按键，双指滚轮，三指中键拖动'
                        : '点击模式：轻触=完整点击，长按移动=拖动\n'
                          '单指=左键 · 双指=右键 · 三指=中键\n'
                          '双指拖动=滚轮',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                const Spacer(),

                // ── 功能 4：操作按钮 ──
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('返回'),
                    ),
                  ),
                  if (!widget.playMode) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // 先关抽屉
                          _save();
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
      );

  Widget _modeBtn(String label, IconData icon, int mode, bool active) =>
      ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 18,
              color: active ? Colors.white : Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label),
        ]),
        selected: active,
        onSelected: (_) => setState(() => _mouseMode = mode),
        selectedColor: Colors.blueGrey.shade700,
        labelStyle: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _btnChip(String label, int btn) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 13)),
        selected: _dragButton == btn,
        onSelected: (_) => setState(() => _dragButton = btn),
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