import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/floating_window/float_button.dart';
import 'package:flutter_application_1/function_area/sidebar/main_sidebar_menu.dart';
import 'package:flutter_application_1/function_area/home_page_view/choose_template.dart';
import 'package:flutter_application_1/function_area/services/template_service.dart';
import 'package:flutter_application_1/function_area/services/connect_grc.dart';
import 'package:flutter_application_1/function_area/all_template/player_template/custom_play_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GrpcKeyService.instance.init(
    host: '127.0.0.1',   // ← 改成你后端电脑的局域网 IP
    port: 50051,             // ← 改成后端监听的端口，和 Go 里 net.Listen 保持一致
  );

  await TemplateService.instance.loadOnce();          // ★ 启动时先读存档
  runApp(const MainApp());
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomPlayPage(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
              title: const Text("主 页"),
              actions: [
                ValueListenableBuilder<bool>(
                  valueListenable: GrpcKeyService.instance.isBackendAlive,
                  builder: (context, alive, _) {
                    final color = alive ? Colors.green : Colors.red;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 指示灯
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 文字
                            Text(
                              alive ? "已连接" : "未连接",
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
        drawer: const MainSidebarMenu(),  // 侧边栏菜单
        body: const ChooseTemplate(),   // 主界面模板展示选择
        floatingActionButton: const FloatButton(),  // 悬浮控件
    );
  }
}
