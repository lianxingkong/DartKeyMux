import 'package:flutter/material.dart';


class AppConfig {
  // 全局可监听的配置
  static final ValueNotifier<String> grpcHost =
      ValueNotifier('127.0.0.1');
  static final ValueNotifier<int> grpcPort =
      ValueNotifier(50052);
}