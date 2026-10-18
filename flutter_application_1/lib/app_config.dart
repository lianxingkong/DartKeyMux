import 'package:flutter/material.dart';


class AppConfig {
  // 全局可监听的配置
  static final ValueNotifier<String> grpcHost =
      ValueNotifier('127.0.0.1');
  static final ValueNotifier<int> grpcPort =
      ValueNotifier(50051);

  /// 实验性功能总开关
  /// 受控项：摇杆组件、按键映射表、按键联立、混合模板（鼠标底层 + 键盘组件）
  static final ValueNotifier<bool> experimentalMode =
      ValueNotifier<bool>(false);
}