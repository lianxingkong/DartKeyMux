// lib/services/grpc_key_service.dart
import 'dart:ffi';

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
  StreamController<MouseEvent>? _mouseController;
  // cancel()，不会在 channel 上留僵尸 call
  ResponseFuture<keyReturn>? _sessionCall;
  ResponseFuture<MouseReturn>? _mouseCall;

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

  /// 当前连接的主机和端口，用于判定是否需要重建通道
  String? _currentHost;
  int? _currentPort;

  void init({required String host, required int port}) {
    // ★ 同一地址 → 无需重建（防止重复调用打断活跃连接）
    if (_currentHost == host && _currentPort == port && _channel != null) {
      return;
    }

    // ── 记下新地址 ──
    _currentHost = host;
    _currentPort = port;

    // ── 清理旧连接 ──
    _healthTimer?.cancel();
    _healthTimer = null;
    _healthClient = null;

    // 关闭活跃的流式会话（旧 client 即将废弃）
    final oldInput = _inputController;
    final oldMouse = _mouseController;
    _inputController = null;
    _mouseController = null;
    _sessionCall = null;
    _mouseCall = null;
    ++_sessionToken;      // 旧会话的收尾回调读到旧 token 会跳过清理
    _closing = false;

    unawaited(oldInput?.close().catchError((_) {}));
    unawaited(oldMouse?.close().catchError((_) {}));

    // 关闭旧 channel（异步，不等待）
    final oldChannel = _channel;
    _channel = null;
    _client = null;
    unawaited(oldChannel?.shutdown().catchError((_) {}));

    // ── 建立新连接 ──
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = rpcKeyServiceClient(_channel!);
    _healthClient = HealthClient(_channel!);
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

    // ── 键盘流 ──
    _inputController = StreamController<keyInput>();
    final keyCall = _client!.keyService(_inputController!.stream);
    _sessionCall = keyCall;

    unawaited(keyCall
        .then((resp) {
          debugPrint('会话完成: isAllDone=${resp.isAllDone}, metaData=${resp.metaData}');
          return resp;
        })
        .catchError((e) {
          debugPrint('gRPC 键盘会话出错: $e');
          throw e;
        })
        .whenComplete(() {
          if (token == _sessionToken) {
            final old = _inputController;
            _inputController = null;
            _sessionCall = null;
            if (old != null && !old.isClosed) unawaited(old.close());
          }
        }));

    // ── 鼠标流 ──
    _mouseController = StreamController<MouseEvent>();
    final mouseCall = _client!.mouseService(_mouseController!.stream);
    _mouseCall = mouseCall;

    unawaited(mouseCall
        .then((resp) {
          debugPrint('鼠标会话完成: isAllDone=${resp.isAllDone}, metaData=${resp.metaData}');
          return resp;
        })
        .catchError((e) {
          debugPrint('gRPC 鼠标会话出错: $e');
          throw e;
        })
        .whenComplete(() {
          if (token == _sessionToken) {
            final old = _mouseController;
            _mouseController = null;
            _mouseCall = null;
            if (old != null && !old.isClosed) unawaited(old.close());
          }
        }));
  }

  // 传输点击事件参数
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

  // 传输鼠标移动参数
  void sendPos({required MouseEvent_EventType type, required int dx, required int dy, required int scrollDelta}){
    final ctrl = _mouseController;
    final call = _mouseCall;
    if (ctrl == null || ctrl.isClosed || call == null || _closing) {
      debugPrint('鼠标会话未开启');
      return;
    }
    try{
      ctrl.add(
        MouseEvent()
          ..type = type
          ..x = dx
          ..y = dy
          ..scrollDelta = scrollDelta
      );
    } catch(e){
      debugPrint('鼠标入流失败（会话已失效）');
    }
  }

  Future<keyReturn?> endSession() async {
    final keyCtrl = _inputController;
    final mouseCtrl = _mouseController;
    if (keyCtrl == null && mouseCtrl == null) return null;

    final token = _sessionToken;
    final keyCall = _sessionCall;
    final mouseCall = _mouseCall;
    _closing = true; // 收流期间不再接受新事件

    // 1) 关闭鼠标流
    if (mouseCtrl != null && !mouseCtrl.isClosed) {
      try {
        await mouseCtrl.close().timeout(const Duration(seconds: 2));
      } catch (_) {
        debugPrint('[grpc] 鼠标关流超时/失败，继续强制清理');
      }
    }

    // 2) 关闭键盘流
    if (keyCtrl != null && !keyCtrl.isClosed) {
      try {
        await keyCtrl.close().timeout(const Duration(seconds: 2));
      } catch (_) {
        debugPrint('[grpc] 键盘关流超时/失败，继续强制清理');
      }
    }

    // 3) 等待 MouseReturn
    if (mouseCall != null) {
      try {
        await mouseCall.timeout(const Duration(seconds: 3));
      } catch (_) {
        debugPrint('[grpc] 等待 MouseReturn 超时/出错，取消该会话');
        unawaited(mouseCall.cancel().catchError((_) {}));
      }
    }

    // 4) 等待 keyReturn 汇总
    keyReturn? result;
    if (keyCall != null) {
      try {
        result = await keyCall.timeout(const Duration(seconds: 3));
      } catch (_) {
        debugPrint('[grpc] 等待 keyReturn 超时/出错，取消该会话');
        unawaited(keyCall.cancel().catchError((_) {}));
      }
    }

    // 5) 仅当仍是当前会话时清理状态（防止把新会话清掉）
    if (token == _sessionToken) {
      _inputController = null;
      _sessionCall = null;
      _mouseController = null;
      _mouseCall = null;
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