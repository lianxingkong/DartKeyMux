// lib/services/grpc_key_service.dart
import 'package:flutter/foundation.dart';

import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:flutter_application_1/src/generated/keymux.pbgrpc.dart';  // 先试这个
import 'package:flutter_application_1/src/generated/health.pbgrpc.dart';


class GrpcKeyService {
  GrpcKeyService._internal();
  static final GrpcKeyService instance = GrpcKeyService._internal();

  ClientChannel? _channel;
  rpcKeyServiceClient? _client;

  StreamController<keyInput>? _inputController;
  Future<keyReturn>? _sessionFuture;

  // ═══════════ 健康监测（新增）═══════════
  /// 必须与 Go 端注册的服务名一致
  static const String _healthServiceName = 'GoKeyMux.rpcKeyService';

  /// true = 后端活着且 SERVING；false = 连不上 / 引擎 NOT_SERVING
  final ValueNotifier<bool> isBackendAlive = ValueNotifier<bool>(false);

  HealthClient? _healthClient;
  Timer? _healthTimer;
  int _failCount = 0;
  static const int _failThreshold = 3; // 连续 3 次失败才判 false，防抖

  void _setAlive(bool v) {
    if (isBackendAlive.value != v) {
      isBackendAlive.value = v;
      debugPrint('[_health] backendAlive -> $v');
    }
  }

  void _startHealthCheck() {
    // debugPrint('[_health] 健康检查启动');     
    _healthTimer?.cancel();
    _setAlive(false);
    _failCount = 0;

    _healthTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      // debugPrint('[_health] tick'); 
      try {
        final res = await _healthClient!
            .check(HealthCheckRequest()..service = _healthServiceName)
            .timeout(const Duration(seconds: 2));

        // debugPrint('[_health] 响应 status=${res.status}');

        if (res.status == HealthCheckResponse_ServingStatus.SERVING) {
          _failCount = 0;
          _setAlive(true);
        } else {
          // debugPrint('[_health] 非 SERVING: ${res.status}');
          // 进程在但引擎 NOT_SERVING —— 立刻判 false
          _setAlive(false);
        }
      } catch (_) {
        // 断网 / 超时 / 进程死了 —— 连续失败才判 false
        _failCount++;
        if (_failCount >= _failThreshold) _setAlive(false);
      }
    });
  }

  // ═══════════ 原有逻辑 ═══════════
  void init({required String host, required int port}) {
    // debugPrint('[_health] init 被调用: $host:$port');
    _channel ??= ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client ??= rpcKeyServiceClient(_channel!);
    _healthClient ??= HealthClient(_channel!);
    _startHealthCheck();
  }

  void startSession() {
    if (_inputController != null && !_inputController!.isClosed) return;
    _inputController = StreamController<keyInput>();

    _sessionFuture = _client!.keyService(_inputController!.stream).then(
      (resp) {
        debugPrint('会话完成: isAllDone=${resp.isAllDone}, metaData=${resp.metaData}');
        return resp;
      },
    ).catchError((e) {
      debugPrint('gRPC 会话出错: $e');
      throw e;
    });
  }

  void sendKey({required String key, required bool isRune, required bool isPressed}) {
    if (_inputController == null || _inputController!.isClosed) {
      debugPrint('会话未开启，丢弃按键: $key');
      return;
    }
    _inputController!.add(
      keyInput()
        ..key = key
        ..isRune = isRune
        ..isPressed = isPressed,
    );
    debugPrint('[${DateTime.now()}] ✅ 已入流: key="$key" pressed=$isPressed');
  }

  Future<keyReturn?> endSession() async {
    if (_inputController == null) return null;
    await _inputController!.close();
    _inputController = null;

    try {
      final result = await _sessionFuture;
      _sessionFuture = null;
      return result;
    } catch (_) {
      _sessionFuture = null;
      return null;
    }
  }

  Future<void> shutdown() async {
    _healthTimer?.cancel();
    _healthTimer = null;
    _healthClient = null;
    await endSession();
    await _channel?.shutdown();
    _channel = null;
    _client = null;
    isBackendAlive.dispose();
  }
}
