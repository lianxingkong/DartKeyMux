import 'package:flutter/material.dart';

import 'package:flutter_application_1/function_area/setting/basic_setting_page.dart';


class MainSidebarMenu extends StatefulWidget {
  const MainSidebarMenu({super.key});

  @override
  State<MainSidebarMenu> createState() => _MainSidebarMenuState();
}

class _MainSidebarMenuState extends State<MainSidebarMenu> {
  // 自启动开关状态
  bool _autoStart = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 210, 243, 210),
          child: Column(
            children: [
              DrawerHeader(
                child: Icon(
                  Icons.account_circle_outlined,
                  size:40
                )
              ),
              ListTile(
                leading: Icon(Icons.home),
                title: Text("主 页"),
              ),
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text("自启动指定模板"),
                trailing: Switch(
                  value: _autoStart,
                  onChanged: (value) {
                    setState(() {
                      _autoStart = value;
                    });
                    debugPrint('自启动开关：$_autoStart');
                  },
                ),
              ),
              InkWell(
                onTap: () {
                  // 先关闭抽屉，再跳转，否则返回时抽屉还是打开的
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingPage()),
                  );
                },
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("设置"),
                ),
              ),
            ],
          ),
    );
  }
}