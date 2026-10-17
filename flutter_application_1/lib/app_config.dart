import 'package:flutter/material.dart';


class AppConfig {
  // 全局可监听的配置
  static final ValueNotifier<String> grpcHost =
      ValueNotifier('127.0.0.1');
  static final ValueNotifier<int> grpcPort =
      ValueNotifier(50051);

  /// 实验性功能总开关（第6条摇杆组件、按键映射表等受此控制）
  static final ValueNotifier<bool> experimentalMode =
      ValueNotifier<bool>(false);
}