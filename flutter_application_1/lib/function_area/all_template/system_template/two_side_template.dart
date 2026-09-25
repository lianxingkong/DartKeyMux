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
    _grpc.sendKey(key: key, isRune: true, isPressed: true);   // ✅
  }

  @override
  void onZoneUp(TapZone zone, String key, Offset pos) {
    debugPrint(key);
    _grpc.sendKey(key: key, isRune: true, isPressed: false);  // ✅
  }

  @override
  void dispose() {
    _grpc.endSession();   // ✅ 离开页面收流，拿 keyReturn 汇总
    super.dispose();
  }
}
