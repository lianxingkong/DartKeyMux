import 'package:flutter/material.dart';

/// 区域类型
enum TapZone { left, right }

/// 分区点击层：
/// 1. 按下时根据 [splitFraction] 判断点落在左区还是右区
/// 2. 画出可移动的分界线
/// 3. 每个区域中心显示该区对应的按键字符
class TapZoneLayer extends StatelessWidget {
  const TapZoneLayer({
    super.key,
    required this.splitFraction,   // 0.0~1.0，分界线位置
    required this.zoneKeys,        // 各区显示&传输的字符
    required this.onZoneDown,
    required this.onZoneUp,
  });

  /// 分界线位置（比例）
  final double splitFraction;

  /// 各区字符，如 {TapZone.left: 'a', TapZone.right: 's'}
  final Map<TapZone, String> zoneKeys;

  /// 回调带上了对应字符，按下即“传输”它
  final void Function(TapZone zone, String key, Offset globalPos) onZoneDown;
  final void Function(TapZone zone, String key, Offset globalPos) onZoneUp;

  TapZone _zoneOf(double dx, double width) {
    return dx < width * splitFraction ? TapZone.left : TapZone.right;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final lineWidth = width * splitFraction;

          return Stack(
            children: [
              // ── 1. 全屏命中层（含多点触控）──
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  final zone = _zoneOf(e.position.dx, width);
                  onZoneDown(zone, zoneKeys[zone]!, e.position);
                },
                onPointerUp: (e) {
                  final zone = _zoneOf(e.position.dx, width);
                  onZoneUp(zone, zoneKeys[zone]!, e.position);
                },
                child: const SizedBox.expand(),
              ),

              // ── 2. 分界线（纯装饰，不拦截触摸）──
              IgnorePointer(
                child: Align(
                  alignment: Alignment(-1 + 2 * splitFraction, 0),
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(          // ✅ 阴影属于 BoxDecoration
                        color: Colors.white.withValues(alpha: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── 3. 左区中心字符 ──
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: lineWidth,
                child:IgnorePointer(
                  child: Center(child: _keyLabel(zoneKeys[TapZone.left]!)),
                ),
              ),

              // ── 4. 右区中心字符 ──
              Positioned(
                top: 0,
                bottom: 0,
                left: lineWidth,
                width: width - lineWidth,
                child:IgnorePointer(
                  child: Center(child: _keyLabel(zoneKeys[TapZone.right]!)),
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _keyLabel(String key) {
    return Text(
      key,
      style: TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey.shade800.withValues(alpha: 0.35),
      ),
    );
  }
}
