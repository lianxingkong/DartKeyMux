import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_application_1/function_area/floating_window/float_button.dart';
import 'package:flutter_application_1/function_area/sidebar/main_sidebar_menu.dart';
import 'package:flutter_application_1/function_area/home_page_view/choose_template.dart';
import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/services/connect_grc.dart';
import 'package:flutter_application_1/function_area/all_template/player_template/custom_play_page.dart';
import 'package:flutter_application_1/function_area/all_template/player_template/custom_mouse_play_page.dart';
import 'package:flutter_application_1/function_area/sidebar/connect_state.dart';
import './app_config.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );  // 关闭部分手机底部导航栏

  AppConfig.grpcPort.addListener(_reconnectGrpc);

  GrpcKeyService.instance.init(
    host: AppConfig.grpcHost.value,   // ← 改成你后端电脑的局域网 IP
    port: AppConfig.grpcPort.value,
  );

  await TemplateService.instance.loadOnce();          // ★ 启动时先读存档
  runApp(const MainApp());
}

void _reconnectGrpc() {
  GrpcKeyService.instance.init(
    host: AppConfig.grpcHost.value,   // host 虽然不监听，重连时还是要带上当前值
    port: AppConfig.grpcPort.value,
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
    home: _MainInterface(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _MainInterface extends StatefulWidget {
  const _MainInterface();

  @override
  State<_MainInterface> createState() => __MainInterfaceState();
}

class __MainInterfaceState extends State<_MainInterface> {
  bool _autoStartHandled = false;

  @override
  void initState() {
    super.initState();
    // ★ 自启动：首帧完成后立即跳转，跳过主页显示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoStart();
    });
  }

  void _tryAutoStart() {
    if (_autoStartHandled) return;
    final service = TemplateService.instance;
    if (!service.autoStartMasterEnabled) return;          // 总开关未开启
    final idx = service.autoStartIndex;
    if (idx == null) return;                              // 没有指定模板
    if (idx < 0 || idx >= service.templates.length) return; // 下标无效

    _autoStartHandled = true;
    final draft = service.draftAt(idx);
    // ★ 按模板类型路由到正确的播放页
    if (draft.isMouse) {
      openCustomMousePlayPage(context, draft);
    } else {
      openCustomPlayPage(context, draft);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
              title: const Text("主 页"),
              actions: [
                ConnectState(valueListenable:GrpcKeyService.instance.isBackendAlive)  // 连接状态灯
              ],
            ),
        drawer: const MainSidebarMenu(),  // 侧边栏菜单
        body: const ChooseTemplate(),   // 主界面模板展示选择
        floatingActionButton: Padding(    // 悬浮窗控件
          padding: EdgeInsets.only(bottom: 40, left: 14),
          child: const FloatButton()
        )
    );
  }
}
