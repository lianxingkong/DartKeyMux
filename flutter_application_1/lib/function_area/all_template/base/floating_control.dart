import 'package:flutter/material.dart';

/// ═══════════ 悬浮控件上的单个功能按钮 ═══════════
/// 抽象成数据类：后期要加新功能按键，只需要 new 一个 FloatingAction 塞进列表即可。
class FloatingAction {
  const FloatingAction({
    required this.icon,
    this.tooltip,
    required this.onTap,
    this.activeBuilder,   // 返回 true 时高亮激活态
    this.activeColor,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  /// 可选：返回 true 表示当前处于"激活"状态（如锁屏按钮点亮）
  final bool Function()? activeBuilder;

  /// 激活态颜色（不填默认琥珀色）
  final Color? activeColor;
}

/// ═══════════ 可拖拽悬浮控件（搭载功能按键） ═══════════
///
/// 改造自 rhythm_tap_template.dart 的 _buildPad()，
/// 抽象为独立组件，供 CustomPlayPage 等游玩页直接使用。
///
/// 用法：
/// ```dart
/// FloatingControl(
///   actions: [
///     FloatingAction(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
///     FloatingAction(
///       icon: Icons.lock_open,
///       activeBuilder: () => _locked,
///       onTap: () => setState(() => _locked = !_locked),
///     ),
///   ],
/// )
/// ```
class FloatingControl extends StatefulWidget {
  const FloatingControl({
    super.key,
    required this.actions,
    this.initialX = 50,
    this.initialY = 100,
    this.padColor,
    this.padWidth = 118,
    this.padHeight = 68,
    this.buttonSize = 48,
    this.buttonSpacing = 12,
    this.borderRadius = 40,
  });

  /// 搭载的功能按钮列表（抽象模板）
  final List<FloatingAction> actions;

  /// 初始位置（默认左上角偏右下一点）
  final double initialX;
  final double initialY;

  /// 悬浮控件外观定制
  final Color? padColor;
  final double padWidth;
  final double padHeight;
  final double buttonSize;
  final double buttonSpacing;
  final double borderRadius;

  @override
  State<FloatingControl> createState() => _FloatingControlState();
}

class _FloatingControlState extends State<FloatingControl> {
  late double _padX;
  late double _padY;

  @override
  void initState() {
    super.initState();
    _padX = widget.initialX;
    _padY = widget.initialY;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _padX += details.delta.dx;
      _padY += details.delta.dy;
      final size = MediaQuery.of(context).size;
      _padX = _padX.clamp(0.0, size.width - widget.padWidth);
      _padY = _padY.clamp(0.0, size.height - widget.padHeight);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _padX,
      top: _padY,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.padColor ?? Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < widget.actions.length; i++) ...[
                if (i > 0) SizedBox(width: widget.buttonSpacing),
                _FloatingActionButton(
                  action: widget.actions[i],
                  size: widget.buttonSize,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingActionButton extends StatelessWidget {
  const _FloatingActionButton({
    required this.action,
    required this.size,
  });

  final FloatingAction action;
  final double size;

  @override
  Widget build(BuildContext context) {
    final active = action.activeBuilder?.call() ?? false;
    final color = active
        ? (action.activeColor ?? Colors.amber.shade600)
        : Colors.white;

    return GestureDetector(
      onTap: action.onTap,
      child: Tooltip(
        message: action.tooltip ?? '',
        preferBelow: false,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            action.icon,
            size: size * 0.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}