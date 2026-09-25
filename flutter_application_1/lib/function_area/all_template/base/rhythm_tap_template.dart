import 'package:flutter/material.dart';
import 'tap_zone.dart';

/// ═══════════ Widget 类（之前缺的）═══════════
abstract class RhythmTapTemplate extends StatefulWidget {
  const RhythmTapTemplate({super.key});
}

/// ═══════════ State 基类 ═══════════
abstract class RhythmTapTemplateState<T extends RhythmTapTemplate>
    extends State<T> {

  double _padX = 50;
  double _padY = 100;
  bool _locked = false;

  static const double _padW = 118;
  static const double _padH = 68;

  // ═══ 可配置项 ═══
  double _splitFraction = 0.5;
  final Map<TapZone, String> _zoneKeys = {
    TapZone.left: 'a',
    TapZone.right: 's',
  };

  void setSplitFraction(double fraction) {
    setState(() => _splitFraction = fraction.clamp(0.05, 0.95));
  }

  void setZoneKey(TapZone zone, String key) {
    setState(() => _zoneKeys[zone] = key);
  }

  // ═══ 子类必须实现的钩子（之前缺声明，现在补上）═══
  void onZoneDown(TapZone zone, String key, Offset globalPos);
  void onZoneUp(TapZone zone, String key, Offset globalPos);

  /// 子类可重写的背景（之前缺定义，现在补上默认实现）
  Widget buildBackground(BuildContext context) {
    return Container(color: const Color.fromARGB(255, 204, 243, 234));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Stack(
            children: [
              buildBackground(context),    
              Positioned.fill(         // 背景
                child: TapZoneLayer(                      // 点击层也放进 body
                  splitFraction: _splitFraction,
                  zoneKeys: _zoneKeys,
                  onZoneDown: onZoneDown,
                  onZoneUp: onZoneUp,
                ),
              )
            ],
          ),
        ),

        if (_locked)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(color: Colors.black.withValues(alpha: 0.1)),
            ),
          ),

        _buildPad(),
      ],
    );
  }

  Widget _buildPad() {
    return Positioned(
      left: _padX,
      top: _padY,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(40),
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
              _circleButton(
                icon: Icons.arrow_back_ios_new,
                color: Colors.white,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              _circleButton(
                icon: _locked ? Icons.lock : Icons.lock_open,
                color: _locked ? Colors.grey : Colors.white,
                onTap: () => setState(() => _locked = !_locked),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _padX += details.delta.dx;
      _padY += details.delta.dy;
      final size = MediaQuery.of(context).size;
      _padX = _padX.clamp(0.0, size.width - _padW);
      _padY = _padY.clamp(0.0, size.height - _padH);
    });
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 24, color: Colors.black87),
      ),
    );
  }
}
