// lib/services/grpc_key_service.dart
import 'package:flutter/foundation.dart';

import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:grpc/service_api.dart' show ResponseFuture;
import 'package:flutter_application_1/src/generated/keymux.pbgrpc.dart';
import 'package:flutter_application_1/src/generated/health.pbgrpc.dart';


class GrpcKeyService {
  GrpcKeyService._internal();
  static final GrpcKeyService instance = GrpcKeyService._internal();

  ClientChannel? _channel;
  rpcKeyServiceClient? _client;

  StreamController<keyInput>? _inputController;
  // 直接持有 ResponseFuture（而不是 then 出来的 Future）→ 会话挂死时能
  // cancel()，不会在 channel 上留僵尸 call
  ResponseFuture<keyReturn>? _sessionCall;

  // ═══════════ 会话生命周期保护 ═══════════
  /// 会话编号：旧会话的收尾逻辑不得碰新会话的状态（应对快速 退出→再进入）
  int _sessionToken = 0;
  /// endSession 进行中 → sendKey 拒绝入流
  bool _closing = false;

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
    if (_client == null) {
      debugPrint('[grpc] 尚未初始化，忽略 startSession');
      return;
    }

    final token = ++_sessionToken;
    _closing = false;
    _inputController = StreamController<keyInput>();

    final call = _client!.keyService(_inputController!.stream);
    _sessionCall = call;

    // 会话结束（服务端回了 keyReturn，或连接出错）时，若它仍是当前会话
    // 就就地清空状态。否则：死会话会占住上面的门闩（新会话开不起来）、
    // sendKey 还会往已废的流里无限堆事件（缓冲只增不减 = 内存泄漏）。
    unawaited(call
        .then((resp) {
          debugPrint('会话完成: isAllDone=${resp.isAllDone}, metaData=${resp.metaData}');
          return resp;
        })
        .catchError((e) {
          debugPrint('gRPC 会话出错: $e');
          throw e;
        })
        .whenComplete(() {
          if (token == _sessionToken) {
            final old = _inputController;
            _inputController = null;
            _sessionCall = null;
            _closing = false;
            if (old != null && !old.isClosed) unawaited(old.close());
          }
        }));
  }

  void sendKey({required String key, required bool isRune, required bool isPressed}) {
    final ctrl = _inputController;
    final call = _sessionCall;
    if (ctrl == null || ctrl.isClosed || call == null || _closing) {
      debugPrint('会话未开启，丢弃按键: $key');
      return;
    }
    try {
      ctrl.add(
        keyInput()
          ..key = key
          ..isRune = isRune
          ..isPressed = isPressed,
      );
      debugPrint('[${DateTime.now()}] ✅ 已入流: key="$key" pressed=$isPressed');
    } catch (e) {
      debugPrint('入流失败（会话已失效），丢弃按键 $key: $e');
    }
  }

  Future<keyReturn?> endSession() async {
    final ctrl = _inputController;
    if (ctrl == null) return null;

    final token = _sessionToken;
    final call = _sessionCall;
    _closing = true; // 收流期间不再接受新按键

    // 1) 关闭输入流 = 通知服务端“收流”。半死连接下 close 也可能迟迟不回 → 限时兜底
    try {
      await ctrl.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      debugPrint('[grpc] 关流超时/失败，继续强制清理');
    }

    // 2) 等服务端的 keyReturn 汇总。服务端不回（挂死的连接、或协议上死等
    //    一个永远不会来的 keyUp）时，旧实现这里会永久悬挂：反复“进入→
    //    退出”还会在 channel 上积累僵尸 call。现在限时等待，超时即 cancel()。
    keyReturn? result;
    if (call != null) {
      try {
        result = await call.timeout(const Duration(seconds: 3));
      } catch (_) {
        debugPrint('[grpc] 等待 keyReturn 超时/出错，取消该会话');
        unawaited(call.cancel().catchError((_) {}));
      }
    }

    // 3) 仅当仍是当前会话时清理状态（防止把新会话清掉）
    if (token == _sessionToken) {
      _inputController = null;
      _sessionCall = null;
      _closing = false;
    }
    return result;
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
