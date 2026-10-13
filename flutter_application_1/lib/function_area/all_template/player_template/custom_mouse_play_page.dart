import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../base/template_document.dart';
import '../base/mouse_touch_core.dart';
import '../../services/connect_grc.dart';


/// 鼠标触控模拟播放页（纯使用模式）
///
/// 从模板列表点击或自启动进入。
/// 全屏触控区 + 左上角返回按钮 + 右侧隐藏式侧边栏（参数调节）。
/// 侧边栏通过屏幕右边缘的微小把手唤出，常态隐藏防误触。
class CustomMousePlayPage extends StatefulWidget {
  const CustomMousePlayPage({super.key, required this.draft});
  final TemplateDraft draft;

  @override
  State<CustomMousePlayPage> createState() => _CustomMousePlayPageState();
}

class _CustomMousePlayPageState extends State<CustomMousePlayPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final MouseTouchEngine _engine;

  @override
  void initState() {
    super.initState();
    // 隐藏状态栏防止误触
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final d = widget.draft;
    _engine = MouseTouchEngine(
      sensitivity: d.sensitivity,
      mouseMode: d.mouseMode,
    );
    // 播放模式自动开启 gRPC 会话
    GrpcKeyService.instance.startSession();
  }

  @override
  void dispose() {
    _engine.dispose();
    GrpcKeyService.instance.endSession();
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFECEFF1),
      // ★ 隐藏式右侧侧边栏（播放时可实时调参）
      endDrawer: _engine.buildSettingsDrawer(
        context,
        () => setState(() {}),
        showSave: false,
      ),
      // ★ 禁止滑动手势打开侧边栏（只能通过把手按钮打开）
      drawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          // ── 全屏触控层（圆点 + Listener）──
          ..._engine.buildTouchLayers(),
          // ── 极简返回按钮 ──
          const Positioned(
            top: 16,
            left: 12,
            child: BackButton(),
          ),
          // ── 右侧把手（打开侧边栏）──
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _engine.buildSidebarHandle(
              () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 模板列表 / 自启动入口调用
void openCustomMousePlayPage(BuildContext context, TemplateDraft draft) =>
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomMousePlayPage(draft: draft)),
    );