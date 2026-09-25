import 'package:flutter/material.dart';
import 'package:flutter_application_1/function_area/all_template/base/tap_zone.dart';
import 'package:flutter_application_1/function_area/all_template/base/rhythm_tap_template.dart';
import 'package:flutter_application_1/function_area/services/connect_grc.dart';

class TwoSideTemplate extends RhythmTapTemplate {
  const TwoSideTemplate({
    super.key,
    this.splitFraction = 0.5,
    this.leftKey = 'a',
    this.rightKey = 's',
  });

  final double splitFraction;
  final String leftKey;
  final String rightKey;

  @override
  State<TwoSideTemplate> createState() => _TwoSideTemplateState();
}

class _TwoSideTemplateState extends RhythmTapTemplateState<TwoSideTemplate> {
  final _grpc = GrpcKeyService.instance;
  /// 当前按下的键（多点触控时可能不止一个），退出时用来补发 keyUp
  final _downKeys = <String>{};

  @override
  void initState() {
    super.initState();
    setSplitFraction(widget.splitFraction);
    setZoneKey(TapZone.left, widget.leftKey);
    setZoneKey(TapZone.right, widget.rightKey);

    _grpc.startSession();   // ✅ 进入页面开流
  }

  @override
  void onZoneDown(TapZone zone, String key, Offset pos) {
    debugPrint(key);
    _downKeys.add(key);
    _grpc.sendKey(key: key, isRune: true, isPressed: true);   // ✅
  }

  @override
  void onZoneUp(TapZone zone, String key, Offset pos) {
    debugPrint(key);
    _downKeys.remove(key);
    _grpc.sendKey(key: key, isRune: true, isPressed: false);  // ✅
  }

  @override
  void dispose() {
    // ★ 点悬浮球退出时可能仍有键处于按下状态（另一根手指压着）：
    //   不补发 keyUp 的话，服务端若按“等所有键抬起才汇总”实现，
    //   keyReturn 永远不回 → 会话悬挂（退出瞬间卡死的根因之一）。
    for (final k in _downKeys) {
      _grpc.sendKey(key: k, isRune: true, isPressed: false);
    }
    _downKeys.clear();
    _grpc.endSession();   // ✅ 离开页面收流，拿 keyReturn 汇总
    super.dispose();
  }
}
